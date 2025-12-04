// Container App module for the Web App with Entra ID authentication

@description('The name of the Container App')
param name string

@description('The Azure region for the container app')
param location string

@description('The Container Apps Environment ID')
param containerAppsEnvironmentId string

@description('The container image to deploy')
param containerImage string

@description('The Container Registry name')
param containerRegistryName string

@description('The Entra ID tenant ID')
param tenantId string

@description('The Entra ID client ID')
param clientId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('API Management gateway URL')
param apimGatewayUrl string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
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
          name: 'webapp'
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
              name: 'AZURE_TENANT_ID'
              value: tenantId
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: clientId
            }
            {
              name: 'API_BASE_URL'
              value: apimGatewayUrl
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// Configure Entra ID authentication for the Container App
resource authConfig 'Microsoft.App/containerApps/authConfigs@2023-05-01' = {
  parent: containerApp
  name: 'current'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: clientId
          openIdIssuer: 'https://sts.windows.net/${tenantId}/v2.0'
        }
        validation: {
          allowedAudiences: [
            'api://${clientId}'
          ]
        }
      }
    }
    login: {
      preserveUrlFragmentsForLogins: false
    }
  }
}

output id string = containerApp.id
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
