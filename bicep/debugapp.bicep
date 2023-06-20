
param workloadProfileName string
@description('locatioon name')
param location string  = resourceGroup().location

@description('name of app ')
param containerAppName string = 'networkdebugapp'

param image string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('App Env id')
param environmentId string

@description('A DNS')
param zoneName string = ''

@description('ipAddress')
param ipAddress string = ''



// https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2022-03-01/containerapps?pivots=deployment-language-bicep
// https://gist.github.com/kopetan-ms/1d5276120122d561a56352a05fc10543
/* resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultGroup)
}
module anotherAppCertificate 'certificate.bicep' = {
  name: 'app2certificate'
  params: {
    caEnvironmentName: environmentName
    location: location
    certificateName: app2DomainName
    certificateValue: keyVault.getSecret(app2CertificateName) 
  }
}
resource certificate 'Microsoft.App/managedEnvironments/certificates@2022-11-01-preview' = {
  parent: containerAppEnv
  location: location
  name: certificateName
  properties: {
    value: certificateValue
  }
}*/

resource debugapp 'Microsoft.App/containerapps@2023-04-01-preview' = {
  name: containerAppName
  kind: 'containerapps'
  location: location
  properties: {
    workloadProfileName: workloadProfileName
    configuration: {
      secrets: []
      registries: []
      activeRevisionsMode: 'Single'
  //    ingress: {
  //      external: true
  //      targetPort: 80
  //      customDomains: [
   //       {
    //          name: app2DomainName
     //         certificateId: '${environment.id}/certificates/${app2DomainName}'
      //        bindingType: 'SniEnabled'
      //    }
      // ]
    //  }
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: 'nicolaka/netshoot'
          
          command: ['/bin/bash']
           args: ['-c', 'while true; do ping localhost; sleep 600; done']

          resources: {
            cpu: 1
            memory: '2Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
      }
    }
    managedEnvironmentId: environmentId
  }
}
// created default record 
resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: zone
  name: containerAppName
  properties: {
    ttl: 3600
     
    aRecords: [
      {
        ipv4Address: ipAddress
      }
     
    ]
  }
}
resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
}
 // output the ip and the domain  
