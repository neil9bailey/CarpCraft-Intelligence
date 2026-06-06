from app.ai.knowledge_pack import KnowledgeSnippet
from app.ai.rag_retriever import RagRetriever, RetrievalRequest


def test_retriever_ranks_by_keyword_relevance() -> None:
    results = RagRetriever().retrieve(
        RetrievalRequest(
            query="falling pressure and a warm south-westerly wind at dawn",
            categories=["weather_wind_pressure_and_light", "baiting_strategy"],
            limit=3,
        )
    )

    assert results
    assert results[0].category == "weather_wind_pressure_and_light"
    assert results[0].score > 0


def test_retriever_ignores_unknown_categories() -> None:
    results = RagRetriever().retrieve(
        RetrievalRequest(query="anything", categories=["not_a_real_category"], limit=5)
    )

    assert results == []


def test_category_only_request_returns_pack_snippets() -> None:
    results = RagRetriever().retrieve(
        RetrievalRequest(query="", categories=["fish_care_and_welfare"], limit=5)
    )

    assert any(item.category == "fish_care_and_welfare" for item in results)


def test_private_notes_are_only_returned_for_private_category() -> None:
    private_note = KnowledgeSnippet(
        category="venue_specific_private_notes",
        title="North bank margin",
        snippet="Fish hold tight to the north margin in a warm wind.",
        keywords=("margin", "north", "wind"),
        source="private",
    )

    with_private = RagRetriever().retrieve(
        RetrievalRequest(
            query="warm wind margin",
            categories=["venue_specific_private_notes"],
            private_notes=[private_note],
            limit=5,
        )
    )
    without_category = RagRetriever().retrieve(
        RetrievalRequest(
            query="warm wind margin",
            categories=["baiting_strategy"],
            private_notes=[private_note],
            limit=5,
        )
    )

    assert any(item.private and item.title == "North bank margin" for item in with_private)
    assert all(not item.private for item in without_category)
