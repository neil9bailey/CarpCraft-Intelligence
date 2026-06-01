# 11 Release And Store Readiness

This is an operational checklist, not legal advice.

## Android Internal Testing First

- Install Flutter and Android Studio.
- Verify package ID: `com.carpcraft.intelligence`.
- Verify app name: CarpCraft Intelligence.
- Run `flutter test`.
- Run on at least one emulator and one physical device.
- Build debug APK for local testing.
- Prepare Android App Bundle only after signing and release configuration are reviewed.
- Configure Google Maps API key restrictions for package `com.carpcraft.intelligence`.
- Configure Met Office DataHub access if authoritative UK weather cross-checks are required in the release environment.
- Verify DIIAC Entra app registrations and consent before internal testing.

## Play Console Preparation

- Create or verify Play Console developer account.
- Complete developer identity verification.
- Prepare privacy policy URL.
- Complete Play Data Safety form from `legal/DATA_SAFETY_MATRIX.md`.
- Complete app content rating.
- Prepare store listing copy and screenshots.
- Use internal testing before closed or production tracks.
- Gather tester feedback and crash reports.

## Permissions

- Minimise permissions.
- Do not request location permission unless a feature genuinely needs it.
- If precise location is added, require explicit user action and clear consent.

Current Android permissions:

- `INTERNET`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`

The app requests location only from the Spot Map current-location action.

## Current Build Notes

- Flutter SDK is installed locally at `F:\tools\flutter`.
- Pub, Gradle and temp caches are configured under `F:\tools` by helper scripts.
- Android CMake 3.22.1 was installed into the existing Android SDK during debug APK build.
- C: free space is critically low on the current machine and should be cleaned before release builds.
- Debug APK verification path: `flutter build apk --debug`.
- Known warning: current Android plugins still apply the Kotlin Gradle Plugin directly. This does not block the current debug build, but should be revisited before future Flutter upgrades.

## Draft Store Listing

App name: CarpCraft Intelligence

Short description: Private watercraft intelligence for serious carp anglers.

Long description:

CarpCraft Intelligence helps carp anglers plan, log and learn from every session. Build private venue memory, track swims and spots, log catches and blanks, record water readings and generate explainable recommendations based on conditions, observations and carp behaviour rules. It does not guarantee catches. It helps you make better decisions on location, timing, presentation and baiting.

Fish care and rules disclaimer: Always follow fishery rules, local law and good fish care practice. Do not disturb spawning fish.

## Future Apple Readiness

- Enrol in Apple Developer Program.
- Prepare App Store Connect record.
- Configure iOS bundle ID.
- Review App Privacy labels using `legal/APP_STORE_PRIVACY_MATRIX.md`.
- Test through TestFlight.
- Verify Xcode, signing, capabilities and SDK requirements.
