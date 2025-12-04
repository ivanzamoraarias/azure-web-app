// Azure Function App module (running as Container App)

@description('The name of the Function App')
param name string

@description('The Azure region for the function app')
param location string

@description('The Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('The container image to deploy')
param containerImage string

@description('The Container Registry name')
param containerRegistryName string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('The Entra ID tenant ID')
param tenantId string

@description('The Entra ID API client ID')
param apiClientId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource functionApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'function'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: appInsightsConnectionString
            }
            {
              name: 'AzureWebJobsStorage'
              value: 'UseDevelopmentStorage=true'
            }
            {
              name: 'FUNCTIONS_WORKER_RUNTIME'
              value: 'node'
            }
            {
              name: 'AZURE_TENANT_ID'
              value: tenantId
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: apiClientId
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

// Configure Entra ID authentication for the Function App
resource authConfig 'Microsoft.App/containerApps/authConfigs@2023-05-01' = {
  parent: functionApp
  name: 'current'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: apiClientId
          openIdIssuer: 'https://sts.windows.net/${tenantId}/v2.0'
        }
        validation: {
          allowedAudiences: [
            'api://${apiClientId}'
          ]
        }
      }
    }
  }
}

output id string = functionApp.id
output name string = functionApp.name
output fqdn string = functionApp.properties.configuration.ingress.fqdn
