#!/bin/bash
set -o errexit

REDIS_PASSWORD=$(kubectl get secrets -n redis redis -oyaml | yq .data.redis-password | base64 -d)
export VAULT_ROOT_TOKEN=$(cat ../../cluster-config/vault-cert-manager/init-keys.json | jq -r .root_token)

kubectl exec -it -n vault vault-0 -- vault kv put secret/redis password="${REDIS_PASSWORD}"

envsubst < kong-vault-template.yaml > kong-vault.yaml

kubectl apply -f kong-vault.yaml

kubectl apply -f plugin-caching-advanced.yaml -n demo

kubectl annotate -n demo ingress httpbin konghq.com/plugins=proxy-cache-advanced --overwrite