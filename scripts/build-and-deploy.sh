#!/bin/bash

# Important: only run this script from the root of the repository.

set -euo pipefail

echo ""
echo "### BUILDING CUSTOM ZEEK IMAGE"
docker build -t zeek-with-extras:0.0.1 zeek/

echo ""
echo "### CREATING K3D CLUSTER"
CLUSTER_NAME="zeek"
k3d cluster create $CLUSTER_NAME -p "80:80@loadbalancer" -p "443:443@loadbalancer"
k3d image import zeek-with-extras:0.0.1 -c $CLUSTER_NAME

echo ""
echo "### DEPLOYING ZEEK"
kubectl apply -f zeek/fluent-bit-config.yaml
kubectl apply -f zeek/zeek.yaml

echo ""
echo "### DONE!"