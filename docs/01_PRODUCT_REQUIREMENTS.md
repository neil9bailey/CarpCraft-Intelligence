# 01 Product Requirements

## Product Promise

CarpCraft Intelligence helps serious carp anglers make better decisions by collecting private session evidence and producing grounded recommendations.

## Principles

1. Private by default.
2. Spots, venues, swim pins, catch locations and target fish data are not public by default.
3. Blanks are logged as carefully as catches.
4. Rod-hours and effort-normalised performance matter.
5. AI must not invent facts.
6. Recommendations include confidence, reasoning and data gaps.
7. The app never guarantees catches.
8. The app encourages ethical angling, fish care and compliance with fishery rules.
9. The app warns users not to disturb spawning fish.
10. Rule-based intelligence comes before ML.
11. RAG is for grounded explanation and later knowledge retrieval.
12. Architecture remains modular for sensors, subscriptions, fishery dashboards and iOS.

## Primary Users

- Solo carp anglers building private watercraft memory.
- Product testers validating session logging and recommendation behaviour.
- Future advanced anglers who may add water readings, fishery rules and venue notes.

## Key Workflows

- Create private venue, swim and spot records.
- Start and end a session.
- Configure rods and presentations.
- Log bait, observations, water readings, bites, catches and blank intervals.
- Generate and review a recommendation.
- Record recommendation outcomes to improve future rules.

## Trust Requirements

- Every recommendation must expose confidence and data gaps.
- Weak sample sizes must suppress confidence.
- Unknown or missing environmental readings must be visible.
- Fish welfare warnings must override tactical language.
