#!/bin/bash
set -o errexit

helm dependency build .
helm upgrade --install redis . --values values.yaml --namespace redis --create-namespace