Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$localFlutter = "F:\tools\flutter\bin"
if ((-not (Get-Command flutter -ErrorAction SilentlyContinue)) -and (Test-Path (Join-Path $localFlutter "flutter.bat"))) {
    $env:Path = "$localFlutter;$env:Path"
}
$env:GRADLE_USER_HOME = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { "F:\tools\gradle-cache" }
$env:PUB_CACHE = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "F:\tools\pub-cache" }
$env:TEMP = if ($env:TEMP -and $env:TEMP.StartsWith("F:\")) { $env:TEMP } else { "F:\tools\tmp" }
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME, $env:PUB_CACHE, $env:TEMP | Out-Null

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter was not found on PATH. Install Flutter and Android tooling, then rerun this script."
}

Push-Location "mobile\carpcraft_app"
try {
    $apiBaseUrl = if ($env:CARPCRAFT_API_BASE_URL) { $env:CARPCRAFT_API_BASE_URL } else { "http://10.0.2.2:8000" }
    $userId = if ($env:CARPCRAFT_USER_ID) { $env:CARPCRAFT_USER_ID } else { "mobile-local-user" }
    $entraTenantId = if ($env:ENTRA_TENANT_ID) { $env:ENTRA_TENANT_ID } else { "67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da" }
    $entraClientId = if ($env:ENTRA_CLIENT_ID) { $env:ENTRA_CLIENT_ID } else { "96e02813-75a8-4fef-a8f2-d1c8b41234c6" }
    $entraApiScope = if ($env:ENTRA_API_SCOPE) { $env:ENTRA_API_SCOPE } else { "api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3/access_as_user" }
    $entraRedirectUrl = if ($env:ENTRA_REDIRECT_URL) { $env:ENTRA_REDIRECT_URL } else { "com.carpcraft.intelligence://oauthredirect" }
    flutter pub get
    flutter run -d android `
        --dart-define="CARPCRAFT_API_BASE_URL=$apiBaseUrl" `
        --dart-define="CARPCRAFT_USER_ID=$userId" `
        --dart-define="GOOGLE_MAPS_API_KEY=$env:GOOGLE_MAPS_API_KEY" `
        --dart-define="ENTRA_TENANT_ID=$entraTenantId" `
        --dart-define="ENTRA_CLIENT_ID=$entraClientId" `
        --dart-define="ENTRA_API_SCOPE=$entraApiScope" `
        --dart-define="ENTRA_REDIRECT_URL=$entraRedirectUrl"
}
finally {
    Pop-Location
}
