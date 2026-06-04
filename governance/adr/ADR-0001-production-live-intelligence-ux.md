# Architecture Decision Record

**ADR ID:** ADR-0001
**Title:** Production live intelligence, fishery search, maps and UX baseline
**Epic ref:** EPIC-CCINT-QUALITY-INTEL-001
**Status:** Approved
**Author (role):** Enterprise Architect
**EA reviewer:** Enterprise Architect
**CTO (if cross-cutting):** Required before release
**Date raised / Date decided:** 2026-06-04 / 2026-06-04

## 1. Context

CarpCraft Intelligence has moved beyond an MVP shell into Android-first production testing.
The current baseline is useful but inconsistent:

- The backend and documentation now describe a live, source-bound product.
- The mobile app still imports `core/mock_data.dart` and several user-facing paths fall back to offline demo values.
- Fishery search depends on backend catalogue/search routes, but AnglingAI Pro is an enrichment provider, not a guaranteed all-fisheries directory feed.
- Google Maps is wired through the Android Maps SDK key, while backend location enrichment should use a separate server-side Places key.
- Weather should use multiple credible sources: Open-Meteo, Met Office DataHub when configured, and AnglingAI interpretation only as advisory evidence.
- Capture, maps, venues, swims, spots, catch locations, photos and target fish notes are sensitive and must remain private by default.
- User-facing reports and AI explanations must show evidence, confidence and data gaps, and must never invent fishery facts or guarantee catches.

The requested work changes user-facing design, data boundaries, provider routing, reporting outputs and acceptance criteria. This ADR is mandatory before G2 implementation.

## 2. Decision

Adopt a production live-evidence architecture for CarpCraft:

1. Production app flows must be live-data-first. Demo/mock fixtures may exist only behind explicit development/test gates and must not be shown as production fallback data.
2. Fishery search will use a staged evidence pipeline:
   - private saved CarpCraft profiles;
   - approved candidate sources such as Google Places, official fishery pages, user-provided Catch/GoCatch or Swimbooker links/exports, and future partner APIs;
   - AnglingAI `venue-research` as advisory enrichment with cited sources, confidence and review gaps;
   - no scraping of Facebook groups or private/public groups without a compliant permissioned connector.
3. AnglingAI endpoints may be used where the account permits them, but every response is treated as external advisory evidence until source facts are verified. Current priority endpoints are `venue-research`, `weather`, `water-temp`, `solunar`, `swim-selector`, `vision`, `lake-map/from-location`, and `locations` if the Pro key returns access.
4. Maps will keep Google Maps SDK for Android as the primary embedded map provider for MVP production, with a separate backend Google Places key for search/enrichment. The app must expose actionable diagnostics when the mobile Maps key, package restriction, SHA-1, billing, or API enablement is wrong.
5. Google Earth-style value will be delivered through hybrid/satellite Google Maps, Places-backed coordinates, fishery map/depth-map source links, capture annotations, distance/wrap markers, and future licensed overlay assets. Replacing Google Maps with another provider is a separate build-vs-buy decision.
6. Reports and AI explanations will be generated from structured session, venue, weather, capture and provider evidence. They must include source attribution, confidence, data gaps, ethical warnings and privacy state.
7. Precise device location remains opt-in only. Public sharing remains off by default and requires explicit consent.

## 3. Drift assessment

- Does this deviate from the approved architecture baseline? Yes. It replaces the MVP demo-tolerant shell with a production live-evidence baseline and adds stronger provider/data boundaries.
- Does it still serve the original epic and end-to-end deliverable? Yes. It directly serves production readiness, live fishery search, useful maps, weather, reporting and intelligence.
- Impact on other domains / interfaces:
  - Mobile: removes production mock fallbacks, changes empty/error states, improves map/search/report flows.
  - Backend: tightens source/provider contracts, AnglingAI normalization, weather aggregation, fishery profile evidence rules.
  - Platform: requires Key Vault/env validation for AnglingAI, Met Office, Google Places and Android Google Maps keys.
  - QA/UAT: requires Android emulator and real tablet journeys, not backend-only tests.
  - Security/governance: strengthens privacy, secrets handling, consent and evidence rules.

