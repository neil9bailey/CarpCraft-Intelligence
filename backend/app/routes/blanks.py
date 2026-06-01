from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.schemas.domain import BlankInterval, Session as AnglingSession

router = APIRouter(tags=["blanks"])


def _assert_session_access(session_id: str, db: Session, principal: Principal) -> None:
    session = build_repository(db, "sessions", AnglingSession).get(session_id)
    if session is None or session.user_id != principal.user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Session belongs to a different user or does not exist")


@router.post("", response_model=BlankInterval, status_code=status.HTTP_201_CREATED)
def create_blank_interval(
    blank: BlankInterval,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> BlankInterval:
    _assert_session_access(blank.session_id, db, principal)
    return build_repository(db, "blanks", BlankInterval).create(blank)


@router.get("", response_model=list[BlankInterval])
def list_blank_intervals(
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> list[BlankInterval]:
    blanks = build_repository(db, "blanks", BlankInterval).list()
    return [
        blank
        for blank in blanks
        if (session := build_repository(db, "sessions", AnglingSession).get(blank.session_id)) is not None
        and session.user_id == principal.user_id
    ]
