from collections.abc import Generator
from contextlib import contextmanager

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import get_db
from app.main import app
from app.models.persistence import Base
from app.services.condition_service import WeatherConditionService
from app.services.venue_intelligence_service import VenueIntelligenceService


@contextmanager
def sqlite_client() -> Generator[TestClient, None, None]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    testing_session = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)

    def override_get_db() -> Generator[Session, None, None]:
        db = testing_session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()
        Base.metadata.drop_all(engine)
        engine.dispose()


def test_capture_assets_are_private_and_user_scoped() -> None:
    with sqlite_client() as client:
        user_a_headers = {"X-CarpCraft-User-Id": "angler-a"}
        user_b_headers = {"X-CarpCraft-User-Id": "angler-b"}

        create_response = client.post(
            "/api/v1/capture-assets",
            headers=user_a_headers,
            json={
                "id": "capture-1",
                "category": "swim",
                "file_uri": "device://photos/swim-1.jpg",
                "caption": "Left margin reedline",
                "annotations": [
                    {
                        "annotation_type": "distance",
                        "label": "Middle rod line",
                        "x1": 0.2,
                        "y1": 0.7,
                        "x2": 0.8,
                        "y2": 0.4,
                        "distance_yards": 88,
                        "distance_wraps": 22,
                    }
                ],
            },
        )

        assert create_response.status_code == 201
        payload = create_response.json()
        assert payload["owner_user_id"] == "angler-a"
        assert payload["privacy_level"] == "private"
        assert payload["sharing_scope"] == "private"

        assert client.get("/api/v1/capture-assets", headers=user_b_headers).json() == []


def test_capture_public_and_precise_location_require_explicit_consent() -> None:
    with sqlite_client() as client:
        public_response = client.post(
            "/api/v1/capture-assets",
            json={
                "id": "public-without-consent",
                "category": "catch",
                "file_uri": "device://photos/catch.jpg",
                "sharing_scope": "public",
            },
        )
        location_response = client.post(
            "/api/v1/capture-assets",
            json={
                "id": "location-without-consent",
                "category": "location",
                "file_uri": "device://photos/location.jpg",
                "latitude": 52.1,
                "longitude": -1.2,
            },
        )
        allowed_public_response = client.post(
            "/api/v1/capture-assets",
            json={
                "id": "public-with-consent",
                "category": "map",
                "file_uri": "device://photos/map.jpg",
                "sharing_scope": "public",
                "public_sharing_consent": True,
            },
        )

        assert public_response.status_code == 422
        assert location_response.status_code == 422
        assert allowed_public_response.status_code == 201
        assert allowed_public_response.json()["sharing_scope"] == "public"


def test_fishery_profile_import_is_private_and_source_bound(monkeypatch) -> None:
    monkeypatch.setattr(VenueIntelligenceService, "_weather_for_venue", lambda self, venue: None)

    with sqlite_client() as client:
        response = client.post(
            "/api/v1/fishery-profiles/from-venue-intelligence?query=Linear%20Fisheries",
            headers={"X-CarpCraft-User-Id": "angler-a"},
        )

        assert response.status_code == 201
        profile = response.json()
        assert profile["owner_user_id"] == "angler-a"
        assert profile["privacy_level"] == "private"
        assert profile["sharing_scope"] == "private"
        assert profile["confidence_score"] >= 80
        assert any("Catch" in option["platform_name"] for option in profile["booking_options"])
        assert any("Swimbooker" in gap or "swimbooker" in gap for gap in profile["data_gaps"])
        assert {section["category"] for section in profile["sections"]} >= {
            "location",
            "access",
            "rules",
            "lakes",
            "booking",
        }
        assert profile["gate_closure_notes"]
        assert profile["facilities"]


def test_fishery_catalogue_seed_and_search_are_private(monkeypatch) -> None:
    monkeypatch.setattr(VenueIntelligenceService, "_weather_for_venue", lambda self, venue: None)

    with sqlite_client() as client:
        seed_response = client.post(
            "/api/v1/fishery-profiles/catalogue/seed",
            headers={"X-CarpCraft-User-Id": "angler-a"},
        )
        search_response = client.get(
            "/api/v1/fishery-profiles/catalogue/search?query=norton",
            headers={"X-CarpCraft-User-Id": "angler-a"},
        )
        other_user_response = client.get(
            "/api/v1/fishery-profiles/catalogue/search",
            headers={"X-CarpCraft-User-Id": "angler-b"},
        )

        assert seed_response.status_code == 201
        assert len(seed_response.json()) >= 2
        assert search_response.status_code == 200
        assert [profile["display_name"] for profile in search_response.json()] == ["Embryo Norton Disney"]
        assert other_user_response.status_code == 200
        assert other_user_response.json() == []


def test_weather_conditions_include_surface_temp_and_data_gaps() -> None:
    condition = WeatherConditionService().enrich_snapshot(
        {
            "source": "multi_provider",
            "requested_location": {"location_label": "Test Lake"},
            "captured_at": "2026-06-02T10:00:00Z",
            "air_temp_c": 18.0,
            "pressure_hpa": 1012.0,
            "wind_speed_mps": 6.0,
            "wind_direction_degrees": 225,
            "rainfall_mm": 0.0,
            "cloud_cover_percent": 20,
            "humidity_percent": 70,
            "providers": [{"source": "open_meteo"}, {"source": "met_office"}],
            "data_gaps": [],
        }
    )

    assert condition.approx_surface_temp_c == 18.2
    assert condition.approx_surface_temp_confidence > 50
    assert condition.wind_direction_label == "SW"
    assert condition.condition == "partly_cloudy"
    assert "not a measured water reading" in condition.approximation_notes[0]


def test_ai_brief_is_grounded_and_never_guarantees() -> None:
    with sqlite_client() as client:
        response = client.post(
            "/api/v1/ai-intelligence/brief",
            json={
                "session_id": "session-1",
                "venue_id": "venue-1",
                "observations": ["Two shows at 80 yards", "One liner on middle rod"],
                "bottom_conditions": ["silt"],
                "weed_conditions": ["silk_weed"],
            },
        )

        assert response.status_code == 200
        brief = response.json()
        assert brief["confidence_score"] > 40
        assert brief["evidence"]
        assert "not a catch prediction or guarantee" in brief["no_guarantee_notice"]
        assert "Never disturb spawning fish." in brief["safety_warnings"]
