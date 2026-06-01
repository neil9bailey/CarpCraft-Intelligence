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

Push-Location "backend"
try {
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }
    .\.venv\Scripts\python.exe -m pip install -e ".[dev]"
    .\.venv\Scripts\python.exe -m pytest
}
finally {
    Pop-Location
}

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Push-Location "mobile\carpcraft_app"
    try {
        flutter test
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warning "Skipping Flutter tests because Flutter is not on PATH."
}
