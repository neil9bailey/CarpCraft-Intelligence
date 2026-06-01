from __future__ import annotations

from dataclasses import dataclass


RAG_KNOWLEDGE_CATEGORIES = [
    "carp_biology",
    "water_temperature_and_metabolism",
    "dissolved_oxygen_and_weed_dynamics",
    "seasonal_behaviour_and_spawning",
    "weather_wind_pressure_and_light",
    "baiting_strategy",
    "rig_and_presentation_logic",
    "fish_care_and_welfare",
    "venue_specific_private_notes",
    "fishery_rules",
]


@dataclass(slots=True)
class RetrievalRequest:
    query: str
    categories: list[str]
    owner_user_id: str | None = None
    venue_id: str | None = None


class RagRetriever:
    """Future pgvector-backed retriever interface."""

    def retrieve(self, request: RetrievalRequest) -> list[dict[str, object]]:
        # TODO: Implement embeddings and private access controls before use.
        return [
            {
                "category": category,
                "snippet": "Retrieval is not implemented in Phase A.",
                "source": "stub",
                "private": category == "venue_specific_private_notes",
            }
            for category in request.categories
            if category in RAG_KNOWLEDGE_CATEGORIES
        ]
