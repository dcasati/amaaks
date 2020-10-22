#!/bin/bash
set -x
# az login --identity

# az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID
# az login --identity -u /subscriptions/<subscriptionId>/resourcegroups/myRG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID
az login --identity -u  "/subscriptions/b4b07aea-0ece-45e6-ab84-4aa23106a47d/resourceGroups/MC_amaaks-test-template_amaaks-cluster_eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/amaaks-cluster-agentpool"

if [ "$#" -ne 0 ]
  then 
    echo "Converting kubeconfig..."  
    echo $1 | base64 --decode > kube.config
    echo "Converted kubeconfig."
  else 
    echo "Getting kubeconfig using az get-creadentials..."
    az aks get-credentials --resource-group amaaks-test-template --name amaaks --admin --file kube.config
    echo "Completed kubeconfig"
fi

cat <<EOF | kubectl apply  --kubeconfig=kube.config  -f -
apiVersion: v1
kind: Secret
metadata:
  name: registry-ca
  namespace: kube-system
type: Opaque
data:
  registry-ca: $(cat ./harbor/ca.crt | base64 -w 0 | tr -d '\n')
EOF

kubectl apply -f aks-harbor-ca-daemonset.yaml  --kubeconfig=kube.config 
kubectl create secret docker-registry amaaksregcred --docker-server=amaaks --docker-username=admin --docker-password=Harbor12345 --docker-email=someguy@code4clouds.com  --kubeconfig=kube.config 

# Deploy containers
kubectl apply -f kanary-deployment.yaml  --kubeconfig=kube.config 
kubectl apply -f kanary-service.yaml  --kubeconfig=kube.config 
