Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "backend"
try {
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }
    .\.venv\Scripts\python.exe -m pip install -e ".[dev]"
    .\.venv\Scripts\python.exe -m alembic upgrade head
}
finally {
    Pop-Location
}
