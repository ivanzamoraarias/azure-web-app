// API Management module

@description('The name of the API Management service')
param name string

@description('The Azure region for the API Management service')
param location string

@description('Application Insights ID')
param appInsightsId string

@description('Application Insights instrumentation key')
param appInsightsInstrumentationKey string

@description('The Entra ID tenant ID')
param tenantId string

@description('The Entra ID API client ID')
param apiClientId string

@description('Publisher email address')
param publisherEmail string = 'admin@example.com'

@description('Publisher name')
param publisherName string = 'API Publisher'

// Azure AD login URL - using environment().authentication for cloud compatibility
var aadLoginUrl = environment().authentication.loginEndpoint

resource apiManagement 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}

// Configure Application Insights logger
resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  parent: apiManagement
  name: 'appinsights-logger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

// Configure Entra ID OAuth2 authentication
resource oauthServer 'Microsoft.ApiManagement/service/authorizationServers@2023-03-01-preview' = {
  parent: apiManagement
  name: 'entra-id-oauth'
  properties: {
    displayName: 'Entra ID OAuth2'
    description: 'Entra ID OAuth2 authorization server'
    clientRegistrationEndpoint: '${aadLoginUrl}${tenantId}'
    authorizationEndpoint: '${aadLoginUrl}${tenantId}/oauth2/v2.0/authorize'
    tokenEndpoint: '${aadLoginUrl}${tenantId}/oauth2/v2.0/token'
    clientId: apiClientId
    clientAuthenticationMethod: [
      'Body'
    ]
    authorizationMethods: [
      'GET'
      'POST'
    ]
    grantTypes: [
      'authorizationCode'
      'implicit'
    ]
    bearerTokenSendingMethods: [
      'authorizationHeader'
    ]
    defaultScope: 'api://${apiClientId}/.default'
  }
}

// API Definition for the Function App
resource api 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = {
  parent: apiManagement
  name: 'webapp-api'
  properties: {
    displayName: 'Web App API'
    description: 'API for the Azure Web App with mock data'
    subscriptionRequired: false
    path: 'api'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2: {
        authorizationServerId: oauthServer.name
      }
    }
  }
}

// API Policy for JWT validation
resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = {
  parent: api
  name: 'policy'
  properties: {
    value: '<policies><inbound><base /><validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Invalid or missing token."><openid-config url="${aadLoginUrl}${tenantId}/v2.0/.well-known/openid-configuration" /><audiences><audience>api://${apiClientId}</audience></audiences><issuers><issuer>https://sts.windows.net/${tenantId}/</issuer><issuer>${aadLoginUrl}${tenantId}/v2.0</issuer></issuers></validate-jwt></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
    format: 'xml'
  }
}

// Users API operation
resource usersOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: api
  name: 'get-users'
  properties: {
    displayName: 'Get Users'
    method: 'GET'
    urlTemplate: '/users'
    description: 'Get list of mock users'
    responses: [
      {
        statusCode: 200
        description: 'Success'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

// Products API operation
resource productsOperation 'Microsoft.ApiManagement/service/apis/operations@2023-03-01-preview' = {
  parent: api
  name: 'get-products'
  properties: {
    displayName: 'Get Products'
    method: 'GET'
    urlTemplate: '/products'
    description: 'Get list of mock products'
    responses: [
      {
        statusCode: 200
        description: 'Success'
        representations: [
          {
            contentType: 'application/json'
          }
        ]
      }
    ]
  }
}

output id string = apiManagement.id
output name string = apiManagement.name
output gatewayUrl string = apiManagement.properties.gatewayUrl
