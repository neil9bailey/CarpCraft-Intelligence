# CarpCraft Intelligence

CarpCraft Intelligence is an Android-first mobile intelligence product for carp angling. The MVP combines private venue memory, session logging, catch and blank logging, water readings, observations and deterministic rules to produce explainable recommendations with confidence and data gaps.

The product is not a magical catch predictor and must never guarantee catches. It is an evidence-ranked watercraft assistant.

## Current State

This repository contains the Phase A scaffold plus the first Phase B persistence slice:

- FastAPI backend skeleton with route scaffolds and rule-engine tests.
- SQLAlchemy/Alembic persistence with normalized core analytics tables.
- Local auth plus production Microsoft Entra ID validation for the DIIAC tenant.
- Flutter Android-first mobile skeleton with API wiring, DIIAC sign-in, hybrid maps and explicit geolocation action.
- PostgreSQL Docker Compose using a pgvector-ready image.
- Documentation, legal/compliance drafts, sample data and Windows helper scripts.

## Requirements

- Python 3.11 or newer.
- Docker Desktop for local PostgreSQL.
- Flutter SDK for Android mobile development.
- Android Studio or an Android emulator/device for mobile testing.

Flutter was intentionally scaffolded as source files so the repo remains readable even before local Flutter tooling is installed.

## Setup

```powershell
Copy-Item .env.example .env
.\scripts\setup_dev.ps1
```

## Run Local Services

```powershell
docker compose up -d
```

## Run Backend

```powershell
.\scripts\run_backend.ps1
```

Or manually:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -e ".[dev]"
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Run database migrations after starting PostgreSQL:

```powershell
docker compose up -d
.\scripts\migrate_backend.ps1
```

Backend health check:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
```

If port 8000 is occupied, `run_backend.ps1` will try the next available port.

## Run Flutter Android App

Install Flutter first, then run:

```powershell
.\scripts\run_mobile_android.ps1
```

Or manually:

```powershell
cd mobile\carpcraft_app
flutter pub get
flutter run -d android --dart-define=CARPCRAFT_API_BASE_URL=http://10.0.2.2:8000 --dart-define=CARPCRAFT_USER_ID=mobile-local-user
```

Android app name: `CarpCraft Intelligence`

Android package/application ID: `com.carpcraft.intelligence`

For a physical Android device, set `CARPCRAFT_API_BASE_URL` to the LAN address of the development machine before running the script.

The helper scripts use `F:\tools\flutter` when Flutter is not on PATH and place Gradle/TEMP build caches under `F:\tools` to avoid filling the Windows system drive.

Production mobile auth is configured against the DIIAC tenant:

- Tenant ID: `67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da`
- API audience: `api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3`
- Mobile client ID: `96e02813-75a8-4fef-a8f2-d1c8b41234c6`
- Mobile scope: `api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3/access_as_user`
- Redirect URI: `com.carpcraft.intelligence://oauthredirect`

For production backend auth set `APP_ENV=production`, `AUTH_MODE=entra`, `AUTH_REQUIRED=true` and keep `ENTRA_AUDIENCES` aligned with `.env.example`.

Google Maps hybrid imagery is enabled when `GOOGLE_MAPS_API_KEY` is provided. Precise geolocation is requested only when the user taps the current-location control.

Weather lookup uses two explicit provider adapters: Open-Meteo for open forecast data and Met Office DataHub Site-specific Global Spot data when `MET_OFFICE_API_KEY` is configured.

## Run Tests

```powershell
.\scripts\test_all.ps1
```

Backend only:

```powershell
cd backend
python -m pytest
```

Flutter only:

```powershell
cd mobile\carpcraft_app
flutter test
```

## Privacy Defaults

- Venues, swims, spots and catch locations are private by default.
- Blanks are logged as first-class learning data.
- Precise location is not required for MVP use.
- AI and RAG are interface-only in Phase A and must not invent facts.

## Legal Status

The legal/compliance documents in this repository are engineering drafts for planning. They require qualified legal review before commercial launch, app store submission, public testing, or customer use.

## Next Build Steps

1. Add normalized tables for rod sets, bait, observations, water readings and weather snapshots.
2. Wire the Flutter app to the FastAPI API.
3. Replace the remaining JSON bridge resources where query needs demand it.
4. Add normalized persistence for user/account profile metadata once production auth is exercised end to end.
5. Add server-side weather snapshot caching and daily Met Office call-budget protection.
6. Add release signing and Play internal testing configuration.
7. Add grounded AI explanations and RAG ingestion after deterministic rules are stable.
