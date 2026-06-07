# 16 AnglingAI Pro Integration

Reviewed on 2026-06-04 against `https://anglingai.co.uk/docs` and the production integration expectations.

## What Pro Gives CarpCraft Now

- `POST /venue-research` works with the Pro key and returns structured venue data, cited sources, confidence, provider and model metadata.
- `POST /swim-selector` works with the Pro key for advisory swim/peg selection from weather, season and venue features.
- `POST /fish-id` is documented for capture-photo analysis and should be used only for user-supplied images.
- `GET /locations` is documented as Pro-and-above saved fishing locations. Treat it as private account data and verify live access before using it for import.
- `POST /weather`, `POST /water-temp` and `POST /solunar` are documented for advisory weather interpretation, thermal-lag water temperature estimates and solunar windows. Keep Open-Meteo and Met Office as the primary weather data sources; use AnglingAI as advisory interpretation when the endpoint responds.
- `POST /session-plan`, `POST /peg-analyser`, `POST /bait-calculator`, `POST /rig-builder`, `POST /catch-log` and `POST /catch-log/analysis` are relevant future adapters for session planning and personal pattern analysis.

## Gated Or Unavailable From This Key

- `GET /fishery-lakes` returned `401`; the docs mark fishery lakes/pegs as Fishery plan and above.
- Any endpoint that returns `401`, `404`, quota exhaustion or plan gating must be surfaced as provider evidence/data gaps, not hidden behind fallback content.

## Fisheries Import Pattern

AnglingAI Pro is not currently an "all fisheries directory" feed. Use it as an enrichment layer:

1. Seed candidate fisheries from integrated sources: official fishery pages, Google Places, AnglingAI venue research, or explicit user-provided evidence.
2. Call AnglingAI `venue-research` for each seed name/location.
3. Store the output as external advisory evidence with cited source links and confidence.
4. Normalize only reviewed facts into CarpCraft `FisheryProfile`, `Venue`, `Swim`, `MapAsset`, `rules`, `costs` and `booking` fields.
5. Keep imported profiles private by default until explicit public-sharing consent and source/licensing review are complete.

## Implemented

- CarpCraft backend now sends documented camelCase payloads to AnglingAI.
- Venue intelligence includes an AnglingAI Pro venue-research connector when `ANGLINGAI_API_KEY` is configured.
- Fishery profile creation now requires active live AnglingAI venue-research evidence; source packs alone are not enough to seed the production catalogue.
- Key-backed enrichment routes remain protected by Microsoft Entra in production.

## Future Upgrade Path

If the account is upgraded to AnglingAI Fishery plan or AnglingAI enables location/lake endpoints for this key, add:

- `GET /locations` account-location import.
- `GET /fishery-lakes` and `GET /fishery-lakes/:id/pegs` lake/swim import.
- `POST /fishery-overrides` only for CarpCraft-owned or fishery-approved knowledge; do not push third-party facts without permission.
