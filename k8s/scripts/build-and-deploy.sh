#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
K8S_BASE="$REPO_ROOT/k8s/base"
BUILD_HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)

echo "==> Building sf-digital:${BUILD_HASH}..."
cd "$REPO_ROOT"

npm run build

docker build -t sf-digital:latest -t "sf-digital:${BUILD_HASH}" .

echo "==> Importing image into k3s containerd..."
docker save sf-digital:latest | sudo k3s ctr images import -

echo "==> Applying k8s manifests..."
sudo kubectl apply -f "$K8S_BASE/namespace.yaml"
sudo kubectl apply -f "$K8S_BASE/sf-digital-configmap.yaml"
sudo kubectl apply -f "$K8S_BASE/sf-digital-deployment.yaml"
sudo kubectl apply -f "$K8S_BASE/sf-digital-service.yaml"
sudo kubectl apply -f "$K8S_BASE/sf-digital-ingress.yaml"

echo "==> Restarting sf-digital deployment to pick up new image..."
sudo kubectl -n sf-digital rollout restart deployment/sf-digital

echo "==> Waiting for rollout..."
sudo kubectl -n sf-digital rollout status deployment/sf-digital --timeout=120s

echo "==> Deploy complete!"
echo "    Build hash: ${BUILD_HASH}"
echo "    Pods:"
sudo kubectl -n sf-digital get pods -o wide
