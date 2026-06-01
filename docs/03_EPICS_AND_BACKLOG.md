# 03 Epics And Backlog

## EPIC 0: Repository, Tooling And Developer Experience

Goal: Make the project easy to run locally on Windows.

User stories:
- As a developer, I can clone/open the repo and understand the structure.
- As a developer, I can run backend tests.
- As a developer, I can run the Android app locally.
- As a developer, I can start local services with Docker Compose.

Acceptance criteria:
- README contains setup steps.
- `.env.example` exists.
- Scripts exist for setup, backend, mobile and tests.
- `AGENTS.md` exists.
- No secrets are committed.

## EPIC 1: Commercial, Licensing And Compliance Foundations

Goal: Prepare the product for future commercial distribution.

User stories:
- As the product owner, I have a proprietary license placeholder.
- As the product owner, I have draft Terms, Privacy Policy and EULA.
- As the product owner, I have Google Play Data Safety and future Apple privacy matrices.
- As the product owner, I have a release readiness checklist.

Acceptance criteria:
- `LICENSE.md` is proprietary and all-rights-reserved.
- Legal docs are present and marked as drafts requiring legal review.
- Privacy docs mention location data, catch data, photos, AI processing and third-party providers.
- Compliance docs mention app store requirements, consent and data deletion/export.

## EPIC 2: Android Mobile Shell

Goal: Build an Android-first mobile shell ready for MVP iteration.

User stories:
- As an angler, I can open the app and see a dashboard.
- As an angler, I can navigate to venues, sessions, recommendations and settings.
- As a tester, I can run the app on Android emulator/device.

Acceptance criteria:
- Flutter app runs when Flutter tooling is installed.
- Navigation skeleton exists.
- Core screens exist.
- App name is CarpCraft Intelligence.
- Android package ID is `com.carpcraft.intelligence`.
- Future iOS porting is not blocked by Android-only architecture.

## EPIC 3: Venue, Swim And Spot Mapping

Goal: Capture lake-specific knowledge.

User stories:
- As an angler, I can create a venue.
- As an angler, I can add swims.
- As an angler, I can add spots with depth, substrate and feature type.
- As an angler, I can mark private data.

Acceptance criteria:
- Venue, swim and spot models exist.
- API scaffolds exist.
- Mobile screens exist.
- Spot map placeholder exists.
- Privacy level exists on sensitive entities.

## EPIC 4: Session, Rod And Bait Logging

Goal: Capture complete effort data, including blanks.

User stories:
- As an angler, I can start and end a session.
- As an angler, I can configure rods.
- As an angler, I can log bait applications.
- As an angler, I can calculate rod-hours.

Acceptance criteria:
- Session, RodSet and BaitApplication models exist.
- API scaffolds exist.
- Mobile screens exist.
- Rod-hour concept is documented and represented.

## EPIC 5: Observations, Water Readings And Weather

Goal: Capture the data that drives watercraft intelligence.

User stories:
- As an angler, I can log shows, fizzing, liners and other observations.
- As an angler, I can add water temperature and optional dissolved oxygen.
- As the app, I can store weather snapshots.
- As the system, I can use pressure trend, wind, cloud, rain and light.

Acceptance criteria:
- Observation, WaterReading and WeatherSnapshot models exist.
- API scaffolds exist.
- Weather service interface exists.
- Data fields cover temperature, pressure, wind, cloud, rain and moon phase placeholder.

## EPIC 6: Catch And Blank Logging

Goal: Treat blanks as first-class learning data.

User stories:
- As an angler, I can log a catch.
- As an angler, I can log a lost fish or bite event.
- As an angler, I can log blank intervals.
- As the system, I can use blanks to avoid false patterns.

Acceptance criteria:
- BiteEvent, Catch and BlankInterval models exist.
- API scaffolds exist.
- Mobile screens exist.
- Blank logging is present in docs and app flow.

## EPIC 7: Rules-Based Intelligence Engine

Goal: Produce first explainable recommendations.

User stories:
- As an angler, I can generate a recommendation from current context.
- As an angler, I can see confidence and data gaps.
- As an angler, I can see why a tactic is suggested.

Acceptance criteria:
- Rules engine exists.
- Confidence caps are implemented.
- Oxygen risk and water temp rules exist.
- Tests exist for key rules.
- Recommendation output has fixed fields.

## EPIC 8: AI Explanation And RAG Foundation

Goal: Prepare for grounded AI explanation without hallucination.

User stories:
- As a user, I can receive plain-English advice based on structured evidence.
- As the product owner, I can later add carp biology documents to the knowledge base.
- As the system, I can separate deterministic scores from AI wording.

Acceptance criteria:
- AI service interface exists.
- RAG retriever interface exists.
- AI prompt policy is documented.
- AI must not invent facts.
- AI returns fixed JSON.

## EPIC 9: Lake Brain And Pattern Discovery

Goal: Build venue-specific memory.

User stories:
- As an angler, I can see what a venue has taught the system.
- As the system, I can summarise patterns by swim, wind, temperature, bait and time.
- As the system, I can show sample size and confidence.

Acceptance criteria:
- Lake brain summary endpoint scaffold exists.
- Pattern discovery is documented.
- Sample size and confidence are required.
- No strong claims are made from weak data.

## EPIC 10: Privacy, Security And Data Ownership

Goal: Protect sensitive angling and personal data.

User stories:
- As an angler, my venues and spots are private by default.
- As an angler, I can understand what data is collected.
- As an angler, I can export or delete my data in future.

Acceptance criteria:
- Privacy controls screen placeholder exists.
- Privacy docs exist.
- Sensitive fields are identified.
- No public sharing is built into MVP.

## EPIC 11: Testing And Quality

Goal: Keep the build stable.

User stories:
- As a developer, I can run backend tests.
- As a developer, I can run Flutter tests.
- As a product owner, I can validate recommendation behaviour with sample data.

Acceptance criteria:
- pytest tests exist.
- Flutter test placeholder exists.
- Sample data exists.
- `test_all.ps1` exists.

## EPIC 12: Play Store Internal Testing Readiness

Goal: Prepare Android for controlled testing.

User stories:
- As the product owner, I can prepare an Android App Bundle.
- As the product owner, I have store readiness docs.
- As the product owner, I know what privacy declarations are needed.

Acceptance criteria:
- Android release notes checklist exists.
- Data Safety matrix exists.
- Privacy policy draft exists.
- App permissions are minimised.
- Location permission is only requested if a feature genuinely needs it.
- Internal testing track notes exist.

## EPIC 13: Future Apple Port

Goal: Keep iOS commercially viable later.

User stories:
- As the product owner, I can port to iOS without redesigning the app.
- As the product owner, I know Apple privacy and SDK readiness tasks.

Acceptance criteria:
- Future iOS checklist exists.
- App Store privacy matrix exists.
- Flutter architecture avoids unnecessary Android-only assumptions.
- No iOS build is required in this phase.

## EPIC 14: Commercial Launch Roadmap

Goal: Prepare staged growth from private alpha to commercial product.

User stories:
- As the product owner, I can see a phased roadmap.
- As the product owner, I can defer subscriptions, social and fishery dashboards until later.

Acceptance criteria:
- Roadmap includes Prototype, Alpha, Beta and Commercial Launch.
- Monetisation is deferred but documented.
- Fisheries/club mode is future-scoped.
- Sensor integrations are future-scoped.
