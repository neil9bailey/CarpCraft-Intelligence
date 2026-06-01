# 07 Rules Engine Spec

The first intelligence version is deterministic. It must be explainable, testable and conservative.

## Current Rules

1. If water temperature is missing, cap confidence at 65.
2. If venue history count is less than 10 sessions, cap confidence at 50.
3. If dissolved oxygen is missing during hot summer-like conditions, cap confidence at 65.
4. If water temperature is below 8C, recommend low baiting.
5. If water temperature is between 8C and 14C, recommend light to moderate baiting depending on signs.
6. If water temperature is between 14C and 20C, feeding potential can increase, but pressure and oxygen still matter.
7. If hot, still and weedy, increase oxygen risk and suggest upper layers, inflows, windward water or shaded areas.
8. If strong wind has pushed into a bank for several hours, increase windward location score.
9. If shows are logged away from current rods, recommend observation-led movement or one mobile rod.
10. If liners occur without takes, suggest presentation or layer adjustment.
11. If spawning indicators exist, warn against disturbing spawning fish.
12. If data quality is weak, state this clearly and keep confidence low.

## Output Requirements

- No certainty language.
- Confidence must be capped by missing or weak data.
- Evidence and data gaps must be explicit.
- Fish welfare warnings must override tactical excitement.
- Outcomes should be recorded for later pattern review.
