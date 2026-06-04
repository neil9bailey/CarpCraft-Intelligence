from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import get_db
from app.main import app
from app.models.persistence import Base


@pytest.fixture()
def client_with_sqlite() -> Generator[TestClient, None, None]:
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


def _seed_session(client: TestClient, headers: dict[str, str]) -> None:
    client.post("/api/v1/venues", headers=headers, json={"id": "venue-plan", "name": "Plan Water", "type": "lake"})
    client.post(
        "/api/v1/sessions",
        headers=headers,
        json={"id": "session-plan", "venue_id": "venue-plan", "started_at": "2026-10-15T05:30:00Z"},
    )


def test_session_plan_assembles_context_from_logged_evidence(client_with_sqlite: TestClient) -> None:
    headers = {"X-CarpCraft-User-Id": "angler-plan"}
    _seed_session(client_with_sqlite, headers)

    client_with_sqlite.post(
        "/api/v1/water-readings",
        headers=headers,
        json={"id": "wr-1", "session_id": "session-plan", "read_at": "2026-10-14T06:00:00Z", "water_temp_c": 12.0, "dissolved_oxygen_mg_l": 8.5},
    )
    client_with_sqlite.post(
        "/api/v1/water-readings",
        headers=headers,
        json={"id": "wr-2", "session_id": "session-plan", "read_at": "2026-10-15T06:00:00Z", "water_temp_c": 13.0, "dissolved_oxygen_mg_l": 8.4},
    )
    client_with_sqlite.post(
        "/api/v1/weather-snapshots",
        headers=headers,
        json={
            "id": "ws-1",
            "session_id": "session-plan",
            "captured_at": "2026-10-15T05:45:00Z",
            "air_temp_c": 14.0,
            "pressure_hpa": 1003.0,
            "pressure_trend_hpa_3h": -2.5,
            "wind_speed_mps": 5.0,
            "wind_direction_label": "SW",
        },
    )
    client_with_sqlite.post(
        "/api/v1/observations",
        headers=headers,
        json={"id": "obs-1", "session_id": "session-plan", "observation_type": "show", "observed_at": "2026-10-15T05:50:00Z"},
    )

    response = client_with_sqlite.post("/api/v1/recommendations/session/session-plan/plan", headers=headers)

    assert response.status_code == 201
    body = response.json()
    # Autumn + falling pressure + rising water temp should produce a confident plan with actions.
    assert body["priority_actions"]
    assert body["prime_feeding_windows"]
    assert body["seasonal_context"] is not None
    assert body["barometric_note"] is not None
    assert any("rising" in line.lower() for line in body["evidence_summary"])

    # The plan is persisted and listable per session.
    listed = client_with_sqlite.get("/api/v1/recommendations/session/session-plan", headers=headers)
    assert listed.status_code == 200
    assert any(item["id"] == body["id"] for item in listed.json())


def test_session_plan_is_scoped_to_the_owning_user(client_with_sqlite: TestClient) -> None:
    _seed_session(client_with_sqlite, {"X-CarpCraft-User-Id": "angler-plan"})

    response = client_with_sqlite.post(
        "/api/v1/recommendations/session/session-plan/plan",
        headers={"X-CarpCraft-User-Id": "angler-other"},
    )

    assert response.status_code == 403


def test_session_plan_without_evidence_reports_data_gaps(client_with_sqlite: TestClient) -> None:
    headers = {"X-CarpCraft-User-Id": "angler-plan"}
    _seed_session(client_with_sqlite, headers)

    response = client_with_sqlite.post(
        "/api/v1/recommendations/session/session-plan/plan?persist=false",
        headers=headers,
    )

    assert response.status_code == 201
    body = response.json()
    assert any("Water temperature is missing" in gap for gap in body["data_gaps"])
    # Nothing persisted when persist=false.
    assert client_with_sqlite.get("/api/v1/recommendations/session/session-plan", headers=headers).json() == []
