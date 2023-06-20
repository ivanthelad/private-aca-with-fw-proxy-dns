@description('suffix')
param suffix string = 'suffix${uniqueString(resourceGroup().id)}'

@description('Number of public IP addresses for the Azure Firewall')
@minValue(1)
@maxValue(100)
param numberOfPublicIPAddresses int = 1

@description('Zone numbers e.g. 1,2,3.')
param availabilityZones array = []

@description('Location for all resources.')
param location string = resourceGroup().location
var firewallName = 'hubfw-${suffix}'

var acaIpGroupName  = '${location}-aca-ipgroup-${suffix}'
var hubIpGroupName  = '${location}-hub-ipgroup-${suffix}'
var firewallPolicyName  = '${firewallName}-firewallPolicy-${suffix}'

var hubVirtualNetworkName = 'hubvnet-${suffix}'
var acaVirtualNetworkName = 'acavnet-${suffix}'


var azfwRouteTableName = 'fw-route-${suffix}'
var acaSpokePrefix = '10.10.4.0/22' 
var hubVnetAddressPrefix = '10.10.0.0/22'
var azureFirewallSubnetPrefix = '10.10.0.0/25'
var privateFirewallIP = '10.10.0.4'
var publicIPNamePrefix = 'publicIP'
var azurepublicIpname = publicIPNamePrefix
var azureFirewallSubnetName = 'AzureFirewallSubnet'

var acisubnet ='aci'
var aciAddressPrefix  = '10.10.2.0/28'
@description('name of the subnet that will be used for private resolver inbound endpoint')
var inboundSubnet  = 'snet-inbound'

@description('the inbound endpoint subnet address space')
var inboundAddressPrefix  = '10.10.1.0/28'

@description('name of the subnet that will be used for private resolver outbound endpoint')
var outboundSubnet  = 'snet-outbound'

@description('the outbound endpoint subnet address space')
var  outboundAddressPrefix  = '10.10.1.16/28'

var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', hubVirtualNetworkName, azureFirewallSubnetName)
var azureFirewallPublicIpId = resourceId('Microsoft.Network/publicIPAddresses', publicIPNamePrefix)

 // https://github.com/brwilkinson/AzureDeploymentFramework/blob/main/ADF/bicep/AKS-AKS.bicep
resource acaspoke 'Microsoft.Network/virtualNetworks@2022-01-01' =  {
  name: acaVirtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        acaSpokePrefix
      ]
    }
    // setting the firewall as a dns proxy.  
    dhcpOptions: {
      dnsServers: [
        privateFirewallIP
      ]
    }
    subnets: [
      {
        name: 'aca'
        properties: {
          addressPrefix: '10.10.4.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'Microsoft.App.testClients'
              properties: {
                serviceName: 'Microsoft.App/environments'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/join/action'
                ]
              }
            }
          ]
          routeTable: {
            id: azfwRouteTable.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.10.5.0/24'
        }
      }
      {
        name: 'vm'
        properties: {
          addressPrefix: '10.10.6.0/24'
        }
      }
    ]
  }
}
resource acabastionsubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: 'AzureBastionSubnet'
  parent: acaspoke
}
resource publicIp 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'bastionip-${suffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'acabastion-${suffix}'
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
            id: acabastionsubnet.id
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
  name: '${acaspoke.name}-To-${hubVnet.name}'
  parent: acaspoke
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource destinationToSourcePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-07-01' = {
  name:  '${hubVnet.name}-To-${acaspoke.name}'
  parent: hubVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    remoteVirtualNetwork: {
      id: acaspoke.id
    }
  }
}

var azureFirewallIpConfigurations = [for i in range(0, numberOfPublicIPAddresses): {
  name: 'IpConf${i}'
  properties: {
    subnet: ((i == 0) ? json('{"id": "${azureFirewallSubnetId}"}') : json('null'))
    publicIPAddress: {
      id: '${azureFirewallPublicIpId}${i + 1}'
    }
   
      privateIPAddress: privateFirewallIP

    
  }
}]

