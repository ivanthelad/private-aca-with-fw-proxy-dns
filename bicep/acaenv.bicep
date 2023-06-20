
param environmentName string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
param logAnalyticsSharedKey string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param storageAccountName string 
param subnetName string
param vnetName string
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}
resource acaSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: subnetName
  parent: vnet
}

// https://learn.microsoft.com/en-us/azure/container-apps/plans#consumption-dedicated
//var primaryKey = logAnalytics.listKeys().primarySharedKey
// https://learn.microsoft.com/en-us/azure/container-apps/firewall-integration
// https://learn.microsoft.com/en-us/azure/container-apps/user-defined-routes




resource environment 'Microsoft.App/managedEnvironments@2023-04-01-preview' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'd4-compute'
        workloadProfileType: 'D4'
        MinimumCount: 1
        MaximumCount: 3
      }
    ]
    daprAIConnectionString: appInsightsConnectionString
    daprAIInstrumentationKey: appInsightsInstrumentationKey
    vnetConfiguration: {
      infrastructureSubnetId: acaSubnet.id
      internal: true
    }
    zoneRedundant: false
  }
}

output appEnvId string = environment.id
output appEnvName string =environment.name
output defaultDomain string = environment.properties.defaultDomain
output staticIp string = environment.properties.staticIp
