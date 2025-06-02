#!/bin/bash
set -o errexit

REDIS_PASSWORD=$(kubectl get secrets -n redis redis -oyaml | yq .data.redis-password | base64 -d)

kubectl exec -it -n vault vault-0 -- vault kv put secret/redis password="${REDIS_PASSWORD}"

kubectl apply -f kong-vault.yaml

kubectl apply -f plugin-caching-advanced.yaml -n demo

kubectl annotate -n demo ingress httpbin konghq.com/plugins=proxy-cache-advanced --overwrite