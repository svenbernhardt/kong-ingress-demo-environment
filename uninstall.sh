#!/bin/bash
set -o errexit

k3d cluster delete -c k3d-cluster.yaml

echo "Cluster deleted"