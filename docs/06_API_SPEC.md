# 06 API Spec

FastAPI exposes OpenAPI at `/docs` and `/openapi.json` when the backend is running.

## Auth

Requests may include `X-CarpCraft-User-Id` to simulate the current user during local development. If the header is absent, the backend uses `LOCAL_DEV_USER_ID`. Venues and sessions are owner-scoped in this first pass; production requests use Entra bearer-token validation.

Production auth uses Microsoft Entra ID bearer tokens from the DIIAC tenant.

- `APP_ENV=production`
- `AUTH_MODE=entra`
- `AUTH_REQUIRED=true`
- `ENTRA_TENANT_ID=67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da`
- `ENTRA_AUDIENCES=api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3,9f0ac07a-2cce-4e4b-b74b-41264c6594e3`

The backend validates the JWT signature from Microsoft JWKS, issuer, audience, token tenant ID and stable user identifier. In production, startup requests fail closed if `AUTH_REQUIRED` is not true.

## Implemented Phase A Routes

- `GET /health`
- `GET /api/v1/version`
- `GET/POST/GET by id/PUT/DELETE /api/v1/venues`
- `GET/POST/GET by id/PUT/DELETE /api/v1/swims`
- `GET/POST/GET by id/PUT/DELETE /api/v1/spots`
- `GET/POST/GET by id/PUT/DELETE /api/v1/sessions`
- `POST /api/v1/sessions/{id}/start`
- `POST /api/v1/sessions/{id}/end`
- `GET/POST/GET by id/PUT/DELETE /api/v1/rod-sets`
- `GET/POST/GET by id/PUT/DELETE /api/v1/bait-applications`
- `GET/POST/GET by id/PUT/DELETE /api/v1/observations`
- `GET/POST/GET by id/PUT/DELETE /api/v1/water-readings`
- `GET/POST/GET by id/PUT/DELETE /api/v1/weather-snapshots`
- `GET /api/v1/weather-snapshots/live/lookup`
- `GET /api/v1/weather-snapshots/live/conditions`
- `GET/POST/GET by id/PUT/DELETE /api/v1/bite-events`
- `GET/POST/GET by id/PUT/DELETE /api/v1/catches`
- `POST /api/v1/blanks`
- `GET /api/v1/blanks`
- `POST /api/v1/recommendations/generate`
- `POST /api/v1/recommendations/{id}/outcome`
- `GET /api/v1/venues/intelligence/lookup`
- `POST /api/v1/venues/intelligence/import`
- `GET /api/v1/venues/{id}/lake-brain-summary`
- `GET/POST/GET by id/PUT/DELETE /api/v1/capture-assets`
- `GET/POST/GET by id/PUT/DELETE /api/v1/fishery-profiles`
- `POST /api/v1/fishery-profiles/from-venue-intelligence`
- `POST /api/v1/ai-intelligence/brief`
- `GET /api/v1/ai-intelligence/example-live-session`
- `GET/POST/GET by id/PUT/DELETE /api/v1/mcp-agent-runs`
- `GET /api/v1/anglingai/status`
- `POST /api/v1/anglingai/venue-research`
- `POST /api/v1/anglingai/swim-selector`
- `POST /api/v1/anglingai/water-temp`
- `POST /api/v1/anglingai/vision`

## Route Status

Route data now persists through SQLAlchemy once migrations have been applied. Venues, swims, spots, sessions, rod sets, bait applications, observations, water readings, weather snapshots, bite events, catches, blanks, recommendations and recommendation outcomes use normalized tables. Capture assets, fishery profiles and MCP agent runs currently use `json_resource_records` until promoted.

`GET /api/v1/weather-snapshots/live/lookup` returns a multi-provider weather snapshot from configured provider adapters. Open-Meteo works with latitude and longitude without an API key. Met Office DataHub Site-specific Global Spot data is attempted with `dataSource=BD1` when `MET_OFFICE_API_KEY` is configured; otherwise the response explicitly reports that provider gap.

`GET /api/v1/weather-snapshots/live/conditions` returns the same provider evidence plus condition labels, wind direction, precipitation intensity and an approximate surface-water temperature. The water temperature is an inference with confidence and data gaps, not a measured reading.

`GET /api/v1/venues/intelligence/lookup?query=...` returns a grounded venue intelligence report with source evidence, connector statuses, licensing notes, data gaps, ethical warnings and optional live weather. Known official-source packs can augment a result, but fishery profile creation requires active live AnglingAI venue-research evidence. Google Places Text Search enrichment is attempted only when `GOOGLE_PLACES_ENABLED=true` and a server-side `GOOGLE_PLACES_API_KEY` is configured. Production-facing connector statuses are limited to enabled integrated sources; unsupported partner or social sources are not surfaced as pseudo-connectors.

`POST /api/v1/venues/intelligence/import?query=...` creates or updates a private user-owned venue and starter swim records from the grounded report. Public map/depth assets remain source links only unless `cache_allowed` is explicitly true after licensing review.

`POST /api/v1/fishery-profiles/from-venue-intelligence?query=...` creates a private fishery profile from a grounded venue report. Booking/cost entries stay source-bound and are included only when official or integrated source evidence provides them.

`POST /api/v1/capture-assets` stores camera/gallery metadata, image annotations, distance/wrap/depth fields, bottom/weed/algae state and rig/bait notes. Captures are private by default. Public sharing requires explicit `public_sharing_consent=true`; precise latitude/longitude requires `precise_location_user_enabled=true`.

`POST /api/v1/ai-intelligence/brief` creates a structured brief from weather, observations, bottom/weed conditions and capture evidence. It returns confidence, evidence, gaps, welfare warnings and a no-guarantee notice.

`/api/v1/anglingai/*` routes call AnglingAI only when `ANGLINGAI_API_KEY` is configured on the backend. Output is returned as external advisory evidence with provider attribution and review gaps.

## Recommendation Output Contract

`POST /api/v1/recommendations/generate` returns:

- recommendation_summary
- location_score
- feeding_window_score
- presentation_fit_score
- oxygen_comfort_score
- pressure_risk_score
- confidence_score
- recommended_zone
- recommended_tactic
- recommended_baiting_level
- recommended_depth_or_layer
- evidence_summary
- data_gaps
- alternative_plan
- fish_welfare_warning
