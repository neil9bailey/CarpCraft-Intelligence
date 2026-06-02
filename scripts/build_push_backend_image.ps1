param(
    [string]$ImageTag,
    [switch]$Execute
)

$ErrorActionPreference = "Stop"

if (-not $ImageTag) {
    throw "ImageTag is required, for example diiac.azurecr.io/carpcraft-backend:latest"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot "backend"

$commands = @(
    @("docker", "build", "-t", $ImageTag, $backendDir),
    @("docker", "push", $ImageTag)
)

foreach ($command in $commands) {
    Write-Host ($command -join " ")
    if ($Execute) {
        $exe = $command[0]
        $args = $command[1..($command.Count - 1)]
        & $exe @args
    }
}

if (-not $Execute) {
    Write-Host "Dry run only. Add -Execute to build and push."
}
