import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from starlette.requests import Request

from app.core.auth import get_current_principal
from app.core.config import get_settings
from app.main import app


def _request(headers: dict[str, str] | None = None) -> Request:
    raw_headers = [
        (name.lower().encode("latin-1"), value.encode("latin-1"))
        for name, value in (headers or {}).items()
    ]
    return Request({"type": "http", "method": "GET", "path": "/", "headers": raw_headers})


@pytest.fixture(autouse=True)
def clear_settings_cache() -> None:
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


def test_production_requires_auth_required(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("AUTH_MODE", "local")
    monkeypatch.setenv("AUTH_REQUIRED", "false")

    with pytest.raises(HTTPException) as exc_info:
        get_current_principal(_request())

    assert exc_info.value.status_code == 500
    assert "AUTH_REQUIRED=true" in exc_info.value.detail


def test_auth_required_rejects_missing_bearer_token(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "local")
    monkeypatch.setenv("AUTH_MODE", "entra")
    monkeypatch.setenv("AUTH_REQUIRED", "true")
    monkeypatch.setenv("ENTRA_AUDIENCE", "api://carpcraft-intelligence")

    with pytest.raises(HTTPException) as exc_info:
        get_current_principal(_request())

    assert exc_info.value.status_code == 401
    assert "bearer token" in exc_info.value.detail


@pytest.mark.parametrize(
    ("path", "method"),
    [
        ("/api/v1/anglingai/status", "GET"),
        ("/api/v1/weather-snapshots/live/lookup", "GET"),
        ("/api/v1/venues/intelligence/lookup?query=Linear%20Fisheries", "GET"),
    ],
)
def test_key_backed_enrichment_routes_require_auth_in_production(
    monkeypatch: pytest.MonkeyPatch,
    path: str,
    method: str,
) -> None:
    monkeypatch.setenv("APP_ENV", "production")
    monkeypatch.setenv("AUTH_MODE", "entra")
    monkeypatch.setenv("AUTH_REQUIRED", "true")
    monkeypatch.setenv("ENTRA_AUDIENCES", "api://carpcraft-intelligence")
    get_settings.cache_clear()

    response = TestClient(app).request(method, path)

    assert response.status_code == 401
    assert "bearer token" in response.json()["detail"]
