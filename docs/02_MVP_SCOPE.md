# 02 MVP Scope

## In Scope For Phase A

- Clean repo structure.
- FastAPI route scaffolds.
- Pydantic API schemas for core entities.
- In-memory repositories for early API shape testing.
- Rules engine with deterministic confidence caps.
- Flutter mobile shell with mock data and named routes.
- Android package identity and app label.
- Docker Compose PostgreSQL service using a pgvector-ready image.
- Documentation and compliance drafts.
- Sample data for sessions, blanks, catches and recommendations.

## Out Of Scope For Phase A

- Production database migrations.
- Real user accounts.
- OAuth or third-party auth providers.
- Live maps.
- Location permissions.
- Photo uploads.
- Payment/subscription flows.
- AI provider calls.
- App store submissions.

## MVP Success Criteria

- A developer can run backend tests.
- A developer with Flutter installed can run the Android shell.
- The API contract is visible through FastAPI/OpenAPI.
- The rules engine returns fixed fields with confidence and data gaps.
- Legal/compliance draft files exist for future review.
