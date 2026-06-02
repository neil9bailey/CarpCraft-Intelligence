targetScope = 'resourceGroup'

@description('Azure region for CarpCraft production resources.')
param location string = 'uksouth'

@description('Short application name used in resource names.')
param appName string = 'carpcraft'

@description('Environment name used in tags and resource names.')
param environmentName string = 'prod'

@description('DIIAC Microsoft Entra tenant ID.')
param entraTenantId string = '67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da'

@description('Container image to run for the backend API.')
param backendImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Dedicated Azure Container Registry name. Must be globally unique.')
param acrName string = toLower('acr${appName}${environmentName}${uniqueString(subscription().id, resourceGroup().id)}')

@description('Backend API audience accepted by Microsoft Entra tokens.')
param entraAudience string = 'api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3'

@description('PostgreSQL database name.')
param databaseName string = 'carpcraft'

@description('PostgreSQL administrator login.')
param databaseAdministratorLogin string = 'carpcraftadmin'

@secure()
@description('PostgreSQL administrator password. Supply from a local environment variable or Key Vault reference during deployment.')
param databaseAdministratorPassword string

@description('Optional custom hostname for later Container Apps domain binding.')
param customDomainName string = 'carpcraft.diiac.io'

var suffix = '${appName}-${environmentName}'
var tags = {
  app: 'CarpCraft Intelligence'
  environment: environmentName
  owner: 'DIIAC'
  managedBy: 'bicep'
}
var keyVaultSecretsUserRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${suffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${suffix}-api'
  location: location
  tags: tags
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource acrPullAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: acr
  name: guid(acr.id, appIdentity.id, acrPullRole)
  properties: {
    principalId: appIdentity.properties.principalId
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower(replace('st${appName}${environmentName}', '-', ''))
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource captureContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storage.name}/default/captures'
  properties: {
    publicAccess: 'None'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${suffix}'
  location: location
  tags: tags
  properties: {
    tenantId: entraTenantId
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

resource keyVaultAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, appIdentity.id, keyVaultSecretsUserRole)
  properties: {
    principalId: appIdentity.properties.principalId
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: 'psql-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: databaseAdministratorLogin
    administratorLoginPassword: databaseAdministratorPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgres
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgres
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource databaseUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-url'
  properties: {
    value: 'postgresql+psycopg://${databaseAdministratorLogin}:${databaseAdministratorPassword}@${postgres.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
  }
}

resource metOfficeSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'met-office-api-key'
  properties: {
    value: 'replace-in-key-vault'
  }
}

resource googlePlacesSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'google-places-api-key'
  properties: {
    value: 'replace-in-key-vault'
  }
}

resource anglingAiSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'anglingai-api-key'
  properties: {
    value: 'replace-in-key-vault'
  }
}

resource acaEnvironment 'Microsoft.App/managedEnvironments@2025-01-01' = {
  name: 'cae-${suffix}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource backendApp 'Microsoft.App/containerApps@2025-01-01' = {
  name: 'ca-${suffix}-api'
  location: location
  tags: union(tags, {
    customDomainPlanned: customDomainName
  })
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: acaEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: appIdentity.id
        }
      ]
      secrets: [
        {
          name: 'database-url'
          keyVaultUrl: databaseUrlSecret.properties.secretUri
          identity: appIdentity.id
        }
        {
          name: 'met-office-api-key'
          keyVaultUrl: metOfficeSecret.properties.secretUri
          identity: appIdentity.id
        }
        {
          name: 'google-places-api-key'
          keyVaultUrl: googlePlacesSecret.properties.secretUri
          identity: appIdentity.id
        }
        {
          name: 'anglingai-api-key'
          keyVaultUrl: anglingAiSecret.properties.secretUri
          identity: appIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: backendImage
          env: [
            {
              name: 'APP_ENV'
              value: 'production'
            }
            {
              name: 'AUTH_MODE'
              value: 'entra'
            }
            {
              name: 'AUTH_REQUIRED'
              value: 'true'
            }
            {
              name: 'ENTRA_TENANT_ID'
              value: entraTenantId
            }
            {
              name: 'ENTRA_AUDIENCES'
              value: '${entraAudience},${replace(entraAudience, 'api://', '')}'
            }
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
            {
              name: 'MET_OFFICE_API_KEY'
              secretRef: 'met-office-api-key'
            }
            {
              name: 'GOOGLE_PLACES_API_KEY'
              secretRef: 'google-places-api-key'
            }
            {
              name: 'ANGLINGAI_API_KEY'
              secretRef: 'anglingai-api-key'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8000
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

output resourceGroup string = resourceGroup().name
output backendAppName string = backendApp.name
output backendDefaultHostname string = backendApp.properties.configuration.ingress.fqdn
output customDomainPlanned string = customDomainName
output keyVaultName string = keyVault.name
output storageAccountName string = storage.name
output postgresServerName string = postgres.name
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
