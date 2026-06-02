param(
    [string]$SubscriptionId = "9ae9da49-de67-443b-af55-ce9db33ed8f4",
    [string]$Location = "uksouth",
    [string]$ResourceGroupName = "rg-carpcraft-prod",
    [string]$BackendImage,
    [string]$AcrLoginServer = "",
    [string]$PostgresAdminPassword = $env:CARPCRAFT_POSTGRES_ADMIN_PASSWORD,
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"

if (-not $BackendImage) {
    throw "BackendImage is required, for example diiac.azurecr.io/carpcraft-backend:latest"
}

if (-not $PostgresAdminPassword) {
    throw "Set CARPCRAFT_POSTGRES_ADMIN_PASSWORD or pass -PostgresAdminPassword."
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$template = Join-Path $repoRoot "infra\bicep\main.bicep"
$deploymentName = "carpcraft-prod-$(Get-Date -Format yyyyMMddHHmmss)"

az account set --subscription $SubscriptionId

$resourceGroupExists = az group exists --name $ResourceGroupName | ConvertFrom-Json
if (-not $resourceGroupExists) {
    if ($Deploy) {
        az group create --name $ResourceGroupName --location $Location | Out-Null
    } else {
        throw "Resource group $ResourceGroupName does not exist. Create it first or run with -Deploy after reviewing the template."
    }
}

$commonArgs = @(
    "--name", $deploymentName,
    "--resource-group", $ResourceGroupName,
    "--template-file", $template,
    "--parameters",
    "location=$Location",
    "backendImage=$BackendImage",
    "acrLoginServer=$AcrLoginServer",
    "databaseAdministratorPassword=$PostgresAdminPassword"
)

if ($Deploy) {
    Write-Host "Deploying CarpCraft Azure resources to subscription $SubscriptionId..."
    az deployment group create @commonArgs
} else {
    Write-Host "Running what-if only. Add -Deploy after reviewing output."
    az deployment group what-if @commonArgs
}
