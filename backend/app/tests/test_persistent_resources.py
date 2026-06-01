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


def test_venue_crud_persists_to_database(client_with_sqlite: TestClient) -> None:
    create_response = client_with_sqlite.post(
        "/api/v1/venues",
        json={
            "id": "venue-test-pit",
            "name": "Test Pit",
            "type": "pit",
            "privacy_level": "private",
        },
    )

    assert create_response.status_code == 201

    get_response = client_with_sqlite.get("/api/v1/venues/venue-test-pit")
    assert get_response.status_code == 200
    assert get_response.json()["name"] == "Test Pit"

    list_response = client_with_sqlite.get("/api/v1/venues")
    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()] == ["venue-test-pit"]


def test_venue_crud_is_scoped_to_current_local_user(client_with_sqlite: TestClient) -> None:
    user_a_headers = {"X-CarpCraft-User-Id": "angler-a"}
    user_b_headers = {"X-CarpCraft-User-Id": "angler-b"}

    user_a_response = client_with_sqlite.post(
        "/api/v1/venues",
        headers=user_a_headers,
        json={
            "id": "venue-user-a",
            "name": "User A Mere",
            "type": "lake",
        },
    )
    user_b_response = client_with_sqlite.post(
        "/api/v1/venues",
        headers=user_b_headers,
        json={
            "id": "venue-user-b",
            "name": "User B Pit",
            "type": "pit",
        },
    )

    assert user_a_response.status_code == 201
    assert user_a_response.json()["owner_user_id"] == "angler-a"
    assert user_b_response.status_code == 201
    assert user_b_response.json()["owner_user_id"] == "angler-b"

    user_a_list = client_with_sqlite.get("/api/v1/venues", headers=user_a_headers)
    user_b_list = client_with_sqlite.get("/api/v1/venues", headers=user_b_headers)
    cross_user_get = client_with_sqlite.get("/api/v1/venues/venue-user-a", headers=user_b_headers)

    assert [item["id"] for item in user_a_list.json()] == ["venue-user-a"]
    assert [item["id"] for item in user_b_list.json()] == ["venue-user-b"]
    assert cross_user_get.status_code == 404


def test_venue_create_rejects_different_explicit_owner(client_with_sqlite: TestClient) -> None:
    response = client_with_sqlite.post(
        "/api/v1/venues",
        headers={"X-CarpCraft-User-Id": "angler-a"},
        json={
            "id": "venue-wrong-owner",
            "owner_user_id": "angler-b",
            "name": "Wrong Owner Water",
        },
    )

    assert response.status_code == 403


def test_session_start_and_end_are_persisted(client_with_sqlite: TestClient) -> None:
    start_response = client_with_sqlite.post("/api/v1/sessions/session-night-1/start")

    assert start_response.status_code == 200
    assert start_response.json()["status"] == "active"

    end_response = client_with_sqlite.post("/api/v1/sessions/session-night-1/end")
    assert end_response.status_code == 200
    assert end_response.json()["status"] == "ended"

    get_response = client_with_sqlite.get("/api/v1/sessions/session-night-1")
    assert get_response.status_code == 200
    assert get_response.json()["status"] == "ended"


def test_session_start_is_scoped_to_current_local_user(client_with_sqlite: TestClient) -> None:
    user_a_headers = {"X-CarpCraft-User-Id": "angler-a"}
    user_b_headers = {"X-CarpCraft-User-Id": "angler-b"}

    start_response = client_with_sqlite.post("/api/v1/sessions/private-session/start", headers=user_a_headers)
    cross_user_end = client_with_sqlite.post("/api/v1/sessions/private-session/end", headers=user_b_headers)
    user_a_get = client_with_sqlite.get("/api/v1/sessions/private-session", headers=user_a_headers)
    user_b_get = client_with_sqlite.get("/api/v1/sessions/private-session", headers=user_b_headers)

    assert start_response.status_code == 200
    assert start_response.json()["user_id"] == "angler-a"
    assert cross_user_end.status_code == 404
    assert user_a_get.status_code == 200
    assert user_b_get.status_code == 404


def test_swims_and_spots_are_scoped_through_their_venue(client_with_sqlite: TestClient) -> None:
    user_a_headers = {"X-CarpCraft-User-Id": "angler-a"}
    user_b_headers = {"X-CarpCraft-User-Id": "angler-b"}
    client_with_sqlite.post(
        "/api/v1/venues",
        headers=user_a_headers,
        json={"id": "venue-a", "name": "Venue A", "type": "lake"},
    )
    client_with_sqlite.post(
        "/api/v1/venues",
        headers=user_b_headers,
        json={"id": "venue-b", "name": "Venue B", "type": "pit"},
    )

    swim_a = client_with_sqlite.post(
        "/api/v1/swims",
        headers=user_a_headers,
        json={"id": "swim-a", "venue_id": "venue-a", "name": "Reed Corner"},
    )
    cross_user_swim = client_with_sqlite.post(
        "/api/v1/swims",
        headers=user_b_headers,
        json={"id": "swim-cross", "venue_id": "venue-a", "name": "Sneaky Swim"},
    )
    spot_a = client_with_sqlite.post(
        "/api/v1/spots",
        headers=user_a_headers,
        json={"id": "spot-a", "venue_id": "venue-a", "name": "Gravel Bar"},
    )
    user_b_spots = client_with_sqlite.get("/api/v1/spots", headers=user_b_headers)

    assert swim_a.status_code == 201
    assert cross_user_swim.status_code == 403
    assert spot_a.status_code == 201
    assert user_b_spots.json() == []


