source .env
az containerapp env workload-profile set -g $VNET_GROUP -n $ACA_ENV_NAME  --workload-profile-type GP1 --workload-profile-name  GP1  --min-nodes 1 --max-nodes 2

