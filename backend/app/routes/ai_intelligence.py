from fastapi import APIRouter, Depends

from app.core.auth import Principal, get_current_principal
from app.schemas.domain import AIIntelligenceBrief, AIIntelligenceBriefInput
from app.services.ai_intelligence_service import AIIntelligenceService

router = APIRouter(tags=["ai-intelligence"])


@router.post("/brief", response_model=AIIntelligenceBrief)
def create_intelligence_brief(
    context: AIIntelligenceBriefInput,
    principal: Principal = Depends(get_current_principal),
) -> AIIntelligenceBrief:
    return AIIntelligenceService().build_brief(context, principal)


@router.get("/example-live-session", response_model=AIIntelligenceBrief)
def example_live_session_brief(
    principal: Principal = Depends(get_current_principal),
) -> AIIntelligenceBrief:
    return AIIntelligenceService().example_brief(principal)
