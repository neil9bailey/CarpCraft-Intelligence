# 15 Azure Deployment

This is the production deployment scaffold for the DIIAC tenant. It follows the PatchForge pattern: Azure Container Apps, Microsoft Entra ID, Key Vault, PostgreSQL, private blob storage and explicit DNS cutover.

## Tenant And Subscription

- Tenant: DIIAC.IO
- Tenant ID: `67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da`
- Subscription ID: `9ae9da49-de67-443b-af55-ce9db33ed8f4`
- Region: `uksouth`
- Planned hostname: `carpcraft.diiac.io`

## Resources

The Bicep template creates:

- Resource group: `rg-carpcraft-prod`
- Container Apps Environment and backend API Container App
- Dedicated Basic Azure Container Registry
- User-assigned managed identity for the API
- Key Vault with RBAC and soft delete/purge protection
- PostgreSQL Flexible Server and `carpcraft` database
- Private blob container named `captures`
- Log Analytics workspace

## Secrets

Do not commit real API keys. Store them locally in `.env` for development and in Azure Key Vault for production.

Required production Key Vault secrets:

- `database-url`: created by Bicep from the PostgreSQL deployment
- `met-office-api-key`: Met Office DataHub key
- `google-places-api-key`: server-side Google Places key
- `anglingai-api-key`: AnglingAI key from the account dashboard

Optional future secrets:

- `openai-api-key`
- `catch-partner-api-key`
- `swimbooker-partner-api-key`

## Plan Deployment

The script is what-if by default:

```powershell
$env:CARPCRAFT_POSTGRES_ADMIN_PASSWORD = "<strong-password>"
.\scripts\plan_carpcraft_azure.ps1 `
  -BackendImage "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
```

After reviewing the output:

```powershell
.\scripts\plan_carpcraft_azure.ps1 `
  -BackendImage "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" `
  -Deploy
```

## Build Backend Image

Dry run:

```powershell
.\scripts\build_push_backend_image.ps1 `
  -ImageTag "<acr-login-server>/carpcraft-backend:latest"
```

Execute:

```powershell
.\scripts\build_push_backend_image.ps1 `
  -ImageTag "<acr-login-server>/carpcraft-backend:latest" `
  -Execute
```

After pushing the backend image, rerun the deployment with `-BackendImage "<acr-login-server>/carpcraft-backend:<tag>"` so Container Apps uses the production API image.

## DNS Cutover

DNS for `diiac.io` is managed outside Azure. Do not add DNS records until the Container App exists and Azure shows the custom-domain verification value.

When ready, add these records:

| Host | Type | Value |
| --- | --- | --- |
| `carpcraft` | `CNAME` | Container App default hostname from `backendDefaultHostname` output |
| `asuid.carpcraft` | `TXT` | Container App custom-domain verification ID |

Optional API split:

| Host | Type | Value |
| --- | --- | --- |
| `api.carpcraft` | `CNAME` | Container App default hostname |
| `asuid.api.carpcraft` | `TXT` | Container App verification ID for `api.carpcraft.diiac.io` |

After DNS propagates, bind `carpcraft.diiac.io` to the Container App and issue the managed certificate.

## Auth

Production backend environment must use:

- `APP_ENV=production`
- `AUTH_MODE=entra`
- `AUTH_REQUIRED=true`
- `ENTRA_TENANT_ID=67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da`
- `ENTRA_AUDIENCES=api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3,9f0ac07a-2cce-4e4b-b74b-41264c6594e3`

## Partner Data

Catch, Swimbooker and AnglingAI integrations must stay source-bound:

- Use official partner APIs, approved exports or fishery-approved profile links.
- Do not scrape private accounts, public/private Facebook groups or copyrighted maps.
- Store public swim/depth maps as source links unless licensing review marks them cacheable.
- Treat external AI output as advisory evidence until reviewed against CarpCraft logs and fishery rules.
