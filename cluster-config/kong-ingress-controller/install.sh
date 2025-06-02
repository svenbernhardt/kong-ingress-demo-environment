#!/bin/bash
set -o errexit

LICENSE_FILE=license.json

kubectl create namespace kong || true

kubectl apply -f template/gateway-class.yaml
kubectl apply -f template/gateway.yaml
kubectl apply -f template/sa-token-secret.yaml

helm dependency build .
helm upgrade --install kong . --values values.yaml --namespace kong --create-namespace

if [[ -f ${LICENSE_FILE} ]]; then
echo "${LICENSE_FILE} exists. Using it!"

echo "
apiVersion: configuration.konghq.com/v1alpha1
kind: KongLicense
metadata:
  name: kong-license
rawLicenseString: '$(cat "${LICENSE_FILE}")'
" | kubectl apply -f -
fi

kubectl delete secret mysecretskv -n kong || true
kubectl create secret generic mysecretskv --from-literal=test=test -n kong

echo "Waiting for Kong Ingress Controller Pods to be ready..."
kubectl -n kong wait --for=condition=Available=true --timeout=120s deployment/kong-gateway