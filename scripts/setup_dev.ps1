Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Setting up CarpCraft Intelligence development environment..."

$env:GRADLE_USER_HOME = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { "F:\tools\gradle-cache" }
$env:PUB_CACHE = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { "F:\tools\pub-cache" }
$env:TEMP = if ($env:TEMP -and $env:TEMP.StartsWith("F:\")) { $env:TEMP } else { "F:\tools\tmp" }
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force -Path $env:GRADLE_USER_HOME, $env:PUB_CACHE, $env:TEMP | Out-Null

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Created .env from .env.example"
}

if (Get-Command python -ErrorAction SilentlyContinue) {
    Push-Location "backend"
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }
    .\.venv\Scripts\python.exe -m pip install --upgrade pip
    .\.venv\Scripts\python.exe -m pip install -e ".[dev]"
    Pop-Location
}
else {
    Write-Warning "Python was not found on PATH. Install Python before running backend tests."
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    if (Test-Path "F:\tools\flutter\bin\flutter.bat") {
        Write-Host "Found local Flutter SDK at F:\tools\flutter."
    }
    else {
        Write-Warning "Flutter was not found on PATH. Install Flutter before running the Android app."
    }
}

Write-Host "Setup complete."
