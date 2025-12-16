// Main Bicep deployment file for Azure Web App with Functions, Container Apps, API Management, and Entra ID authentication

@description('The environment name (e.g., dev, staging, prod)')
param environment string = 'dev'

@description('The Azure region for resources')
param location string = resourceGroup().location

@description('Unique suffix for resource names')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('The Entra ID (Azure AD) tenant ID')
param tenantId string

@description('The Entra ID (Azure AD) client ID for the web app')
param webAppClientId string

@description('The Entra ID (Azure AD) client ID for the API')
param apiClientId string

@description('Container image for the web app')
param webAppImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Container image for the function app')
param functionAppImage string = 'mcr.microsoft.com/azure-functions/dotnet:4'

// Variables
var baseName = 'webapp-${environment}-${uniqueSuffix}'
var containerAppEnvName = 'cae-${baseName}'
var containerAppName = 'ca-${baseName}'
var functionAppName = 'func-${baseName}'
var apimName = 'apim-${baseName}'
var logAnalyticsName = 'log-${baseName}'
var appInsightsName = 'ai-${baseName}'
var containerRegistryName = 'acr${replace(uniqueSuffix, '-', '')}'

// Log Analytics Workspace for monitoring
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

// Application Insights for monitoring
module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Container Registry for storing Docker images
module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    name: containerRegistryName
    location: location
  }
}

// Container Apps Environment
module containerAppsEnvironment 'modules/container-apps-environment.bicep' = {
  name: 'containerAppsEnvironment'
  params: {
    name: containerAppEnvName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// Web App (Container App with Entra ID authentication)
module webApp 'modules/container-app.bicep' = {
  name: 'webApp'
  params: {
    name: containerAppName
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerImage: webAppImage
    containerRegistryName: containerRegistry.outputs.name
    tenantId: tenantId
    clientId: webAppClientId
    appInsightsConnectionString: appInsights.outputs.connectionString
    apimGatewayUrl: apiManagement.outputs.gatewayUrl
  }
}

// Azure Function App (Container App based)
module functionApp 'modules/function-app.bicep' = {
  name: 'functionApp'
  params: {
    name: functionAppName
    location: location
    containerAppsEnvironmentId: containerAppsEnvironment.outputs.id
    containerImage: functionAppImage
    containerRegistryName: containerRegistry.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
    tenantId: tenantId
    apiClientId: apiClientId
  }
}

// API Management
module apiManagement 'modules/api-management.bicep' = {
  name: 'apiManagement'
  params: {
    name: apimName
    location: location
    appInsightsId: appInsights.outputs.id
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    tenantId: tenantId
    apiClientId: apiClientId
  }
}

// Outputs
output containerAppUrl string = webApp.outputs.fqdn
output functionAppUrl string = functionApp.outputs.fqdn
output apimGatewayUrl string = apiManagement.outputs.gatewayUrl
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
