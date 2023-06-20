param location string = resourceGroup().location
var hubPrefix = '10.0.0.0/22'
var acaSpokePrefix = '10.0.4.0/22'
var vnetNewOrExisting = 'new'
var  inboundSubnet  = 'snet-inbound'
var inboundAddressPrefix  = '10.7.0.0/28'
var outboundSubnet  = 'snet-outbound'
var  outboundAddressPrefix  = '10.7.0.16/28'
var fwSubnet ='10.0.0.0/24'
var appGwFW = '10.0.1.0/24'


resource hubnet 'Microsoft.Network/virtualNetworks@2022-01-01' = if (vnetNewOrExisting == 'new') {
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
          addressPrefix: fwSubnet
        }
      }
      {
        name: 'appgw'
        properties: {
          addressPrefix: appGwFW
        }
      }
      {
        name:  inboundSubnet
        properties: {
          addressPrefix: inboundAddressPrefix
          delegations:[
            {
              name:'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName:'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: outboundSubnet
        properties: {
          addressPrefix: outboundAddressPrefix
          delegations:[
            {
              name:'Microsoft.Network.dnsResolvers'
              properties:{
                serviceName:'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource acaspoke 'Microsoft.Network/virtualNetworks@2022-01-01' = if (vnetNewOrExisting == 'new') {
  name: 'acaspoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        acaSpokePrefix
      ]
    }
    subnets: [
      {
        name: 'aca'
        properties: {
          addressPrefix: '10.0.4.0/24'
          delegations: [
            {
              name: 'Microsoft.App.testClients'
              properties: {
                serviceName: 'Microsoft.App/environments'
               
              }
            }
          ]
             }

      }
      {
        name: 'bastion'
        properties: {
          addressPrefix: '10.0.5.0/24'
        }
      }
      {
        name: 'vms'
        properties: {
          addressPrefix: '10.0.6.0/24'
       }
      }

    ]
  }
}
resource bastionsubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: 'bastion'
  parent: acaspoke
}
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'bastionip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'acabastion'
  location: location
  dependsOn: [
    acaspoke
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionsubnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}
// Peering 
resource sourceToDestinationPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${acaspoke.name}-To-${hubnet.name}'
  parent: acaspoke
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: hubnet.id
    }
  }
}

resource destinationToSourcePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name: '${hubnet.name}-To-${acaspoke.name}'
  parent: hubnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: acaspoke.id
    }
  }
}
