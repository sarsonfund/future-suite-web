#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
K8S_STG="$REPO_ROOT/k8s/staging"
BUILD_HASH=$(git -C "$REPO_ROOT" rev-parse --short HEAD)

echo "==> [STAGING] Building sf-digital:${BUILD_HASH}..."
cd "$REPO_ROOT"

npm run build

docker build -t sf-digital:latest -t "sf-digital:${BUILD_HASH}" .

echo "==> [STAGING] Importing image into k3s containerd..."
docker save sf-digital:latest | sudo k3s ctr images import -

echo "==> [STAGING] Applying k8s manifests..."
sudo kubectl apply -f "$K8S_STG/namespace.yaml"
sudo kubectl apply -f "$K8S_STG/sf-digital-configmap.yaml"
sudo kubectl apply -f "$K8S_STG/sf-digital-deployment.yaml"
sudo kubectl apply -f "$K8S_STG/sf-digital-service.yaml"
sudo kubectl apply -f "$K8S_STG/sf-digital-ingress.yaml"

echo "==> [STAGING] Restarting sf-digital deployment to pick up new image..."
sudo kubectl -n sf-digital-qa rollout restart deployment/sf-digital

echo "==> [STAGING] Waiting for rollout..."
sudo kubectl -n sf-digital-qa rollout status deployment/sf-digital --timeout=120s

echo "==> [STAGING] Deploy complete!"
echo "    Build hash: ${BUILD_HASH}"
echo "    Pods:"
sudo kubectl -n sf-digital-qa get pods -o wide
