# Google Play Data Safety Matrix Draft

Engineering draft only. Legal review is required before Play Store submission.

| Data Type | Collected In MVP | Future Use | Shared With Third Parties | Purpose | User Control |
| --- | --- | --- | --- | --- | --- |
| Name | Not in Phase A scaffold | Account profile | Auth provider later | Account management | Future edit/delete |
| Email | Not in Phase A scaffold | Login and account support | Auth provider later | Authentication | Future export/delete |
| Approximate location | Optional | Venue labels and weather | Weather provider if enabled | App functionality | User chooses |
| Precise location | Not required | Spot pins if enabled | Maps/weather provider if enabled | App functionality | Explicit consent |
| Photos | Not in Phase A scaffold | Catch photos | Storage provider if enabled | User content | User delete |
| Session logs | Mock/local scaffold | Private user records | Backend/cloud provider | App functionality | Export/delete planned |
| Catch data | Mock/local scaffold | Private user records | Backend/cloud provider | App functionality | Export/delete planned |
| Blank data | Mock/local scaffold | Private user records | Backend/cloud provider | App functionality | Export/delete planned |
| Health data | No | None planned | No | Not applicable | Not applicable |
| Financial data | No | Subscription later | App stores/payment provider | Payments | Store controls |
| Diagnostics | No | Crash reporting later | Crash provider if enabled | App quality | Consent/settings |
| Analytics | No | Product analytics later | Analytics provider if enabled | App improvement | Consent/settings |
| AI prompts/context | No external calls in Phase A | AI explanations later | AI provider if enabled | App functionality | Consent/settings |

## Notes

- The app should not sell user data.
- Public sharing is not part of MVP.
- Precise location should be off by default.
- Data deletion and export must be implemented before broader commercial launch.
