# 12 Security And Privacy

## Sensitive Data

- Venue names and location labels.
- Swim names and access notes.
- Spot coordinates, wraps, depths and feature notes.
- Catch locations and photos.
- Target fish notes.
- User email and account identifiers.
- AI prompts or retrieved private venue context.

## MVP Defaults

- Private by default.
- No public sharing.
- No required precise location.
- No hardcoded secrets.
- `.env.example` documents environment variables.
- AI integrations are disabled by default.
- Local development auth uses `X-CarpCraft-User-Id` or `LOCAL_DEV_USER_ID`.
- Production auth uses Microsoft Entra ID in the DIIAC tenant and validates bearer token signature, issuer, audience and tenant.
- Venue and session routes apply first-pass owner scoping.

## Future Requirements

- Exercise production Microsoft Entra sign-in end to end in an Android internal test build.
- Complete owner-scoped database access across every promoted resource.
- Export and delete account data.
- Audit logging for sensitive operations.
- Encryption in transit and secure storage.
- GDPR/UK GDPR readiness review.
- Explicit consent for location, photos, analytics and AI processing.

## Production Auth Configuration

DIIAC tenant ID: `67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da`

CarpCraft API app registration:

- Client ID: `9f0ac07a-2cce-4e4b-b74b-41264c6594e3`
- Audience: `api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3`
- Scope: `access_as_user`

CarpCraft mobile app registration:

- Client ID: `96e02813-75a8-4fef-a8f2-d1c8b41234c6`
- Redirect URI: `com.carpcraft.intelligence://oauthredirect`

These IDs are public identifiers, not secrets. Client secrets are not used by the mobile app.

## Fishery And Welfare

- Recommendations must include fish welfare warnings where relevant.
- Spawning indicators must trigger a warning not to disturb fish.
- The app must remind users to follow local fishery rules.