resource hubIpGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: hubIpGroupName
  location: location
   
  properties: {
      
    ipAddresses: [
      '10.10.0.0/24'
      '10.10.1.0/24'
      '10.10.2.0/24'
      '10.10.3.0/24'
    ]
  }
}

resource acaIpGroup 'Microsoft.Network/ipGroups@2022-01-01' = {
  name: acaIpGroupName
  location: location
  properties: {
    ipAddresses: [
      '10.10.4.0/24'
      '10.10.5.0/24'
      '10.10.6.0/24'
    ]
  }
  dependsOn: [
    hubIpGroup
  ]
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: hubVirtualNetworkName
  location: location
  tags: {
    displayName: hubVirtualNetworkName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: acisubnet
        properties: {
          addressPrefix: aciAddressPrefix
          delegations:[
            {
              name:'Microsoft.ContainerInstance.containerGroups'
              properties:{
                serviceName:'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
        
      }
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: azureFirewallSubnetPrefix
        }
      }
      {
        name: inboundSubnet
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
    enableDdosProtection: false
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2022-01-01' = [for i in range(0, numberOfPublicIPAddresses): {
  name: '${azurepublicIpname}${i + 1}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2022-01-01'= {
  name: firewallPolicyName
  location: location
  properties: {
    threatIntelMode: 'Alert'
    dnsSettings: {
      servers: []
      enableProxy: true
  }
  }
}

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  dependsOn: [
    hubIpGroup
    acaIpGroup
  ]
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'azure-global-services-nrc'
        priority: 1250
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'time-windows'
            ipProtocols: [
              'UDP'
            ]
            destinationAddresses: [
              '13.86.101.172'
            ]
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
            destinationPorts: [
              '123'
            ]
          }


          {
            ruleType: 'NetworkRule'
            name: 'aca-deps-all'
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: [
              '*'
            ]
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
            destinationPorts: [
              '*'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'aca-deps-1'
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: [
              'AzureContainerRegistry'
              'MicrosoftContainerRegistry'
              'AzureFrontDoor.FirstParty'
            ]
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
            destinationPorts: [
              '*'
            ]
          }

          {
            ruleType: 'NetworkRule'
            name: 'aca-deps-2'
            ipProtocols: [
              'TCP'
            ]
            destinationAddresses: [
              'Storage'
       
            ]
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
            destinationPorts: [
              '443'
            ]
          }


        ]
      }
    ]
  }
}
 //TODO ADD THIS POLICY https://learn.microsoft.com/en-us/azure/container-apps/networking#user-defined-routes-udr---preview

resource applicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  dependsOn: [
    networkRuleCollectionGroup
    hubIpGroup
    acaIpGroup
  ]
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'global-rule-url-arc'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'winupdate-rule-01'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
            fqdnTags: [
              'WindowsUpdate'
            ]
            terminateTLS: false
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'Global-rules-arc'
        priority: 1202
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'global-rule-01'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'www.microsoft.com'
            ]
            terminateTLS: false
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
          }

          {
            ruleType: 'ApplicationRule'
            name: 'global-rule-02'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            targetFqdns: [
              'www.microsoft.com'
            ]
            terminateTLS: false
            sourceIpGroups: [
              hubIpGroup.id
              acaIpGroup.id
            ]
          }
        ]
      }
    ]
  }
  
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
  zones: ((length(availabilityZones) == 0) ? null : availabilityZones)
  dependsOn: [
    hubVnet
    publicIpAddress
    hubIpGroup
    acaIpGroup
    networkRuleCollectionGroup
    applicationRuleCollectionGroup
  ]
  properties: {
    ipConfigurations: azureFirewallIpConfigurations
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}


resource azfwRouteTable 'Microsoft.Network/routeTables@2021-08-01' = {
  name: azfwRouteTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'AzfwDefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: privateFirewallIP
        }
      }
    ]
  }
}

output spoke object= {

 acaVirtualNetworkName:acaVirtualNetworkName
 acaSubnetname:  'aca'
}
 output hub  object = {
  hubVirtualNetworkName: hubVirtualNetworkName
   inboundSubnet :  inboundSubnet
 outboundSubnet: outboundSubnet
 }
