SUFFIX="9"

DEPLOYMENTNAME="acadep"-$SUFFIX
SUBSCRIPTION_ID=$(az account show --query id -o tsv) #subscriptionid
LOCATION="westeurope" # here enter the datacenter location
RG="$DEPLOYMENTNAME-rg" 


az group create --name $RG --location westeurope  
az deployment group create --resource-group $RG  --template-file testvm.bicep --parameters location=westeurope vnetName=acavnet-acadep-9  subnetName=vm  adminUsername=ivan adminPasswordOrKey=12qwasyx##34erdfcv881-2