#!/bin/bash
set -o errexit

k3d cluster create -c k3d-cluster.yaml

echo ">>> Cluster created."

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

HOME_DIR=$(pwd)

echo ">>> Installing HashiCorp Vault and Cert-manager..."
cd ${HOME_DIR}/cluster-config/vault-cert-manager
bash install.sh

echo ">>> Installing Redis..."
cd ${HOME_DIR}/cluster-config/redis
bash install.sh

echo ">>> Installing Kong Ingress Controller..."
cd ${HOME_DIR}/cluster-config/kong-ingress-controller
bash install.sh

cd ${HOME_DIR}
echo ">>> Installing example service..."
kubectl apply -f demo-apps/httpbin.yaml
kubectl apply -f ingress-definitions/ingress-httpbin.yaml

echo ">>> Installing HashiCorp Vault Operator..."
helm upgrade --install vault-secrets-operator ./cluster-config/vault-secrets-operator -n vault-secrets-operator-system --create-namespace --wait

