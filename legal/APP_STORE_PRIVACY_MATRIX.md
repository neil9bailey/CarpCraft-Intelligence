# Apple App Privacy Matrix Draft

Engineering draft only. Legal review is required before App Store submission.

| Apple Category | Phase A Status | Future Declaration Consideration |
| --- | --- | --- |
| Contact Info | Not collected by scaffold | Email/name if accounts launch |
| Location | Not required by scaffold | Approximate/precise if user creates spot pins or weather lookups |
| User Content | Mock/local scaffold only | Venue notes, catch photos, session notes |
| Identifiers | Not collected by scaffold | User ID, device ID if auth/analytics added |
| Usage Data | Not collected by scaffold | Analytics if enabled |
| Diagnostics | Not collected by scaffold | Crash logs if enabled |
| Purchases | Not collected by scaffold | Subscriptions if launched |
| Sensitive Info | Avoid | Target fish notes and private venues require careful treatment even if not Apple-sensitive categories |

## Apple Readiness Notes

- Add iOS project only when ready to test.
- Prepare privacy nutrition labels from actual production behaviour.
- Do not enable tracking without explicit review and consent.
- Use TestFlight before public release.
