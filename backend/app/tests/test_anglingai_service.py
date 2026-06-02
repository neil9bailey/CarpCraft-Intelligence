import httpx

from app.core.config import get_settings
from app.schemas.domain import AnglingAISwimSelectorRequest, AnglingAIVenueResearchRequest
from app.services.anglingai_service import AnglingAIService


def test_anglingai_status_reports_missing_key(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.delenv("ANGLINGAI_API_KEY", raising=False)

    status = AnglingAIService().status()
    response = AnglingAIService().venue_research(
        AnglingAIVenueResearchRequest(venue_name="Linear Fisheries", target_species="Carp")
    )

    assert status.configured is False
    assert response.status == "not_configured"
    assert "ANGLINGAI_API_KEY" in response.data_gaps[0]

    get_settings.cache_clear()


def test_anglingai_status_treats_placeholder_key_as_missing(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.setenv("ANGLINGAI_API_KEY", "replace-in-key-vault")

    status = AnglingAIService().status()

    assert status.configured is False
    assert "No AnglingAI API key is configured." in status.data_gaps

    get_settings.cache_clear()


def test_anglingai_venue_research_uses_bearer_token(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.setenv("ANGLINGAI_API_KEY", "test-anglingai-key")
    captured = {}

    def fake_post(url, json, headers, timeout):  # noqa: ANN001
        captured.update({"url": url, "json": json, "headers": headers, "timeout": timeout})
        return httpx.Response(
            200,
            json={"summary": "venue context"},
            headers={"content-type": "application/json"},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(httpx, "post", fake_post)

    response = AnglingAIService().venue_research(
        AnglingAIVenueResearchRequest(venue_name="Linear Fisheries", location="Oxford")
    )

    assert captured["url"].endswith("/venue-research")
    assert captured["headers"]["Authorization"] == "Bearer test-anglingai-key"
    assert captured["json"]["venueName"] == "Linear Fisheries"
    assert captured["json"]["targetSpecies"] == "Carp"
    assert response.status == "active"
    assert response.result == {"summary": "venue context"}
    assert response.evidence[0].source_type == "external_ai_provider"

    get_settings.cache_clear()


def test_anglingai_swim_selector_uses_documented_camel_case_payload(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.setenv("ANGLINGAI_API_KEY", "test-anglingai-key")
    captured = {}

    def fake_post(url, json, headers, timeout):  # noqa: ANN001
        captured.update({"url": url, "json": json, "headers": headers, "timeout": timeout})
        return httpx.Response(
            200,
            json={"summary": "swim context"},
            headers={"content-type": "application/json"},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(httpx, "post", fake_post)

    response = AnglingAIService().swim_selector(
        AnglingAISwimSelectorRequest(
            water_type="commercial-stillwater",
            wind_direction="SW",
            venue_features=["island", "reed beds"],
        )
    )

    assert captured["url"].endswith("/swim-selector")
    assert captured["json"]["waterType"] == "commercial-stillwater"
    assert captured["json"]["targetSpecies"] == "Carp"
    assert captured["json"]["windDirection"] == "SW"
    assert captured["json"]["venueFeatures"] == ["island", "reed beds"]
    assert response.status == "active"

    get_settings.cache_clear()
