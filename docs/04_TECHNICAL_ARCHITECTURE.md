# 04 Technical Architecture

## Stack

- Mobile: Flutter and Dart.
- Backend: Python FastAPI.
- Database: PostgreSQL.
- Geo: PostGIS-ready schema design.
- Vector/RAG: pgvector-ready database image.
- Local services: Docker Compose.
- Tests: pytest and Flutter test.

## Backend Layers

- `routes`: HTTP contracts and request/response mapping.
- `schemas`: Pydantic API models.
- `services`: use-case interfaces such as weather and Lake Brain.
- `rules`: deterministic recommendation engine.
- `ai`: future explanation and RAG interfaces.
- `repositories`: persistence boundary; query-heavy resources use normalized SQLAlchemy tables and secondary scaffold resources use the JSON bridge.

## Mobile Layers

- `core`: theme, constants and mock data.
- `core/api_client.dart`: development API client using `CARPCRAFT_API_BASE_URL` and `CARPCRAFT_USER_ID` dart defines.
- `features`: dashboard, venues, sessions, recommendations and settings.
- `shared`: reusable scaffold, cards, metrics and form shell.

## Data Flow

1. User logs venue/session evidence.
2. Backend validates structured data.
3. Rules engine scores context and applies confidence caps.
4. Recommendation returns evidence, gaps and alternatives.
5. Future AI layer rewrites explanation using only structured data and retrieved snippets.

## Persistence

Alembic migration `20260601_0001` creates `json_resource_records`, a SQLAlchemy-backed JSON resource store. Migration `20260601_0002` adds normalized tables for venues, swims, spots, sessions, catches, blank intervals, recommendations and recommendation outcomes.

Pydantic schemas remain the API truth. Query-heavy entities use normalized tables; lower-priority resources can continue through the JSON bridge until they need reporting or cross-entity queries.

Use migrations before production. Sensitive entities should include owner boundaries, privacy level, audit timestamps and deletion/export support.
