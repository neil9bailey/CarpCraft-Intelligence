# AGENTS.md

## Mission

CarpCraft Intelligence is an Android-first, privacy-first mobile intelligence product for carp anglers. It should help users make better watercraft decisions from logged evidence, not pretend to predict catches with certainty.

## Coding Standards

- Keep the codebase modular and commercial-product ready.
- Prefer simple, typed interfaces over clever abstractions.
- Keep deterministic rules separate from API routing and AI wording.
- Use Pydantic schemas for backend contracts.
- Use Flutter/Dart patterns that preserve future iOS portability.
- Add focused tests after behavior changes where practical.
- Preserve existing files and avoid destructive operations.

## Privacy Principles

- Private by default.
- Do not introduce public sharing by default.
- Treat venues, swims, spots, catch locations, target fish notes and photos as sensitive.
- Do not collect precise location unless the user explicitly chooses to add it.
- Document future export, deletion and consent flows.

## Intelligence Principles

- AI must stay grounded in structured data and retrieved knowledge.
- Never invent venue facts, catch history, target fish details or fishery rules.
- Always show confidence, evidence and data gaps.
- Never guarantee catches.
- Warn users not to disturb spawning fish.
- Encourage ethical angling, fish care and compliance with local fishery rules.

## Commercial And Licensing Rules

- Preserve proprietary, all-rights-reserved licensing for app code.
- Do not add an open-source project license such as MIT or Apache to this repository.
- Track third-party dependencies and notices before release.
- Legal and compliance documents are engineering drafts until reviewed by counsel.

## Android-First Rule

- Android local testing is the first mobile target.
- Keep future iOS support realistic, but do not block MVP work on iOS.
- Avoid unnecessary Android-only assumptions in domain, state and service layers.

## Test Discipline

- Run backend tests after backend changes where possible.
- Run Flutter tests after mobile changes where Flutter is available.
- If a tool is missing locally, document the gap clearly.
