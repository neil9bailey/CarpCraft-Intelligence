Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "backend"
try {
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
    }
    $port = if ($env:API_PORT) { [int]$env:API_PORT } else { 8000 }
    while (Test-NetConnection -ComputerName 127.0.0.1 -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue) {
        Write-Warning "Port $port is already in use. Trying $($port + 1)."
        $port += 1
    }
    .\.venv\Scripts\python.exe -m pip install -e ".[dev]"
    .\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port $port
}
finally {
    Pop-Location
}
