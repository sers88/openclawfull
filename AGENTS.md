# AGENTS.md

## What this repo is

A single-purpose Docker image project. No application code — the only "source" is the `Dockerfile`, which layers extra system/Network/SSH utilities on top of `ghcr.io/openclaw/openclaw:latest`. All changes are Dockerfile or CI config changes.

## Build & run

```bash
# Build and start locally (requires Docker)
cp .env.example .env
# Edit .env: set OPENCLAW_GATEWAY_TOKEN at minimum
docker compose up -d --build
```

No package manager, no test suite, no linter, no typecheck. The only verification is whether the image builds and the container starts healthy.

## CI

- **`.github/workflows/build.yml`** — builds multi-arch (`linux/amd64`, `linux/arm64`) and pushes to `ghcr.io/sers88/openclawfull`
- Push to `main` → `latest` tag; push `v*` tag → versioned tags
- Uses GHA cache (`cache-from: type=gha`)

## Key conventions

- Base image runs as `node` user. Dockerfile switches to `root` for installs, then **must switch back** to `node` (`USER node` at the end).
- `NET_ADMIN` is dropped; `NET_RAW` is intentionally kept so `ping`, `nmap`, `tcpdump`, `traceroute` work.
- `yq` version is pinned via `ARG YQ_VERSION` — update the arg to upgrade.
- `paramiko` requires `--break-system-packages` pip flag (Debian bookworm+).
- `.dockerignore` excludes `.md`, `.env.*`, `.git`, `.github`, `LICENSE` from the build context.
- `docker-compose.yml` defines two services: `openclaw-gateway` (server, port 18789/18790) and `openclaw-cli` (interactive shell). The CLI service shares the gateway's network.

## Healthcheck

Gateway health is checked via `http://127.0.0.1:18789/healthz` (in-container Node fetch).
