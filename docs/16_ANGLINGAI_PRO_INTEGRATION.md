# 16 AnglingAI Pro Integration

Reviewed on 2026-06-02 against `https://anglingai.co.uk/docs` and the production Key Vault API key.

## What Pro Gives CarpCraft Now

- `POST /venue-research` works with the Pro key and returns structured venue data, cited sources, confidence, provider and model metadata.
- `POST /swim-selector` works with the Pro key for advisory swim/peg selection from weather, season and venue features.
- `POST /fish-id` is documented for capture-photo analysis and should be used only for user-supplied images.
- `POST /session-plan`, `POST /peg-analyser`, `POST /bait-calculator`, `POST /rig-builder`, `POST /catch-log` and `POST /catch-log/analysis` are relevant future adapters for session planning and personal pattern analysis.

## Gated Or Unavailable From This Key

- `GET /locations` returned `401` with the Pro key during live probing.
- `GET /fishery-lakes` returned `401`; the docs mark fishery lakes/pegs as Fishery plan and above.
- `POST /weather`, `POST /water-temp` and `POST /solunar` returned `404` during live probing, despite being listed in the docs. CarpCraft should keep Met Office and Open-Meteo as the primary weather providers until these endpoints are confirmed live.

## Fisheries Import Pattern

AnglingAI Pro is not currently an "all fisheries directory" feed. Use it as an enrichment layer:

1. Seed candidate fisheries from approved sources: official fishery pages, Google Places, Catch/GoCatch partner links, Swimbooker partner links, or user-provided account exports.
2. Call AnglingAI `venue-research` for each seed name/location.
3. Store the output as external advisory evidence with cited source links and confidence.
4. Normalize only reviewed facts into CarpCraft `FisheryProfile`, `Venue`, `Swim`, `MapAsset`, `rules`, `costs` and `booking` fields.
5. Keep imported profiles private by default until explicit public-sharing consent and source/licensing review are complete.

## Implemented

- CarpCraft backend now sends documented camelCase payloads to AnglingAI.
- Venue intelligence includes an AnglingAI Pro venue-research connector when `ANGLINGAI_API_KEY` is configured.
- Key-backed enrichment routes remain protected by Microsoft Entra in production.

## Future Upgrade Path

If the account is upgraded to AnglingAI Fishery plan or AnglingAI enables location/lake endpoints for this key, add:

- `GET /locations` account-location import.
- `GET /fishery-lakes` and `GET /fishery-lakes/:id/pegs` lake/swim import.
- `POST /fishery-overrides` only for CarpCraft-owned or fishery-approved knowledge; do not push third-party facts without permission.
