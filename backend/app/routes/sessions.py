from datetime import UTC, datetime

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session as DbSession

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.routes._crud import build_crud_router
from app.schemas.domain import Session as AnglingSession

router = build_crud_router(AnglingSession, "sessions")


def _assert_session_access(session: AnglingSession | None, principal: Principal) -> None:
    if session is not None and session.user_id != principal.user_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="sessions item not found")


@router.post("/{session_id}/start", response_model=AnglingSession)
def start_session(
    session_id: str,
    db: DbSession = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> AnglingSession:
    repository = build_repository(db, "sessions", AnglingSession)
    existing = repository.get(session_id)
    _assert_session_access(existing, principal)
    session = existing or AnglingSession(id=session_id, venue_id="pending", user_id=principal.user_id)
    started = session.model_copy(
        update={
            "status": "active",
            "started_at": session.started_at or datetime.now(UTC),
            "user_id": principal.user_id,
        }
    )
    return repository.upsert(started)


@router.post("/{session_id}/end", response_model=AnglingSession)
def end_session(
    session_id: str,
    db: DbSession = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> AnglingSession:
    if not session_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="session_id is required")
    repository = build_repository(db, "sessions", AnglingSession)
    existing = repository.get(session_id)
    _assert_session_access(existing, principal)
    session = existing or AnglingSession(id=session_id, venue_id="pending", user_id=principal.user_id)
    ended = session.model_copy(update={"status": "ended", "ended_at": datetime.now(UTC), "user_id": principal.user_id})
    return repository.upsert(ended)
