#!/bin/bash
set -o errexit

echo ">>> Configure HashiCorp Vault..."

VAULT_ROOT_TOKEN=$(cat ../../cluster-config/vault-cert-manager/init-keys.json | jq -r .root_token)

kubectl exec -it -n vault vault-0 -- vault auth enable -path kong-auth-mount kubernetes

K8S_IP=$(kubectl -n vault exec vault-0 -- sh -c 'echo $KUBERNETES_PORT_443_TCP_ADDR')
echo $K8S_IP
kubectl exec -it -n vault vault-0 -- vault write auth/kong-auth-mount/config kubernetes_host="https://$K8S_IP:443"

kubectl exec -it -n vault vault-0 -- vault secrets enable -path=kvv2 kv-v2

kubectl -n vault exec --stdin=true vault-0 -- vault policy write kong - <<EOF
path "kvv2/data/kong/config"            { capabilities = ["read", "list"] }
EOF

kubectl exec -it -n vault vault-0 -- vault write auth/kong-auth-mount/role/role1 bound_service_account_names=kong-gateway bound_service_account_namespaces=kong policies=kong audience=vault ttl=24h

REDIS_PASSWORD=$(kubectl get secrets -n redis redis -oyaml | yq .data.redis-password | base64 -d)

kubectl exec -it -n vault vault-0 -- vault kv put kvv2/kong/config MY_SECRET_REDIS_PASSWORD="${REDIS_PASSWORD}"
kubectl exec -it -n vault vault-0 -- vault kv patch kvv2/kong/config MY_SECRET_OIDC_CLIENT_KONG_SECRET="123345679986752654xcbvvhfd"

echo ">>> Configure HashiCorp Vault Operator, create StaticVaultSecret and configure Kong Vault..."

kubectl apply -f vault-static-auth.yaml

kubectl apply -f vault-secret.yaml

kubectl apply -f kong-vault-environment.yaml

echo ">>> Recreate Kong Gateway Pods..."

for i in $(kubectl get po -n kong -oNAME | grep kong-gateway); do kubectl delete $i -n kong; done;

echo ">>> Configure Advanced Caching Plugin..."
kubectl apply -f plugin-caching-advanced.yaml -n demo
kubectl annotate -n demo ingress httpbin konghq.com/plugins=proxy-cache-advanced --overwrite