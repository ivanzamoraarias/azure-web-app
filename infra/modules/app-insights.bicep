// Application Insights module

@description('The name of the Application Insights resource')
param name string

@description('The Azure region for the resource')
param location string

@description('The Log Analytics workspace ID to link to')
param logAnalyticsWorkspaceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output id string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
