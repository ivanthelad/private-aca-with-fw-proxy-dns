param location string = resourceGroup().location
var hubPrefix = '10.0.0.0/22'

param zoneName string = '${uniqueString(resourceGroup().id)}.azurequickstart.org'

var vnetNewOrExisting = 'new'
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = if (vnetNewOrExisting == 'new') {
  name: 'hubnetwork'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'appgw'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}
resource acavnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'acavnetlink'
  location: location
  parent: zone
 
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
      
    }
  }
}
resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
 
}
