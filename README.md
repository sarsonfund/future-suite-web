# future-suite-web

# Future Suite

Coming soon landing page for Future Suite. Served by a minimal Node/Express app, containerized with Docker, and deployable to Kubernetes.

## Run locally

```bash
npm install
npm start
```

Open http://localhost:8080 (or the port in `PORT`).

## Deploy to Kubernetes (on the server box)

1. Clone the repo and use the **prod** branch:
   ```bash
   git clone -b prod <repo-url> future-suite && cd future-suite
   ```

2. Ensure Docker and `kubectl` are installed and `kubectl` is configured for your cluster.

3. (Optional) If the cluster pulls images from a registry, set env and push:
   ```bash
   export REGISTRY=ghcr.io/your-org   # or your registry
   export IMAGE=future-suite
   export TAG=prod
   export PUSH=1
   docker login $REGISTRY   # once
   ./deploy.sh
   ```
   Then set the same image in the deployment (the script does this when `FULL_IMAGE` differs from `future-suite:latest`).

4. For a **local** cluster (image built on the same node):
   ```bash
   ./deploy.sh
   ```
   This builds `future-suite:latest` and applies `k8s/`. The deployment uses `imagePullPolicy: IfNotPresent`.

5. Re-deploy after updates:
   ```bash
   git pull origin prod
   ./deploy.sh
   ```

## Env for deploy.sh

| Env     | Default        | Description |
|--------|----------------|-------------|
| IMAGE  | future-suite   | Image name |
| TAG    | latest        | Image tag |
| REGISTRY | (none)      | Registry host; if set, image is `$REGISTRY/$IMAGE:$TAG` and will be pushed |
| PUSH   | 0             | Set to 1 to push after build (use when cluster pulls from a registry) |

## Repo layout

- `public/index.html` – static landing page
- `server.js` – Express server
- `k8s/` – namespace, deployment, service, optional ingress
- `deploy.sh` – build image and apply k8s (run on server)
