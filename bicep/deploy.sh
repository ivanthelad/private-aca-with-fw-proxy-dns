SUFFIX="35"
DEPLOYMENTNAME="acade2"-$SUFFIX
SUBSCRIPTION_ID=$(az account show --query id -o tsv) #subscriptionid
LOCATION="westeurope" # here enter the datacenter location
RG="$DEPLOYMENTNAME-rg" 


az group create --name $RG --location westeurope  

## next step, test the firewall as a proxy 15.05.2023
## privateFirewallIP
az deployment group create --resource-group $RG  --template-file main.bicep --parameters deploymentName=$DEPLOYMENTNAME location=westeurope appsOnly=false

