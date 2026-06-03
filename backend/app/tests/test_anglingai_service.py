import httpx

from app.core.config import get_settings
from app.schemas.domain import (
    AnglingAIBaitCalculatorRequest,
    AnglingAIByelawCheckRequest,
    AnglingAIRigBuilderRequest,
    AnglingAISolunarRequest,
    AnglingAISpawnAlertRequest,
    AnglingAISwimSelectorRequest,
    AnglingAIVenueResearchRequest,
    AnglingAIWeatherRequest,
)
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


def test_anglingai_pro_context_endpoints_use_documented_payloads(monkeypatch) -> None:
    get_settings.cache_clear()
    monkeypatch.setenv("ANGLINGAI_API_KEY", "test-anglingai-key")
    captured: list[dict[str, object]] = []

    def fake_post(url, json, headers, timeout):  # noqa: ANN001
        captured.append({"url": url, "json": json, "headers": headers, "timeout": timeout})
        return httpx.Response(
            200,
            json={"ok": True},
            headers={"content-type": "application/json"},
            request=httpx.Request("POST", url),
        )

    monkeypatch.setattr(httpx, "post", fake_post)

    service = AnglingAIService()
    service.weather(AnglingAIWeatherRequest(location="Oxford", target_species="Carp"))
    service.solunar(AnglingAISolunarRequest(location="Oxford", days=3))
    service.spawn_alert(AnglingAISpawnAlertRequest(water_temperature=18.5))
    service.byelaw_check(AnglingAIByelawCheckRequest(water_type="river", date="2026-04-01"))
    service.bait_calculator(
        AnglingAIBaitCalculatorRequest(
            duration_hours=5,
            target_species=["Carp", "F1"],
            methods=["method feeder", "pellet waggler"],
            water_type="commercial-stillwater",
            season="summer",
        )
    )
    service.rig_builder(
        AnglingAIRigBuilderRequest(
            target_species="Carp",
            water_type="commercial-stillwater",
            method="method feeder",
            generate_image=False,
        )
    )

    endpoints = [str(request["url"]).rsplit("/", 1)[-1] for request in captured]
    assert endpoints == ["weather", "solunar", "spawn-alert", "byelaw-check", "bait-calculator", "rig-builder"]
    assert captured[0]["json"] == {"location": "Oxford", "targetSpecies": "Carp"}
    assert captured[1]["json"] == {"location": "Oxford", "days": 3}
    assert captured[2]["json"] == {"waterTemperature": 18.5}
    assert captured[3]["json"] == {"waterType": "river", "date": "2026-04-01"}
    assert captured[4]["json"] == {
        "durationHours": 5.0,
        "targetSpecies": ["Carp", "F1"],
        "methods": ["method feeder", "pellet waggler"],
        "waterType": "commercial-stillwater",
        "season": "summer",
    }
    assert captured[5]["json"] == {
        "targetSpecies": "Carp",
        "waterType": "commercial-stillwater",
        "method": "method feeder",
        "generateImage": False,
    }

    get_settings.cache_clear()
