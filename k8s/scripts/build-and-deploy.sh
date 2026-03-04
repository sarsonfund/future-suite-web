#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
K8S_BASE="$REPO_ROOT/k8s/base"
BUILD_HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)

echo "==> Building future-suite:${BUILD_HASH}..."
cd "$REPO_ROOT"

npm run build

docker build -t future-suite:latest -t "future-suite:${BUILD_HASH}" .

echo "==> Importing image into k3s containerd..."
docker save future-suite:latest | sudo k3s ctr images import -

echo "==> Applying k8s manifests..."
sudo kubectl apply -f "$K8S_BASE/namespace.yaml"
sudo kubectl apply -f "$K8S_BASE/future-suite-configmap.yaml"
sudo kubectl apply -f "$K8S_BASE/future-suite-deployment.yaml"
sudo kubectl apply -f "$K8S_BASE/future-suite-service.yaml"
sudo kubectl apply -f "$K8S_BASE/future-suite-ingress.yaml"

echo "==> Restarting future-suite deployment to pick up new image..."
sudo kubectl -n future-suite rollout restart deployment/future-suite

echo "==> Waiting for rollout..."
sudo kubectl -n future-suite rollout status deployment/future-suite --timeout=120s

echo "==> Deploy complete!"
echo "    Build hash: ${BUILD_HASH}"
echo "    Pods:"
sudo kubectl -n future-suite get pods -o wide
