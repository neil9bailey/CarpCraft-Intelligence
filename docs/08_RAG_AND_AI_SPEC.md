# 08 RAG And AI Spec

Production AI is not implemented in Phase A. The backend includes interfaces for a future explanation layer and retriever.

The current release includes a grounded brief builder and optional external-provider adapters. These are evidence-formatting services, not autonomous catch predictors.

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
- Treat AnglingAI and any other external AI provider as attributed advisory evidence.
- Keep MCP/agent runs private by default and require human review before public profile use.

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
- `ANGLINGAI_API_KEY`
- `ANGLINGAI_BASE_URL`

AI output should remain secondary to deterministic scores.

## MCP Agent Boundaries

- Agent runs must store objective, status, evidence, data gaps and review state.
- Agent runs must not scrape private accounts or Facebook groups.
- Catch, Swimbooker and fishery directory data must come from official partner APIs, approved exports, user-supplied links or fishery-approved public pages.
- Public sharing of generated fishery profiles requires explicit consent and source/licensing review.
