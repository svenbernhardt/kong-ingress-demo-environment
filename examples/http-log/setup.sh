#!/bin/bash
set -o errexit

kubectl apply -f kong-vault-environment.yaml

kubectl apply -f plugin-http-log-global.yaml