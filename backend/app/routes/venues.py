from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.routes._crud import build_crud_router
from app.schemas.domain import Venue
from app.services.lake_brain_service import LakeBrainService

router = build_crud_router(Venue, "venues")


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
