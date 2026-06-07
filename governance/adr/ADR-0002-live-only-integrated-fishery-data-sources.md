# Architecture Decision Record

**ADR ID:** ADR-0002
**Title:** Live-only integrated fishery data sources
**Epic ref:** E-core-fishery-data-live-only
**Status:** Approved
**Author (role):** Enterprise Architect
**EA reviewer:** Enterprise Architect
**CTO (if cross-cutting):** Required before release
**Date raised / Date decided:** 2026-06-07 / 2026-06-07

## 1. Context

Fishery data is the core product substrate for CarpCraft Intelligence. Users must be able to
search UK carp fisheries dynamically and receive useful, source-grounded profiles with location,
rules, access, facilities, lakes/swims, weather context, map links, confidence and data gaps.

The current baseline still mentions or surfaces sources such as Catch/GoCatch and Swimbooker as
future partner/manual connectors. That creates a product trust problem: if CarpCraft cannot
actually integrate, query, or normalize data from those sources today, the user experience should
not imply that those sources are active or beneficial.

The live sources currently available to CarpCraft are:

- AnglingAI Pro `venue-research` and related advisory endpoints where the key/plan permits access.
- Google Places Text Search for backend location/directory enrichment when a server-side Places key
  is correctly configured.
- Open-Meteo and Met Office for weather conditions.
- Official public fishery pages and fishery-approved public URLs as source links, not scraped or
  cached assets unless licensing is reviewed.
- User-entered private venue/session/capture evidence.

## 2. Decision

Adopt a live-only, integrated-source policy for fishery catalogue and profile features.

1. Remove production-facing Catch/GoCatch and Swimbooker connectors, references and data gaps unless
   an actual API/export/permissioned integration is implemented and verified.
2. Keep fishery profiles private by default and source-bound. Never invent rules, costs, swim maps,
   catch reports, opening times or stock details.
3. Make dynamic UK carp fishery search a first-class live flow:
   - search saved private profiles first;
   - when no saved match exists, call live venue intelligence;
   - require active AnglingAI venue research before returning/importing a profile;
   - enrich coordinates and directory links with Google Places when the backend server key works;
   - show provider failures as data gaps, not as fake results.
4. Normalize as much key profile data as current integrated sources provide:
   - identity and location;
   - evidence/confidence/source URLs;
   - access, rules, facilities, lakes/swims/depth/map links when explicitly supplied by integrated
     sources or official pages;
   - weather context from Open-Meteo/Met Office;
   - clear data gaps for anything not evidenced.
5. Official public fishery pages may be linked and summarized only where sourced and attributed.
   Map/depth-map images remain links unless licensing review approves caching.
6. AnglingAI output is advisory evidence. It may seed structured sections when the response includes
   explicit fields, but those fields must remain marked as advisory unless verified against cited
   official sources.
7. No Facebook/group scraping and no private account scraping. User-provided links or exports must be
   handled as explicit user evidence, not silent ingestion.

## 3. Drift assessment

- Does this deviate from the approved architecture baseline? Yes. ADR-0001 allowed future
  partner/manual source placeholders. This ADR tightens the baseline: no unintegrated provider
  placeholders in production-facing flows.
- Does it still serve the end-to-end deliverable? Yes. It improves trust and focuses the core app on
  working live fishery intelligence.
- Impact:
  - Backend: remove non-working provider connectors and booking/data-gap language; improve dynamic
    profile normalization from integrated sources.
  - Mobile: remove UI copy that implies unavailable partner integrations; keep live search/research
    workflow clear.
  - Docs: update API/source policy to reflect live-only integrated sources.
  - QA/UAT: verify fresh-user dynamic UK fishery search, profile preview/import, map link, weather and
    data gaps on real Android hardware.

## 4. Options considered

| Option | Pros | Cons | Risk |
|--------|------|------|------|
| A. Keep partner placeholders | Keeps roadmap visible | Users see sources that do not work today | High trust risk |
| B. Remove all external fishery data | Simple and safe | Undermines core fishery catalogue value | High product value risk |
| C. Live-only integrated-source policy | Honest, useful and extensible | Requires cleanup and tighter tests | Lower long-term risk |
| D. Scrape directories/groups | More apparent coverage | Legal, privacy and reliability risk | Unacceptable |

Decision: choose Option C.

## 5. Consequences

What becomes easier:

- Users understand exactly which live sources are driving the profile.
- Provider failures are obvious and actionable.
- Product trust improves because unsupported partner claims disappear.
- Future provider integrations can be added cleanly when they are real.

What becomes harder:

- Some booking/cost details will remain data gaps until AnglingAI/cited official pages provide them
  or a permissioned integration exists.
- Dynamic search quality depends on AnglingAI, Google Places and official source evidence.
- UAT must check more than route success: profiles must be useful, grounded and honest.

New constraints:

- No production-facing Catch/GoCatch or Swimbooker references until working integration exists.
- No fake catalogue completeness.
- No silent scraping.
- Every profile must include evidence, confidence and data gaps.

## 6. Verification plan

G2 implementation:

- Remove Catch/GoCatch and Swimbooker connector classes and production-facing references.
- Update source/data-gap copy in backend, mobile and docs.
- Improve dynamic fishery profile normalization from AnglingAI advisory fields and Google Places
  when configured.
- Preserve private-by-default profile ownership.

G3 technical verification:

- Backend tests for dynamic search from a fresh user.
- Backend tests proving no Catch/Swimbooker connector statuses, booking options or data gaps are
  emitted without an actual integration.
- Backend tests for AnglingAI structured fields flowing into profile sections.
- Existing backend suite must pass.
- Mobile analyze/test where Flutter is available for changed UI copy.

G4 real end-user UAT:

- On Android tablet, sign in through Entra.
- Search at least three UK carp fisheries, including one known source-pack fishery and one dynamic
  AnglingAI-only fishery.
- Confirm profile preview, evidence, confidence, data gaps, weather and map action are useful.
- Import/save one profile and confirm it remains private.

G5 security/compliance:

- Confirm no secrets in git.
- Confirm precise location remains opt-in.
- Confirm no unpermissioned scraping or public sharing.

## 7. ARB checkpoint

- [x] EA has reviewed against the architecture baseline
- [x] Drift assessment complete
- [x] Verification plan includes real live end-user UAT
- [ ] CTO consulted if cross-cutting
- [x] Human approved ADR
- [x] Approved - work may proceed to G2

**Decision rationale:**

Fishery data is too central to carry dead-source theatre. CarpCraft should be narrower and honest:
live integrated providers, attributed official links, advisory AI with confidence and gaps, and
private user evidence. Unsupported partners can return later only when there is a real integration.
