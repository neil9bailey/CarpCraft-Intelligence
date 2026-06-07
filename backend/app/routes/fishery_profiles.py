from __future__ import annotations

from hashlib import sha256

from fastapi import Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.routes._crud import build_crud_router
from app.schemas.domain import (
    BookingOption,
    FisheryLakeProfile,
    FisheryProfile,
    FisheryProfileSection,
    FisheryProfileSource,
    FisheryProfileStatus,
    SourceAccessMode,
    VenueIntelligenceReport,
)
from app.services.venue_intelligence_service import SOURCE_PACKS, VenueIntelligenceService

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


def _list_metadata(report: VenueIntelligenceReport, key: str) -> list[str]:
    raw = SOURCE_PACKS.get(report.matched_key)
    value = raw.report.get(key) if raw is not None else None
    return [str(item) for item in value] if isinstance(value, list) else []


def _text_metadata(report: VenueIntelligenceReport, key: str, fallback: str | None = None) -> str | None:
    raw = SOURCE_PACKS.get(report.matched_key)
    value = raw.report.get(key) if raw is not None else None
    return str(value) if isinstance(value, str) and value.strip() else fallback


def _source_urls(report: VenueIntelligenceReport, source_type: str | None = None) -> list[str]:
    urls: list[str] = []
    for source in report.source_evidence:
        if source_type is None or source_type in source.source_type:
            urls.append(source.url)
    return list(dict.fromkeys(urls))


def _has_live_anglingai_research(report: VenueIntelligenceReport) -> bool:
    return any(
        status.connector_name == "anglingai_venue_research" and status.status == "active"
        for status in report.connector_statuses
    )


def _section(
    category: str,
    title: str,
    items: list[str],
    source_urls: list[str],
    summary: str | None = None,
    confidence: int = 75,
) -> FisheryProfileSection:
    return FisheryProfileSection(
        category=category,
        title=title,
        summary=summary,
        items=[item for item in items if item],
        source_urls=source_urls,
        confidence=confidence,
    )


def _profile_sections(
    report: VenueIntelligenceReport,
    lakes: list[FisheryLakeProfile],
    access_notes: list[str],
    opening_times_notes: list[str],
    gate_closure_notes: list[str],
    parking_notes: list[str],
    facilities: list[str],
    rules: list[str],
    costs_notes: str | None,
    how_to_book_notes: str | None,
) -> list[FisheryProfileSection]:
    venue = report.suggested_venue
    coordinates = (
        f"Approximate coordinates: {venue.approximate_latitude:.5f}, {venue.approximate_longitude:.5f}"
        if venue.approximate_latitude is not None and venue.approximate_longitude is not None
        else "Coordinates not normalized yet."
    )
    anglingai_items = [
        status.summary
        for status in report.connector_statuses
        if status.connector_name == "anglingai_venue_research"
    ] + [
        source.summary
        for source in report.source_evidence
        if source.source_name == "AnglingAI" and source.source_type.startswith("external_ai")
    ][:6]
    anglingai_urls = [
        source.url
        for source in report.source_evidence
        if source.source_name == "AnglingAI" and source.url
    ]
    return [
        _section(
            "location",
            "Location and navigation",
            [venue.location_label or "Approximate location not set.", coordinates],
            _source_urls(report, "official") + [report.external_place.google_maps_uri]
            if report.external_place and report.external_place.google_maps_uri
            else _source_urls(report, "official"),
            confidence=report.confidence_score,
        ),
        _section(
            "intelligence",
            "AnglingAI Pro research",
            anglingai_items
            or ["AnglingAI venue research has not returned usable advisory evidence for this profile yet."],
            list(dict.fromkeys(anglingai_urls or ["https://anglingai.co.uk/docs"])),
            summary="External AI output is advisory and needs review against source links, fishery rules and private CarpCraft logs.",
            confidence=65 if anglingai_items else 30,
        ),
        _section(
            "access",
            "Access, opening times and gates",
            [*access_notes, *opening_times_notes, *gate_closure_notes],
            _source_urls(report, "official"),
            confidence=85,
        ),
        _section(
            "parking",
            "Parking and arrival",
            parking_notes,
            _source_urls(report, "official"),
            confidence=75,
        ),
        _section(
            "facilities",
            "Facilities",
            facilities,
            _source_urls(report, "official"),
            confidence=75,
        ),
        _section(
            "rules",
            "Rules and fish care",
            rules or [venue.rules_notes or "Rules need manual review from official fishery sources."],
            _source_urls(report, "official"),
            confidence=85,
        ),
        _section(
            "lakes",
            "Lakes, swims and depth maps",
            [
                " | ".join(
                    [
                        lake.name,
                        f"{lake.acreage:g} acres" if lake.acreage is not None else "",
                        f"{lake.swim_count} swims" if lake.swim_count is not None else "",
                        "depth map linked" if lake.depth_map_url else "",
                    ]
                ).strip(" |")
                for lake in lakes
            ],
            [url for lake in lakes for url in (lake.source_url, lake.depth_map_url) if url],
            confidence=report.confidence_score,
        ),
        _section(
            "booking",
            "Costs and booking",
            [costs_notes or "", how_to_book_notes or ""],
            _source_urls(report),
            confidence=75,
        ),
        _section(
            "evidence",
            "Source review and gaps",
            [*report.licensing_notes, *report.data_gaps],
            _source_urls(report),
            confidence=70,
        ),
    ]


