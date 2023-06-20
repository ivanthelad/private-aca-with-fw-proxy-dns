@description('The name of the DNS zone to be created.  Must have at least 2 segments, e.g. hostname.org')
param zoneName string = '${uniqueString(resourceGroup().id)}.azurequickstart.org'
@description('The name of the DNS record to be created.  The name is relative to the zone, not the FQDN.')
param recordName string = 'www'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('vnet name')
param vnetName string
@description('ip address for zone ')
param ipAddress string
resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
 
}
// https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom-internal?tabs=bash&pivots=azure-cli#deploy-with-a-private-dns

resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: zone
  name: recordName
  properties: {
    ttl: 3600
     
    aRecords: [
      {
        ipv4Address: ipAddress
      }
     
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
}

resource acavnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'acavnetlink'
  location: 'global'
  parent: zone
 
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
      
    }
  }
}
