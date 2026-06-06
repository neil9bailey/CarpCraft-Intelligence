# 09 Mobile App Screens

The Android app is live-data-first. Production screens use API responses, explicit empty states or provider error states rather than canned local content.

## Screens

- Splash / App Start
- Home Dashboard
- Venue List
- Create/Edit Venue
- Venue Detail
- Swim List
- Create/Edit Swim
- Spot Map with Google hybrid maps when configured, otherwise a key/configuration diagnostic surface
- Capture screen for camera/gallery evidence, image markers, distances, wraps, depth, bottom, weed, algae, rig and bait notes
- Weather screen for live conditions, approximate surface temperature, live-session AI inputs and external provider status
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

The venue list/create flow, capture save flow, weather conditions screen, AI brief and recommendation card call FastAPI through `CARPCRAFT_API_BASE_URL`. When the backend, auth token or provider configuration is unavailable, the app shows live empty/error states instead of local fallback content.

Settings includes DIIAC Microsoft Entra sign-in. When sign-in succeeds, API requests include an Entra bearer token. The Spot Map uses Google Maps hybrid imagery when `GOOGLE_MAPS_API_KEY` is provided, supports pan/zoom/tilt/rotate gestures and only requests precise device location after the user taps the current-location action.

## UI Principles

- Field-ready, compact and practical.
- Private data cues are visible.
- Recommendation card shows opportunity, confidence, recommended zone, layer, tactic, baiting level, reasoning, data gaps and alternative plan.
- No social sharing is included in MVP.
- Public contribution controls must stay opt-in and reviewable.
- Location controls must remain explicit action controls, not background tracking.
