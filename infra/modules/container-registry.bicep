// Container Registry module

@description('The name of the Container Registry')
param name string

@description('The Azure region for the registry')
param location string

@description('The SKU for the Container Registry')
param sku string = 'Basic'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
