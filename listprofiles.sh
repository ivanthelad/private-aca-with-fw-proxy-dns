source .env
az containerapp env workload-profile list -g $VNET_GROUP -n $ACA_ENV_NAME

az containerapp up -g $VNET_GROUP --target-port 80 --ingress external --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest --environment $ACA_ENV_NAME -n exthello --browse --workload-profile Consumption 