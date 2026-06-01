# 08 RAG And AI Spec

Production AI is not implemented in Phase A. The backend includes interfaces for a future explanation layer and retriever.

## AI Explanation Rules

The explanation layer must:

- Use only provided structured data and retrieved knowledge snippets.
- Not invent lake facts.
- Not invent catch history.
- Not guarantee catches.
- Always include confidence and data gaps.
- Use plain angling language.
- Return fixed JSON fields.
- Support future OpenAI integration through environment variables.

## RAG Knowledge Categories

- Carp biology
- Water temperature and metabolism
- Dissolved oxygen and weed dynamics
- Seasonal behaviour and spawning
- Weather, wind, pressure and light
- Baiting strategy
- Rig and presentation logic
- Fish care and welfare
- Venue-specific private notes
- Fishery rules

## Access Control

Venue-specific private notes and fishery rules must be scoped by owner, venue and permission. They must not leak into another user recommendation.

## Future OpenAI Adapter

Environment variables are reserved for future integration:

- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `AI_EXPLANATIONS_ENABLED`

AI output should remain secondary to deterministic scores.
