using '../bicep/main.bicep'

param location = 'uksouth'
param appName = 'carpcraft'
param environmentName = 'prod'
param entraTenantId = '67f8be6c-07da-4a7c-bb0a-d6bcb38cd6da'
param entraAudience = 'api://9f0ac07a-2cce-4e4b-b74b-41264c6594e3'
param backendImage = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param customDomainName = 'carpcraft.diiac.io'
param databaseName = 'carpcraft'
param databaseAdministratorLogin = 'carpcraftadmin'
param databaseAdministratorPassword = readEnvironmentVariable('CARPCRAFT_POSTGRES_ADMIN_PASSWORD')
