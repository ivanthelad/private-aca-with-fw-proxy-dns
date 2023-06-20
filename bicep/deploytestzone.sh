SUFFIX="17"

DEPLOYMENTNAME="privatednszone"-$SUFFIX
SUBSCRIPTION_ID=$(az account show --query id -o tsv) #subscriptionid
LOCATION="westeurope" # here enter the datacenter location
RG="$DEPLOYMENTNAME-rg" 


az group create --name $RG --location westeurope  
az deployment group create --resource-group $RG  --template-file testvnetanddns.bicep 

