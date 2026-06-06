from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.models.persistence import AnglingSessionRecord
from app.repositories.factory import build_repository
from app.rules.recommendation_engine import RecommendationEngine
from app.schemas.domain import (
    Recommendation,
    RecommendationContext,
    RecommendationOutcome,
    RecommendationResult,
    Session as AnglingSession,
)
from app.services.session_plan_service import SessionPlanService

router = APIRouter(tags=["recommendations"])


@router.post("/generate", response_model=RecommendationResult)
def generate_recommendation(context: RecommendationContext) -> RecommendationResult:
    return RecommendationEngine().generate(context)


@router.post("/session/{session_id}/plan", response_model=Recommendation, status_code=status.HTTP_201_CREATED)
def generate_session_plan(
    session_id: str,
    persist: bool = True,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> Recommendation:
    """Build and persist a recommendation from a live session's logged evidence.

    Pulls the latest water readings, weather snapshot, observations, venue
    history and recent catches for the session, runs the deterministic engine,
    and (by default) stores the result so outcomes can be reviewed later.
    """
    session = db.get(AnglingSessionRecord, session_id)
    if session is None or session.user_id != principal.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Session belongs to a different user or does not exist",
        )

    _, recommendation = SessionPlanService(db).generate_plan(session)
    if not persist:
        return recommendation
    return build_repository(db, "recommendations", Recommendation).create(recommendation)


@router.get("/session/{session_id}", response_model=list[Recommendation])
def list_session_recommendations(
    session_id: str,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> list[Recommendation]:
    session = db.get(AnglingSessionRecord, session_id)
    if session is None or session.user_id != principal.user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Session belongs to a different user or does not exist",
        )
    repository = build_repository(db, "recommendations", Recommendation)
    return [item for item in repository.list() if item.session_id == session_id]


@router.post("/{recommendation_id}/outcome", response_model=RecommendationOutcome, status_code=status.HTTP_201_CREATED)
def record_recommendation_outcome(
    recommendation_id: str,
    outcome: RecommendationOutcome,
    db: Session = Depends(get_db),
    principal: Principal = Depends(get_current_principal),
) -> RecommendationOutcome:
    session = build_repository(db, "sessions", AnglingSession).get(outcome.session_id)
    if session is None or session.user_id != principal.user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Session belongs to a different user or does not exist")
    stored = outcome.model_copy(update={"recommendation_id": recommendation_id})
    return build_repository(db, "recommendation-outcomes", RecommendationOutcome).create(stored)
