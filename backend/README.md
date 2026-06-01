# CarpCraft Intelligence Backend

FastAPI backend scaffold for the CarpCraft Intelligence MVP.

## Run

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

## Test

```powershell
python -m pytest
```

## Scope

Phase B has started with SQLAlchemy and Alembic migrations. The backend now has:

- A JSON resource store for secondary scaffold resources.
- Normalized tables for venues, swims, spots, sessions, rod sets, bait applications, observations, water readings, weather snapshots, bite events, catches, blank intervals, recommendations and recommendation outcomes.
- A local auth scaffold using `X-CarpCraft-User-Id` for development-only owner scoping.
- Lake Brain summary counts backed by normalized session, catch and blank data.

## Migrate

Start PostgreSQL from the repo root:

```powershell
docker compose up -d
```

Then run:

```powershell
python -m alembic upgrade head
```

## Persistence Note

The MVP persistence layer keeps `json_resource_records` as a bridge for later resources. Query-heavy entities now use normalized tables so venue memory and effort-normalized reporting can grow without parsing opaque JSON.

## Local Auth Scaffold

During local development, requests can include `X-CarpCraft-User-Id`. If the header is absent, the backend uses `LOCAL_DEV_USER_ID` from `.env`. Venues and sessions are scoped to that principal; replace this with real JWT/session validation before shared testing.
