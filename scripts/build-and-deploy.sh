#!/bin/bash

# Important: only run this script from the root of the repository.

set -euo pipefail

wait_for_k8s_resource() {
  local resource=$1
  local name=$2
  local namespace=$3

  for i in {1..15}; do
    if $(kubectl get $resource -n $namespace $name > /dev/null 2>&1); then
      return
    fi
    sleep 1
  done
  
  exit 1
}

echo -e "\n### BUILDING CUSTOM ZEEK IMAGE"
docker build -t zeek-with-extras:0.0.1 zeek/

echo -e "\n### CREATING K3D CLUSTER"
CLUSTER_NAME="zeek"
k3d cluster create $CLUSTER_NAME -p "80:80@loadbalancer" -p "443:443@loadbalancer"
k3d image import zeek-with-extras:0.0.1 -c $CLUSTER_NAME

echo -e "\n### DEPLOYING GRAFANA"
kubectl apply -f grafana/grafana.yaml

echo -e "\n### DEPLOYING LOKI"
kubectl apply -f loki/loki.yaml

echo -e "\n### DEPLOYING ZEEK"
kubectl apply -f zeek/fluent-bit-config.yaml
kubectl apply -f zeek/zeek.yaml

echo -e "\nWaiting for Grafana secret to exist..."
wait_for_k8s_resource secret grafana grafana

echo -e "\n### DEPLOYMENT COMPLETE!"

echo "################################################"
echo "###              CLUSTER DETAILS             ###"
echo "################################################"
echo ""
echo "ZEEK WEB ENDPOINT: zeek.k3d.local"
echo ""
echo "GRAFANA DASHBOARD: grafana.k3d.local"
echo "Username: admin"
echo "Password: $(kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)"
echo ""
echo "### IMPORTANT! ###"
echo "DNS records should be added to /etc/hosts or similar to easily access cluster services"
echo "192.168.97.2    grafana.k3d.local"
echo "192.168.97.2    zeek.k3d.local"