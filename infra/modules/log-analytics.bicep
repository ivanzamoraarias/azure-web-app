// Log Analytics Workspace module

@description('The name of the Log Analytics workspace')
param name string

@description('The Azure region for the workspace')
param location string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output id string = logAnalyticsWorkspace.id
output customerId string = logAnalyticsWorkspace.properties.customerId
output primarySharedKey string = logAnalyticsWorkspace.listKeys().primarySharedKey
