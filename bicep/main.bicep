@description('location region')
param location string = resourceGroup().location

@description('UNIQUE DEPLOYMENT NAME.')
param deploymentName string
@description(' flag to only deploy the apps ')
param appsOnly bool = false
param debugapp bool = false

module monitoring 'monitoring.bicep' = if (!appsOnly) {
  name: 'monitoring'
  params: {
    location: location
    logAnalyticsWorkspaceName: 'logs-${deploymentName}'
    applicationInsightsName: 'appi-${deploymentName}'
  }
}

module hubspoke 'hubspoke.bicep' = if (!appsOnly) {
  name: 'hubspoke'
  params: {
    location: location
    suffix: deploymentName
  }
}
module storage 'storage.bicep' = if (!appsOnly) {
  name: 'storage'
}

module acaenv 'acaenv.bicep' = if (!appsOnly) {
  name: 'acaenv'
  params: {
    location: location
    environmentName: '${deploymentName}'
    subnetName: hubspoke.outputs.spoke.acaSubnetname
    vnetName: hubspoke.outputs.spoke.acaVirtualNetworkName
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: monitoring.outputs.logAnalyticsSharedKey
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    storageAccountName: storage.outputs.storageAccountName
  }
  dependsOn: [
    hubspoke
    monitoring
    storage
  ]
}
//todo need to get the default domain and static ip from the environment 


module apps 'apps.bicep' =  {
  name: 'applications'
  params: {
    location: location
    containerAppName: 'simpleapp2'
    environmentId: acaenv.outputs.appEnvId
    workloadProfileName: 'd4-compute'
    ipAddress: acaenv.outputs.staticIp
    zoneName: acaenv.outputs.defaultDomain
    
  }
  dependsOn: [
     acaenv
     privatednszone
  ]
}
module debapps 'debugapp.bicep' =  if (!debugapp) {
  name: 'debugapp'
  params: {
    location: location
    containerAppName: 'debugapp'
    environmentId: acaenv.outputs.appEnvId
    workloadProfileName: 'd4-compute'
    ipAddress: acaenv.outputs.staticIp
    zoneName: acaenv.outputs.defaultDomain
    
  }
  dependsOn: [
     acaenv
     privatednszone
  ]
}

module vm 'testvm.bicep' =  if (!appsOnly) {
  name: 'test'
  params: {
    location: location
    vnetName: hubspoke.outputs.spoke.acaVirtualNetworkName
    subnetName: 'vm'
    adminUsername: 'ivan'
    adminPasswordOrKey: '12qwasyx##34erdfcv881-28912q##'

  }
  dependsOn: [
    hubspoke
  ]
}
// setting up private dns zone for default domain
// https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom-internal?tabs=bash&pivots=azure-cli#deploy-with-a-private-dns
module privatednszone 'privatednszone.bicep' = if (!appsOnly)  {
  name: 'privatednszone'
  params: {
    location: location
    recordName: '*'
    ipAddress: acaenv.outputs.staticIp
    zoneName: acaenv.outputs.defaultDomain
    vnetName: hubspoke.outputs.spoke.acaVirtualNetworkName
  }
  dependsOn: [
    acaenv
    hubspoke
  ]
}

module keyvault 'keyvault.bicep' = if (!appsOnly)  {
  name: 'keyvault'
  params: {
    location: location
    keyVaultName: 'kv-${deploymentName}'

  }
}

module privateDnsResolver 'privatednsResolver.bicep' = if (!appsOnly)  {
  name: 'privateDnsResolver'
  params: {
    location: location 
     acisubnet: 'aci'
     dnsResolverName: 'adns-${deploymentName}'
      DomainName: 'example.com.'
       inboundSubnet: 'snet-inbound'
       outboundSubnet: 'snet-outbound'
       resolverVNETName: hubspoke.outputs.hub.hubVirtualNetworkName


  }
  dependsOn: [
    hubspoke
  ]
}

