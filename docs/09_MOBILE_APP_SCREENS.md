# 09 Mobile App Screens

Phase A includes a Flutter skeleton with named routes and mock data.

## Screens

- Splash / App Start
- Home Dashboard
- Venue List
- Create/Edit Venue
- Venue Detail
- Swim List
- Create/Edit Swim
- Spot Map with Google hybrid maps when configured, otherwise a local placeholder
- Start Session
- Live Session Dashboard
- Rod Setup
- Add Observation
- Add Water Reading
- Add Catch
- Add Blank Interval
- Recommendation Card
- Post-Session Review
- Settings
- Privacy and Data Controls placeholder

## API Wiring Status

The venue list/create flow and recommendation card attempt FastAPI calls when `CARPCRAFT_API_BASE_URL` is configured. They fall back to local mock data when the backend is unavailable so Android shell testing is still possible.

Settings includes DIIAC Microsoft Entra sign-in. When sign-in succeeds, API requests include an Entra bearer token. The Spot Map uses Google Maps hybrid imagery when `GOOGLE_MAPS_API_KEY` is provided and only requests precise device location after the user taps the current-location action.

## UI Principles

- Field-ready, compact and practical.
- Private data cues are visible.
- Recommendation card shows opportunity, confidence, recommended zone, layer, tactic, baiting level, reasoning, data gaps and alternative plan.
- No social sharing is included in MVP.
- Location controls must remain explicit action controls, not background tracking.
