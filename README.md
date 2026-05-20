# OpenClaw Full — Extended Docker Image

A custom Docker image based on [ghcr.io/openclaw/openclaw](https://github.com/openclaw/openclaw/pkgs/container/openclaw) with additional system utilities for server diagnostics, automation, and management.

Published on GitHub Container Registry: `ghcr.io/sers88/openclawfull`

[README на русском](README.ru.md)

---

## Included Packages

### Base (already in the standard openclaw image)

| Package | Purpose |
|---------|---------|
| `ca-certificates` | SSL/TLS certificates |
| `curl` | HTTP client |
| `git` | Version control |
| `openssl` | Cryptography, certificates |
| `procps` | `ps`, `top`, `free`, `kill` |
| `lsof` | List open files |
| `python3` | Python runtime |
| `tini` | Init system for containers |
| `less`, `file`, `tar` | Basic utilities |

### SSH & File Transfer

| Package | Purpose |
|---------|---------|
| `openssh-client` | SSH client (`ssh`, `scp`, `ssh-keygen`) |
| `rsync` | File synchronization between servers |
| `paramiko` (pip) | SSH via Python |

### Network Diagnostics

| Package | Purpose |
|---------|---------|
| `iputils-ping` | `ping` |
| `netcat-openbsd` | `nc` — port checking |
| `nmap` | Network scanner |
| `dnsutils` | `dig`, `nslookup`, `host` |
| `iproute2` | `ip`, `ss`, `tc` |
| `tcpdump` | Network traffic capture |
| `traceroute` | Route tracing |

### Data Processing

| Package | Purpose |
|---------|---------|
| `jq` | JSON parsing |
| `yq` (Go binary) | YAML/JSON/XML/CSV/TOML processing |
| `ripgrep` | `rg` — fast content search |
| `python3-pip` | Python package manager |

### System Utilities

| Package | Purpose |
|---------|---------|
| `strace` | System call tracing |
| `psmisc` | `killall`, `pstree`, `fuser` |
| `htop` | Process monitoring |
| `nano`, `vim-tiny` | Text editors |
| `unzip`, `zip` | Archives |
| `wget` | File downloads |

---

## Installation on Unraid

### Prerequisites

- Unraid 6.x+
- Docker enabled (Settings → Docker → Enable Docker: Yes)
- For private images: Unraid terminal access for `docker login`

### Step 1. Open Docker tab

In the WebGUI, go to the **Docker** tab and click **Add Container** (bottom of the page).

### Step 2. Basic settings

| Field | Value |
|-------|-------|
| **Name** | `openclaw` |
| **Repository** | `ghcr.io/sers88/openclawfull:latest` |
| **Network Type** | `Bridge` |

### Step 3. Port Mappings

| Host Port | Container Port | Protocol |
|-----------|---------------|----------|
| `18789` | `18789` | TCP |
| `18790` | `18790` | TCP |

### Step 4. Volume Mappings

| Host Path | Container Path | Access Mode |
|-----------|---------------|-------------|
| `/mnt/user/appdata/openclaw` | `/home/node/.openclaw` | Read/Write |
| `/mnt/user/appdata/openclaw/workspace` | `/home/node/.openclaw/workspace` | Read/Write |
| `/mnt/user/appdata/openclaw-auth-profile-secrets` | `/home/node/.config/openclaw` | Read/Write |

> Host paths are created automatically on first start. It is recommended to place `appdata` on a cache pool.

### Step 5. Environment Variables

Click **Add another Path, Port, Variable, Label or Device** and add the following variables:

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `HOME` | `/home/node` | Home directory |
| `OPENCLAW_HOME` | `/home/node` | OpenClaw root |
| `TERM` | `xterm-256color` | Terminal type |
| `OPENCLAW_STATE_DIR` | `/home/node/.openclaw` | State directory |
| `OPENCLAW_CONFIG_PATH` | `/home/node/.openclaw/openclaw.json` | Config file path |
| `OPENCLAW_CONFIG_DIR` | `/home/node/.openclaw` | Config directory |
| `OPENCLAW_WORKSPACE_DIR` | `/home/node/.openclaw/workspace` | Workspace directory |
| `OPENCLAW_GATEWAY_BIND` | `lan` | Bind to 0.0.0.0 (LAN access) |
| `OPENCLAW_GATEWAY_TOKEN` | *your-token* | Gateway auth token |
| `TZ` | `Europe/Moscow` | Timezone |

### Step 6. Extra Parameters

In the **Extra Parameters** field (visible in Advanced View), add:

```
--init --cap-drop=NET_ADMIN --security-opt=no-new-privileges=true
```

This enables:
- `--init` — tini as PID 1 (proper signal handling)
- `--cap-drop=NET_ADMIN` — reduced privileges (security)
- `--security-opt=no-new-privileges=true` — prevent privilege escalation

> **Important:** `NET_RAW` is **not** dropped so that `ping`, `nmap`, `tcpdump`, and `traceroute` work correctly.

### Step 7. Create the container

1. Click **Apply** / **Create**
2. Wait for the image to download (~500 MB on first pull)
3. Once finished, click **Done**

### Step 8. Enable auto-start

On the **Docker** tab, toggle **Auto-Start** to **ON** for the `openclaw` container.

---

## Verify installation

Click the container icon → **Console** and run:

```bash
# Check gateway
curl -s http://127.0.0.1:18789/healthz

# Check network tools
ping -c 2 google.com
nc -zv google.com 443
dig google.com
ip addr show

# Check data tools
echo '{"test":1}' | jq .
echo 'key: value' | yq .
echo "hello world" | rg "hello"

# Check SSH
ssh -V

# Check Python
python3 -m pip show paramiko

# Check system tools
htop --version
strace --version
```

---

## Updating the image

### On Unraid

1. Stop the container: icon → **Stop**
2. Remove the container: icon → **Remove** (select *container only*, do **not** remove the image)
3. Open the Unraid terminal and run:
   ```bash
   docker pull ghcr.io/sers88/openclawfull:latest
   ```
4. Go to the **Docker** tab → select the container from **Previous Containers** at the bottom
5. Click **Install** — settings will be restored from the saved template

### Alternative (via Unraid terminal)

```bash
docker stop openclaw
docker rm openclaw
docker pull ghcr.io/sers88/openclawfull:latest
```

Then recreate the container via WebGUI from Previous Containers.

---

## Private registry (if the image is private)

If the GHCR repository is private, run on the Unraid terminal:

```bash
docker login ghcr.io -u sers88
```

Use a GitHub Personal Access Token (PAT) with `read:packages` scope as the password.

---

## Docker Compose installation (non-Unraid)

For servers with Docker Compose:

```bash
cp .env.example .env
# Edit .env: set OPENCLAW_GATEWAY_TOKEN, TZ, etc.
docker compose up -d --build
```

Or with the pre-built image from GHCR:

```bash
docker compose up -d
```

---

## CI/CD

The image is automatically built and published via GitHub Actions:

- **Push to `main`** → build and push `latest` tag
- **Tag `v*`** → build and push versioned tag (e.g. `v1.0.0`)
- **Platforms:** `linux/amd64`, `linux/arm64`
- **Registry:** `ghcr.io/sers88/openclawfull`

---

## Links

- [OpenClaw — official project](https://github.com/openclaw/openclaw)
- [OpenClaw documentation](https://docs.openclaw.ai)
- [Base image on GHCR](https://github.com/openclaw/openclaw/pkgs/container/openclaw)
- [Unraid Docker documentation](https://docs.unraid.net/unraid-os/using-unraid-to/run-docker-containers/overview/)
