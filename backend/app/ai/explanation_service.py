from __future__ import annotations

from dataclasses import dataclass

from app.schemas.domain import RecommendationResult


@dataclass(slots=True)
class ExplanationRequest:
    structured_context: dict[str, object]
    recommendation: RecommendationResult
    retrieved_knowledge: list[str]


class ExplanationService:
    """Future OpenAI-ready explanation interface.

    Phase A deliberately avoids external AI calls. Any future implementation must
    use only structured context and retrieved snippets, return fixed JSON fields,
    include confidence and data gaps, and avoid invented venue facts.
    """

    def explain(self, request: ExplanationRequest) -> dict[str, object]:
        return {
            "summary": request.recommendation.recommendation_summary,
            "confidence_score": request.recommendation.confidence_score,
            "data_gaps": request.recommendation.data_gaps,
            "grounding": {
                "structured_context_used": bool(request.structured_context),
                "knowledge_snippet_count": len(request.retrieved_knowledge),
            },
            "disclaimer": "This is evidence-ranked advice, not a catch guarantee.",
        }


class OpenAIExplanationService(ExplanationService):
    """Named adapter reserved for future OpenAI integration."""

    pass
