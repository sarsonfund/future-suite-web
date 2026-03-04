#!/usr/bin/env bash
set -e

# Deploy Future Suite to Kubernetes.
# Run on the server box: clone (or pull) prod branch, then run this script.
#
# Requirements: Docker, kubectl (configured for your cluster).
# If using a remote registry: set REGISTRY and run `docker login` first.
#
# Env (optional):
#   IMAGE     image name (default: future-suite)
#   TAG       image tag (default: latest)
#   REGISTRY  registry host (e.g. ghcr.io/myorg). If set, image is $REGISTRY/$IMAGE:$TAG and will be pushed.
#   PUSH      set to 1 to push after build (required when cluster pulls from a registry).

IMAGE="${IMAGE:-future-suite}"
TAG="${TAG:-latest}"
REGISTRY="${REGISTRY:-}"
PUSH="${PUSH:-0}"

if [ -n "$REGISTRY" ]; then
  FULL_IMAGE="$REGISTRY/$IMAGE:$TAG"
else
  FULL_IMAGE="$IMAGE:$TAG"
fi

echo "==> Ensuring prod branch..."
git fetch origin prod 2>/dev/null || true
git checkout prod 2>/dev/null || true
git pull origin prod 2>/dev/null || true

echo "==> Build step (optional)..."
npm run build

echo "==> Building Docker image: $FULL_IMAGE"
docker build -t "$FULL_IMAGE" .

if [ "$PUSH" = "1" ] || [ -n "$REGISTRY" ]; then
  echo "==> Pushing image: $FULL_IMAGE"
  docker push "$FULL_IMAGE"
fi

echo "==> Applying Kubernetes manifests..."
kubectl apply -f k8s/

if [ "$FULL_IMAGE" != "future-suite:latest" ]; then
  echo "==> Updating deployment image to $FULL_IMAGE"
  kubectl set image deployment/future-suite future-suite="$FULL_IMAGE" -n future-suite
fi
kubectl rollout status deployment/future-suite -n future-suite --timeout=120s 2>/dev/null || true

echo "==> Done. App is deployed to namespace future-suite."
