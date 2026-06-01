from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import get_db
from app.main import app
from app.models.persistence import Base
from app.routes.venues import get_venue_intelligence_service
from app.services.venue_intelligence_service import VenueIntelligenceService
from app.services.weather_service import WeatherLookupRequest, WeatherProvider, WeatherService


class _StaticWeatherProvider(WeatherProvider):
    name = "static_weather"

    def get_snapshot(self, request: WeatherLookupRequest) -> dict[str, object]:
        return {
            "source": self.name,
            "data": {
                "air_temp_c": 14.5,
                "pressure_hpa": 1009.2,
                "wind_speed_mps": 3.1,
                "wind_direction_degrees": 210,
                "rainfall_mm": 0.0,
                "humidity_percent": 78,
            },
            "data_gaps": [],
        }


def _test_service() -> VenueIntelligenceService:
    return VenueIntelligenceService(weather_service=WeatherService(providers=[_StaticWeatherProvider()]))


@pytest.fixture()
def client_with_venue_intelligence() -> Generator[TestClient, None, None]:
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
    app.dependency_overrides[get_venue_intelligence_service] = _test_service
    try:
        yield TestClient(app)
    finally:
        app.dependency_overrides.clear()
        Base.metadata.drop_all(engine)
        engine.dispose()


def test_venue_intelligence_lookup_returns_grounded_embryo_report() -> None:
    report = _test_service().lookup("Embryo Norton Disney")

    assert report.matched_key == "embryo-norton-disney"
    assert report.suggested_venue.name == "Embryo Norton Disney"
    assert report.suggested_venue.privacy_level == "private"
    assert report.weather is not None
    assert report.weather.air_temp_c == 14.5
    assert any(asset.asset_type == "official_depth_map" for asset in report.map_assets)
    assert any("Pettitt" in swim.name and swim.depth_map_url for swim in report.swims)
    assert any("Facebook" in gap for gap in report.data_gaps)
    assert "Never disturb spawning fish." in report.ethical_warnings


def test_venue_intelligence_rejects_unsupported_query() -> None:
    with pytest.raises(ValueError):
        _test_service().lookup("unknown syndicate water")


def test_venue_intelligence_import_creates_private_venue_and_swims(client_with_venue_intelligence: TestClient) -> None:
    headers = {"X-CarpCraft-User-Id": "angler-a"}

    response = client_with_venue_intelligence.post(
        "/api/v1/venues/intelligence/import",
        params={"query": "Linear Fisheries"},
        headers=headers,
    )

    assert response.status_code == 201
    imported = response.json()["suggested_venue"]
    assert imported["owner_user_id"] == "angler-a"
    assert imported["privacy_level"] == "private"
    assert imported["id"].startswith("linear-fisheries-oxford-")

    venues = client_with_venue_intelligence.get("/api/v1/venues", headers=headers).json()
    swims = client_with_venue_intelligence.get("/api/v1/swims", headers=headers).json()

    assert [venue["id"] for venue in venues] == [imported["id"]]
    assert {swim["name"] for swim in swims} >= {"Brasenose One", "Unity Lake", "Tar Farm Lake No. 5"}
    assert all(swim["venue_id"] == imported["id"] for swim in swims)


def test_venue_intelligence_lookup_route_exposes_source_evidence(client_with_venue_intelligence: TestClient) -> None:
    response = client_with_venue_intelligence.get(
        "/api/v1/venues/intelligence/lookup",
        params={"query": "Norton Disney"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["matched_key"] == "embryo-norton-disney"
    assert any(source["source_name"] == "Embryo Angling" for source in payload["source_evidence"])
