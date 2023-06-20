source .env
az containerapp create -g $VNET_GROUP -n  "simpleapp2" --target-port 80 --ingress external --image $IMAGE --environment $ACA_ENV_NAME  --workload-profile Consumption-1 --min-replicas 1 --max-replicas 30 --cpu 1 --memory 2Gi 