## 4. Options considered

| Option | Pros | Cons | Risk |
|--------|------|------|------|
| A. Keep current MVP/demo-tolerant baseline | Fastest, low code churn | Continues showing mock/static data and unclear provider failures | High product trust risk |
| B. Remove demos only | Cleans obvious issues | Does not fix maps, provider contracts, reports or intelligence value | Medium; symptoms recur |
| C. Production live-evidence baseline | Aligns product, providers, UI, reports and privacy | More implementation and verification work | Lower long-term risk; requires staged delivery |
| D. Replace Google Maps immediately | Could solve some UX frustration | New licensing, integration, Android testing and provider risk | High; build-vs-buy decision needed |

Decision: choose Option C. Keep Google Maps for now, but add diagnostics and separate provider keys. Revisit Option D only if Google Maps remains blocked after key/API/billing validation and UAT.

## 5. Consequences

What becomes easier:

- Users see clean live behaviour instead of demo content.
- Provider failures become diagnosable rather than looking like product failure.
- Fishery profiles become evidence-led and defensible.
- Reports and AI outputs can be trusted because they state sources and gaps.
- Privacy posture remains consistent with the product mission.

What becomes harder:

- Empty states must be designed carefully because no fake content can mask missing data.
- AnglingAI cannot be treated as a complete fishery catalogue unless the key/plan proves that endpoint access.
- More UAT is required on Android hardware.
- Map failure cases need explicit platform checks.

New constraints:

- No production fallback to `mock_data.dart`.
- No invented venue rules, costs, lake maps, catch reports or swim facts.
- No automated Catch/GoCatch, Swimbooker or Facebook ingestion without approved API/export/permission routes.
- No release without live end-user UAT evidence.

## 6. Verification plan

G2 implementation must be incremental and each increment must include focused verification.

Baseline audit:

- Record current routes, mocks, provider config and release artifacts.
- Confirm all production-visible demo/static paths.

Data hygiene:

- Remove production mock fallbacks.
- Keep dev fixtures only behind explicit test/development gates.
- Backend tests for no static fishery seed leakage.
- Flutter tests/analyze for affected screens.

Fishery search:

- Test saved-profile search, no-result states, AnglingAI `venue-research`, provider failure states and source attribution.
- Verify no fishery fact is normalized without evidence.

Maps:

- Verify Android package `com.carpcraft.intelligence`, signing SHA-1, Maps SDK for Android enablement, billing, and API key restrictions.
- Verify backend Google Places key separately.
- Emulator and tablet journeys must show pan/zoom/tilt/rotate, marker tagging, venue recentering and external Google Maps link.

Weather and intelligence:

- Test Open-Meteo and Met Office aggregation.
- Use AnglingAI weather/water-temp/solunar as advisory interpretation when available.
- Reports must show conditions, evidence, confidence, data gaps and ethical warnings.

Security and privacy:

- Confirm no secrets in git.
- Confirm precise location and public sharing require explicit consent.
- Confirm private venue, swim, spot and capture data stays owner-scoped.

Real end-user UAT:

- Signed-in Android tablet install.
- Fishery search from a real query.
- Map load and navigation.
- Weather and AI explanation for a live venue/session.
- Capture asset creation with private default.
- Report/output review.

## 7. ARB checkpoint

- [x] EA has reviewed against the architecture baseline
- [x] Drift assessment complete and acceptable
- [x] Verification plan adequate, including live end-user UAT
- [ ] CTO consulted if cross-cutting
- [x] Human approved ADR
- [x] Approved - work may proceed to G2

**Decision rationale:**

The current product must stop behaving like a demo in production. The correct architecture is not to fabricate completeness, but to make live data, provider evidence, confidence and gaps visible. This preserves the CarpCraft mission: better watercraft decisions from logged and retrieved evidence, without pretending certainty or inventing facts.
