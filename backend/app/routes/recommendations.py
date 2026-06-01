from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.auth import Principal, get_current_principal
from app.core.database import get_db
from app.repositories.factory import build_repository
from app.rules.recommendation_engine import RecommendationEngine
from app.schemas.domain import RecommendationContext, RecommendationOutcome, RecommendationResult, Session as AnglingSession

router = APIRouter(tags=["recommendations"])


@router.post("/generate", response_model=RecommendationResult)
def generate_recommendation(context: RecommendationContext) -> RecommendationResult:
    return RecommendationEngine().generate(context)


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
