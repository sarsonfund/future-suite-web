#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
K8S_STG="$REPO_ROOT/k8s/staging"
BUILD_HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)

echo "==> [STAGING] Building future-suite:${BUILD_HASH}..."
cd "$REPO_ROOT"

npm run build

docker build -t future-suite:latest -t "future-suite:${BUILD_HASH}" .

echo "==> [STAGING] Importing image into k3s containerd..."
docker save future-suite:latest | sudo k3s ctr images import -

echo "==> [STAGING] Applying k8s manifests..."
sudo kubectl apply -f "$K8S_STG/namespace.yaml"
sudo kubectl apply -f "$K8S_STG/future-suite-configmap.yaml"
sudo kubectl apply -f "$K8S_STG/future-suite-deployment.yaml"
sudo kubectl apply -f "$K8S_STG/future-suite-service.yaml"
sudo kubectl apply -f "$K8S_STG/future-suite-ingress.yaml"

echo "==> [STAGING] Restarting future-suite deployment to pick up new image..."
sudo kubectl -n future-suite-qa rollout restart deployment/future-suite

echo "==> [STAGING] Waiting for rollout..."
sudo kubectl -n future-suite-qa rollout status deployment/future-suite --timeout=120s

echo "==> [STAGING] Deploy complete!"
echo "    Build hash: ${BUILD_HASH}"
echo "    Pods:"
sudo kubectl -n future-suite-qa get pods -o wide
