from __future__ import annotations

import re
from dataclasses import dataclass, field

from app.ai.knowledge_pack import KNOWLEDGE_PACK, KnowledgeSnippet

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

_TOKEN_RE = re.compile(r"[a-z0-9]+")


def _tokenise(text: str) -> list[str]:
    return _TOKEN_RE.findall(text.lower())


@dataclass(slots=True)
class RetrievalRequest:
    query: str
    categories: list[str]
    owner_user_id: str | None = None
    venue_id: str | None = None
    limit: int = 5
    # Owner-scoped private notes, supplied by the caller after its own access
    # check. The retriever never loads private notes itself.
    private_notes: list[KnowledgeSnippet] = field(default_factory=list)


@dataclass(slots=True)
class RetrievedSnippet:
    category: str
    title: str
    snippet: str
    source: str
    score: float
    private: bool


class RagRetriever:
    """Deterministic, grounded knowledge retriever.

    This retrieves from a curated carp-watercraft knowledge pack using keyword
    overlap scoring. It is intentionally embedding-free so it works offline and
    cannot invent facts. The interface is shaped so a pgvector-backed semantic
    retriever can replace the scoring without changing callers.
    """

    def __init__(self, corpus: tuple[KnowledgeSnippet, ...] = KNOWLEDGE_PACK) -> None:
        self._corpus = corpus

    def retrieve(self, request: RetrievalRequest) -> list[RetrievedSnippet]:
        valid_categories = {c for c in request.categories if c in RAG_KNOWLEDGE_CATEGORIES}
        if not valid_categories:
            return []

        query_tokens = set(_tokenise(request.query))

        candidates: list[tuple[KnowledgeSnippet, bool]] = [
            (snippet, False) for snippet in self._corpus if snippet.category in valid_categories
        ]
        if "venue_specific_private_notes" in valid_categories:
            candidates.extend((note, True) for note in request.private_notes)

        scored: list[RetrievedSnippet] = []
        for snippet, is_private in candidates:
            score = self._score(query_tokens, snippet)
            if score <= 0 and query_tokens:
                continue
            scored.append(
                RetrievedSnippet(
                    category=snippet.category,
                    title=snippet.title,
                    snippet=snippet.snippet,
                    source=snippet.source,
                    score=round(score, 3),
                    private=is_private,
                )
            )

        scored.sort(key=lambda item: (item.score, item.title), reverse=True)
        return scored[: max(request.limit, 0)]

    @staticmethod
    def _score(query_tokens: set[str], snippet: KnowledgeSnippet) -> float:
        if not query_tokens:
            # No query terms: surface notes by a small uniform relevance so a
            # category-only request still returns its knowledge.
            return 0.1
        keyword_set = set(snippet.keywords)
        body_tokens = set(_tokenise(f"{snippet.title} {snippet.snippet}"))
        keyword_hits = len(query_tokens & keyword_set)
        body_hits = len(query_tokens & body_tokens)
        # Curated keywords are weighted higher than incidental body matches.
        return keyword_hits * 1.0 + body_hits * 0.25
