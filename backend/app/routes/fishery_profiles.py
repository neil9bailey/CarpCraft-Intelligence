from __future__ import annotations

from hashlib import sha256

from fastapi import Depends, Query, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.routes._crud import build_crud_router
from app.schemas.domain import (
    BookingOption,
    FisheryLakeProfile,
    FisheryProfile,
    FisheryProfileSource,
    FisheryProfileStatus,
    SourceAccessMode,
)
from app.services.venue_intelligence_service import VenueIntelligenceService

router = build_crud_router(FisheryProfile, "fishery-profiles")


def _access_mode(source_type: str) -> SourceAccessMode:
    if source_type.startswith("official"):
        return SourceAccessMode.public_official_page
    if "partner" in source_type:
        return SourceAccessMode.official_partner_api
    if "directory" in source_type:
        return SourceAccessMode.public_directory
    return SourceAccessMode.manual_review


def _is_booking_source(source_name: str, source_type: str) -> bool:
    haystack = f"{source_name} {source_type}".lower()
    return "catch" in haystack or "gocatch" in haystack or "swimbooker" in haystack or "booking" in haystack


@router.post("/from-venue-intelligence", response_model=FisheryProfile, status_code=status.HTTP_201_CREATED)
def create_profile_from_venue_intelligence(
    query: str = Query(..., min_length=2),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> FisheryProfile:
    report = VenueIntelligenceService().lookup(query)
    venue = report.suggested_venue
    fingerprint = sha256(principal.user_id.encode("utf-8")).hexdigest()[:10]
    profile_id = f"fishery-{report.matched_key}-{fingerprint}"[:64]

    sources = [
        FisheryProfileSource(
            source_name=source.source_name,
            source_kind=source.source_type,
            access_mode=_access_mode(source.source_type),
            url=source.url,
            title=source.title,
            summary=source.summary,
            confidence=source.confidence,
            attribution_required=source.attribution_required,
            cache_allowed=False,
            data_rights_notes=source.usage_notes,
        )
        for source in report.source_evidence
    ]
    booking_options = [
        BookingOption(
            platform_name=source.source_name,
            booking_url=source.url,
            cost_summary="Verify current costs, booking windows and cancellation terms in the source account before publishing.",
            availability_notes="Partner/manual connector ready; live availability is not imported until approved access is configured.",
            source_url=source.url,
            requires_partner_confirmation=True,
        )
        for source in report.source_evidence
        if _is_booking_source(source.source_name, source.source_type)
    ]
    lakes = [
        FisheryLakeProfile(
            name=swim.name,
            acreage=swim.acreage,
            swim_count=swim.swim_count,
            depth_map_url=swim.depth_map_url,
            source_url=swim.source_url,
            feature_notes=swim.feature_notes,
            stock_notes=swim.stock_notes,
        )
        for swim in report.swims
    ]

    profile = FisheryProfile(
        id=profile_id,
        owner_user_id=principal.user_id,
        venue_id=venue.id,
        display_name=venue.name,
        slug=report.matched_key,
        location_label=venue.location_label,
        approximate_latitude=venue.approximate_latitude,
        approximate_longitude=venue.approximate_longitude,
        description=report.summary,
        costs_notes="Costs are intentionally source-bound. Confirm current pricing through Catch, Swimbooker or the official fishery page before sharing.",
        how_to_book_notes="Use approved partner/API access, fishery-approved links, or manual review from your Catch/Swimbooker accounts.",
        booking_options=booking_options,
        lakes=lakes,
        latest_news=report.news_items,
        catch_reports=report.catch_reports,
        map_assets=report.map_assets,
        sources=sources,
        profile_status=FisheryProfileStatus.needs_review,
        confidence_score=report.confidence_score,
        licensing_notes=report.licensing_notes,
        data_gaps=[
            *report.data_gaps,
            "Live Catch and Swimbooker availability/cost import needs partner API access, approved export files or fishery-approved profile links.",
            "Do not cache public swim/depth map images until licensing review marks them cacheable.",
        ],
    )
    return build_repository(db, "fishery-profiles", FisheryProfile).upsert(profile)
