from hashlib import sha256
import re

from fastapi import Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.routes._crud import build_crud_router
from app.schemas.domain import PrivacyLevel, Swim, Venue, VenueIntelligenceReport
from app.services.lake_brain_service import LakeBrainService
from app.services.venue_intelligence_service import VenueIntelligenceService

router = build_crud_router(Venue, "venues")


def get_venue_intelligence_service() -> VenueIntelligenceService:
    return VenueIntelligenceService()


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "item"


def _private_venue_id(canonical_venue_id: str, user_id: str) -> str:
    fingerprint = sha256(user_id.encode("utf-8")).hexdigest()[:10]
    return f"{canonical_venue_id}-{fingerprint}"


@router.get("/intelligence/lookup", response_model=VenueIntelligenceReport)
def lookup_venue_intelligence(
    query: str = Query(..., min_length=2),
    service: VenueIntelligenceService = Depends(get_venue_intelligence_service),
) -> VenueIntelligenceReport:
    try:
        return service.lookup(query)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc


@router.post("/intelligence/import", response_model=VenueIntelligenceReport, status_code=status.HTTP_201_CREATED)
def import_venue_intelligence(
    query: str = Query(..., min_length=2),
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
    service: VenueIntelligenceService = Depends(get_venue_intelligence_service),
) -> VenueIntelligenceReport:
    try:
        report = service.lookup(query)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

    canonical_venue = report.suggested_venue
    private_venue = canonical_venue.model_copy(
        update={
            "id": _private_venue_id(canonical_venue.id, principal.user_id),
            "owner_user_id": principal.user_id,
            "privacy_level": PrivacyLevel.private,
        }
    )
    saved_venue = build_repository(db, "venues", Venue).upsert(private_venue)

    swim_repository = build_repository(db, "swims", Swim)
    for swim_intelligence in report.swims:
        swim_id = f"{saved_venue.id}-swim-{_slugify(swim_intelligence.name)}"[:120]
        swim_repository.upsert(
            Swim(
                id=swim_id,
                venue_id=saved_venue.id,
                name=swim_intelligence.name,
                wind_exposure_notes=swim_intelligence.feature_notes,
                access_notes=(
                    f"Imported from public venue intelligence source: {swim_intelligence.source_url}. "
                    "Validate boundaries, rules and current access before fishing."
                ),
                privacy_level=PrivacyLevel.private,
            )
        )

    return report.model_copy(update={"suggested_venue": saved_venue})


@router.get("/{venue_id}/lake-brain-summary")
def lake_brain_summary(
    venue_id: str,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> dict[str, object]:
    venue = build_repository(db, "venues", Venue).get(venue_id)
    if venue is None or venue.owner_user_id != principal.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="venues item not found")
    return LakeBrainService(db).summarise_venue(venue_id)
