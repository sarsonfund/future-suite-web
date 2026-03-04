# future-suite-web

# Future Suite

Landing page for Future Suite. Served by a minimal Node/Express app, containerized with Docker, and deployable to Kubernetes via the Manifest Network infrastructure playbook (k3s, Traefik, ucn/dcn).

## Run locally (DEV)

```bash
npm install
cp .env.example .env   # optional — dev defaults are used if .env is missing
npm start
```

Open http://localhost:8080 (or the port in `PORT`). With `.env` (or no env), the app shows **Future Suite (DEV)** and uses identifier `future-suite-dev`. Edit `.env` to change `APP_DISPLAY_NAME`, `APP_IDENTIFIER`, or `PORT`. Prod and QA set these via k8s ConfigMap.

## Deploy (playbook: ucn / dcn)

Deployment follows the pattern in `manifest-internal-docs/infrastructure/infrastructure-playbook.md`. Images are built on the server and imported into k3s (no registry).

### Server setup (once per box)

1. Clone the repo and check out the branch for that environment:
   - **Production:** `git clone <repo-url> future-suite-web && cd future-suite-web && git checkout prod`
   - **Staging:** same, then `git checkout qa`
2. Symlink `.deploy.env` so ucn/dcn find the right commands:
   - **Production:** `ln -sf k8s/base/.deploy.env .deploy.env`
   - **Staging:** `ln -sf k8s/staging/.deploy.env .deploy.env`
3. Ensure **ucn** and **dcn** are installed at `/usr/local/bin/` (see playbook § 14).
4. Ensure k3s, Docker, and kubectl are installed; user in `docker` group; passwordless sudo for kubectl if required.

### Deploy workflow

From the repo root on the server:

```bash
ucn          # Pull latest (prod → git pull origin prod, staging → git pull origin qa)
dcn          # Build image, import into k3s, apply manifests, rollout (with confirmation)
```

- **Production:** `ucn` runs `git pull origin prod`, `dcn` runs `k8s/scripts/build-and-deploy.sh` (namespace `future-suite`, host `www.futuresuite.ai`).
- **Staging:** `ucn` runs `git pull origin qa`, `dcn` runs `k8s/scripts/build-and-deploy-stg.sh` (namespace `future-suite-qa`, host `www-stg.futuresuite.ai`). Staging displays "Future Suite (QA)" and uses identifier `future-suite-qa`.

### Out of scope (you do)

- Create **prod** and **qa** branches and push to GitHub.
- Add Cloudflare A records: `www.futuresuite.ai` (prod), `www-stg.futuresuite.ai` (staging), proxied to the server IP.
- Install ucn/dcn on each server if not already present.

## Repo layout

- `public/index.html` – static landing page
- `server.js` – Express server
- `k8s/base/` – production manifests and `.deploy.env`
- `k8s/staging/` – staging manifests and `.deploy.env`
- `k8s/scripts/` – `build-and-deploy.sh`, `build-and-deploy-stg.sh`