def test_evidence_resources_are_persisted_and_session_scoped(client_with_sqlite: TestClient) -> None:
    user_a_headers = {"X-CarpCraft-User-Id": "angler-a"}
    user_b_headers = {"X-CarpCraft-User-Id": "angler-b"}
    client_with_sqlite.post(
        "/api/v1/venues",
        headers=user_a_headers,
        json={"id": "venue-evidence", "name": "Evidence Water", "type": "lake"},
    )
    client_with_sqlite.post(
        "/api/v1/sessions",
        headers=user_a_headers,
        json={"id": "session-evidence", "venue_id": "venue-evidence"},
    )

    rod_response = client_with_sqlite.post(
        "/api/v1/rod-sets",
        headers=user_a_headers,
        json={
            "id": "rod-1",
            "session_id": "session-evidence",
            "rod_number": 1,
            "presentation_layer": "bottom",
            "computed_rod_hours": 2.5,
        },
    )
    bait_response = client_with_sqlite.post(
        "/api/v1/bait-applications",
        headers=user_a_headers,
        json={
            "id": "bait-1",
            "session_id": "session-evidence",
            "rod_set_id": "rod-1",
            "bait_category": "boilie",
            "spread_pattern": "tight",
        },
    )
    observation_response = client_with_sqlite.post(
        "/api/v1/observations",
        headers=user_a_headers,
        json={
            "id": "observation-1",
            "session_id": "session-evidence",
            "observation_type": "show",
            "confidence_level": 80,
        },
    )
    water_response = client_with_sqlite.post(
        "/api/v1/water-readings",
        headers=user_a_headers,
        json={
            "id": "water-1",
            "session_id": "session-evidence",
            "water_temp_c": 14.2,
            "dissolved_oxygen_mg_l": 7.4,
        },
    )
    weather_response = client_with_sqlite.post(
        "/api/v1/weather-snapshots",
        headers=user_a_headers,
        json={
            "id": "weather-1",
            "session_id": "session-evidence",
            "source": "manual",
            "air_temp_c": 16.0,
            "wind_speed_mps": 4.0,
        },
    )
    bite_response = client_with_sqlite.post(
        "/api/v1/bite-events",
        headers=user_a_headers,
        json={
            "id": "bite-1",
            "session_id": "session-evidence",
            "rod_set_id": "rod-1",
            "event_type": "liner",
        },
    )
    cross_user_observation = client_with_sqlite.post(
        "/api/v1/observations",
        headers=user_b_headers,
        json={
            "id": "observation-cross",
            "session_id": "session-evidence",
            "observation_type": "show",
        },
    )

    assert rod_response.status_code == 201
    assert bait_response.status_code == 201
    assert observation_response.status_code == 201
    assert water_response.status_code == 201
    assert weather_response.status_code == 201
    assert bite_response.status_code == 201
    assert cross_user_observation.status_code == 403
    assert client_with_sqlite.get("/api/v1/observations", headers=user_a_headers).json()[0]["id"] == "observation-1"
    assert client_with_sqlite.get("/api/v1/observations", headers=user_b_headers).json() == []


def test_lake_brain_counts_normalized_sessions_catches_and_blanks(client_with_sqlite: TestClient) -> None:
    client_with_sqlite.post(
        "/api/v1/venues",
        json={
            "id": "venue-lake-brain",
            "name": "Lake Brain Test Water",
            "type": "lake",
            "privacy_level": "private",
        },
    )
    for session_id in ("session-1", "session-2"):
        response = client_with_sqlite.post(
            "/api/v1/sessions",
            json={
                "id": session_id,
                "venue_id": "venue-lake-brain",
                "status": "ended",
                "target_species": "carp",
            },
        )
        assert response.status_code == 201

    catch_response = client_with_sqlite.post(
        "/api/v1/catches",
        json={
            "id": "catch-1",
            "session_id": "session-1",
            "species": "carp",
            "weight_lb": 20,
            "weight_oz": 4,
            "caught_at": "2026-05-20T06:30:00Z",
            "returned_safely": True,
        },
    )
    assert catch_response.status_code == 201

    blank_response = client_with_sqlite.post(
        "/api/v1/blanks",
        json={
            "id": "blank-1",
            "session_id": "session-2",
            "started_at": "2026-05-21T18:00:00Z",
            "ended_at": "2026-05-22T06:00:00Z",
            "rods_active_count": 3,
        },
    )
    assert blank_response.status_code == 201

    summary_response = client_with_sqlite.get("/api/v1/venues/venue-lake-brain/lake-brain-summary")

    assert summary_response.status_code == 200
    summary = summary_response.json()
    assert summary["sample_size"] == 2
    assert summary["catch_count"] == 1
    assert summary["blank_interval_count"] == 1
    assert summary["confidence"] <= 50
    assert "Fewer than 10 sessions are logged for this venue." in summary["data_gaps"]