def _build_profile_from_report(report: VenueIntelligenceReport, principal: Principal) -> FisheryProfile:
    venue = report.suggested_venue
    fingerprint = sha256(principal.user_id.encode("utf-8")).hexdigest()[:10]
    profile_id = f"fishery-{report.matched_key}-{fingerprint}"[:64]
    access_notes = _list_metadata(report, "access_notes")
    opening_times_notes = _list_metadata(report, "opening_times_notes")
    gate_closure_notes = _list_metadata(report, "gate_closure_notes")
    parking_notes = _list_metadata(report, "parking_notes")
    facilities = _list_metadata(report, "facilities")
    rules = _list_metadata(report, "rules")
    costs_notes = _text_metadata(
        report,
        "costs_notes",
        "Costs are intentionally source-bound. Confirm current pricing through Catch, Swimbooker or the official fishery page before sharing.",
    )
    how_to_book_notes = _text_metadata(
        report,
        "how_to_book_notes",
        "Use approved partner/API access, fishery-approved links, or manual review from your Catch/Swimbooker accounts.",
    )

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
    return FisheryProfile(
        id=profile_id,
        owner_user_id=principal.user_id,
        venue_id=venue.id,
        display_name=venue.name,
        slug=report.matched_key,
        location_label=venue.location_label,
        approximate_latitude=venue.approximate_latitude,
        approximate_longitude=venue.approximate_longitude,
        description=report.summary,
        costs_notes=costs_notes,
        how_to_book_notes=how_to_book_notes,
        access_notes=access_notes,
        opening_times_notes=opening_times_notes,
        gate_closure_notes=gate_closure_notes,
        parking_notes=parking_notes,
        facilities=facilities,
        rules=rules,
        booking_options=booking_options,
        lakes=lakes,
        sections=_profile_sections(
            report,
            lakes,
            access_notes,
            opening_times_notes,
            gate_closure_notes,
            parking_notes,
            facilities,
            rules,
            costs_notes,
            how_to_book_notes,
        ),
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


def _create_profile(
    query: str,
    db: Session,
    principal: Principal,
) -> FisheryProfile:
    try:
        report = VenueIntelligenceService().lookup(query)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    if not _has_live_anglingai_research(report):
        raise HTTPException(
            status_code=status.HTTP_424_FAILED_DEPENDENCY,
            detail=(
                "Live AnglingAI venue research is required before creating a fishery profile. "
                "Check ANGLINGAI_API_KEY, quota and endpoint availability."
            ),
        )
    profile = _build_profile_from_report(report, principal)
    return build_repository(db, "fishery-profiles", FisheryProfile).upsert(profile)


def _build_live_search_preview(query: str, principal: Principal) -> FisheryProfile | None:
    try:
        report = VenueIntelligenceService().lookup(query)
    except ValueError:
        return None
    if not _has_live_anglingai_research(report):
        return None
    return _build_profile_from_report(report, principal)


@router.post("/from-venue-intelligence", response_model=FisheryProfile, status_code=status.HTTP_201_CREATED)
def create_profile_from_venue_intelligence(
    query: str = Query(..., min_length=2),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> FisheryProfile:
    return _create_profile(query, db, principal)


@router.post("/catalogue/seed", response_model=list[FisheryProfile], status_code=status.HTTP_201_CREATED)
def seed_catalogue(
    query: str | None = Query(default=None, min_length=2),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> list[FisheryProfile]:
    if query:
        return [_create_profile(query, db, principal)]
    return []


@router.delete("/catalogue/static-seeds", status_code=status.HTTP_200_OK)
def delete_static_seed_profiles(
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> dict[str, int]:
    repository = build_repository(db, "fishery-profiles", FisheryProfile)
    deleted = 0
    for item in repository.list():
        if item.owner_user_id == principal.user_id and item.slug in SOURCE_PACKS:
            if repository.delete(item.id):
                deleted += 1
    return {"deleted": deleted}


@router.get("/catalogue/search", response_model=list[FisheryProfile])
def search_catalogue(
    query: str = Query(default=""),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> list[FisheryProfile]:
    normalized = query.strip().lower()
    items = build_repository(db, "fishery-profiles", FisheryProfile).list()
    owned = [item for item in items if item.owner_user_id == principal.user_id]
    if not normalized:
        live_owned = [item for item in owned if item.slug not in SOURCE_PACKS]
        return sorted(live_owned, key=lambda item: item.display_name.lower())

    def matches(profile: FisheryProfile) -> bool:
        haystack = " ".join(
            [
                profile.display_name,
                profile.slug,
                profile.location_label or "",
                profile.description or "",
                " ".join(lake.name for lake in profile.lakes),
                " ".join(section.title for section in profile.sections),
                " ".join(item for section in profile.sections for item in section.items),
            ]
        ).lower()
        return normalized in haystack

    matches_owned = sorted([item for item in owned if matches(item)], key=lambda item: item.display_name.lower())
    if matches_owned:
        return matches_owned

    live_preview = _build_live_search_preview(query, principal)
    return [live_preview] if live_preview is not None else []
