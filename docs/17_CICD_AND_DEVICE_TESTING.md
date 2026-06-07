# 17. CI/CD and Android Device Testing

This guide explains how to ship the backend to Azure and get an installable APK
onto an Android tablet for live testing, using GitHub Actions so privileged
credentials stay in your GitHub repository secrets and never sit on a developer
machine or in the codebase.

There are three workflows in `.github/workflows/`:

| Workflow | File | Trigger | Output |
| --- | --- | --- | --- |
| Backend CI | `backend-ci.yml` | push / PR to `backend/**` | tests + migration check |
| Android Release APK | `android-release.yml` | manual, or tag `v*` | downloadable signed APK |
| Deploy Backend to Azure | `azure-deploy.yml` | manual | image build + Container App rollout |

> Workflows only run after these files are on a branch in GitHub **and** Actions
> is enabled for the repository (Settings -> Actions -> General).

---

## 1. Deploy the backend to Azure

### One-time setup

1. Create a deployment service principal scoped to the resource group:
   ```bash
   az ad sp create-for-rbac --name carpcraft-deploy \
     --role contributor \
     --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
     --sdk-auth
   ```
   Copy the entire JSON output.

2. In GitHub: **Settings -> Secrets and variables -> Actions**.
   - Add a **secret** `AZURE_CREDENTIALS` = the JSON from step 1.
   - Add **variables**:
     - `AZURE_RESOURCE_GROUP` — the resource group name
     - `ACR_NAME` — your Azure Container Registry name (without `.azurecr.io`)
     - `CONTAINERAPP_NAME` — the target Container App name
     - (optional) `BACKEND_IMAGE_REPO` — defaults to `carpcraft-backend`

   The infra to create these resources is scaffolded in `infra/bicep/main.bicep`
   and described in `docs/15_AZURE_DEPLOYMENT.md`.

### Deploy

Actions tab -> **Deploy Backend to Azure** -> **Run workflow**. It builds the
image in ACR (`az acr build`, no local Docker needed) and updates the Container
App to the new image, then prints the new revision name.

The container runs `alembic upgrade head` on start, so the new
recommendation-plan columns migrate automatically.

---

## 2. Build a release APK for the tablet

### One-time setup: create and register a keystore

```bash
keytool -genkey -v -keystore carpcraft-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias carpcraft

# base64 for the GitHub secret (macOS/Linux)
base64 -w0 carpcraft-release.jks > carpcraft-release.jks.b64   # Linux
# base64 -i carpcraft-release.jks | tr -d '\n' > carpcraft-release.jks.b64  # macOS
```

Keep `carpcraft-release.jks` somewhere safe — you need the **same** keystore to
ship future updates. It is gitignored and must never be committed.

Add these **secrets** in GitHub Actions:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | contents of `carpcraft-release.jks.b64` |
| `ANDROID_KEYSTORE_PASSWORD` | store password you chose |
| `ANDROID_KEY_ALIAS` | `carpcraft` (or your alias) |
| `ANDROID_KEY_PASSWORD` | key password you chose |
| `GOOGLE_MAPS_API_KEY` | *(optional)* Android Maps SDK key |

Add these **variables** so the build points at your backend:

| Variable | Value |
| --- | --- |
| `CARPCRAFT_API_BASE_URL` | e.g. `https://carpcraft.diiac.io` or the Container App URL |
| `CARPCRAFT_USER_ID` | *(optional)* dev user id for local-auth backends |

### Build

Actions tab -> **Android Release APK** -> **Run workflow** (you can override the
backend URL for a single build). When it finishes, open the run and download the
`carpcraft-intelligence-release-apk` artifact (a zip containing
`app-release.apk`).

Tagging a release also attaches the APK to a GitHub Release:
```bash
git tag v0.1.0 && git push origin v0.1.0
```

### Install on the tablet

1. Copy `app-release.apk` to the tablet (USB, Drive, or download the artifact in
   the tablet's browser while signed in to GitHub).
2. On the tablet: **Settings -> Apps -> Special access -> Install unknown apps**,
   and allow your browser/file manager to install.
3. Open the APK and install. The app is `CarpCraft Intelligence`
   (`com.carpcraft.intelligence`).

> Production auth uses the DIIAC Entra tenant (see the README). For early local
> testing you can point `CARPCRAFT_API_BASE_URL` at a dev backend that uses the
> local `X-CarpCraft-User-Id` auth mode.

---

## Local fallbacks (no CI)

- **APK locally:** `cd mobile/carpcraft_app && flutter build apk --release`
  (after creating `android/key.properties` from your keystore).
- **Azure locally:** `scripts/build_push_backend_image.ps1 -ImageTag <acr>.azurecr.io/carpcraft-backend:latest -Execute`
  then `az containerapp update ...`, while signed in with `az login`.

---

## Troubleshooting live testing

The app is **live-first**: there is no demo/offline data, so if it cannot reach a
working backend, weather, venues and recommendations will be empty or show errors.

### "Weather / venues / recommendations not working"
0. The **Dashboard shows a red "Backend not reachable" banner** when it cannot
   reach the API, with **Open Settings** and **Retry** buttons. If you see it,
   the backend URL is wrong or the backend is down/unreachable.
1. Open **Settings -> Backend connection**, enter your backend URL (the Azure
   Container App URL, or `http://<your-LAN-ip>:8000` for a dev server), tap
   **Save**, then **Test connection**. A green "Connected" confirms reachability.
   - The build's default is `http://10.0.2.2:8000`, which only works on an
     Android *emulator*, never on a physical tablet — so on a tablet you must set
     this.
2. Weather uses Open-Meteo (no key needed) but the **backend** must have outbound
   internet. A backend behind a strict egress policy returns empty weather.
3. **Venue search** requires live, configured sources. Set `ANGLINGAI_API_KEY`
   on the backend for dynamic fishery research. Enable backend Google Places only
   after a server/IP-restricted key works by setting `GOOGLE_PLACES_ENABLED=true`
   and `GOOGLE_PLACES_API_KEY`. With no live source keys, search legitimately
   returns nothing.
4. If the backend runs in production Entra mode (`AUTH_MODE=entra`,
   `AUTH_REQUIRED=true`), you must **Sign in** (Settings -> Account) or every
   request returns 401. For early testing, run the backend with the default
   `AUTH_MODE=local`.

### "Google Maps not working" (grey/blank map)
The map needs the key in **two** places, and the release workflow now sets both:
1. The **AndroidManifest** key (native Maps SDK) — from the `GOOGLE_MAPS_API_KEY`
   secret via Gradle.
2. The **`--dart-define=GOOGLE_MAPS_API_KEY`** — gates the in-app map widget.
   (Before this was only set in the manifest, so the app showed "Maps key
   missing" even when the key was present.)
3. In Google Cloud, enable **Maps SDK for Android** and ensure the key's app
   restriction allows package `com.carpcraft.intelligence` **and the SHA-1 of the
   release keystore** used to sign the APK.

### Cleartext HTTP
Release builds now permit cleartext via `res/xml/network_security_config.xml` so
LAN dev backends over `http://` work during testing. Production backends should
use HTTPS; tighten this config before a public release.
