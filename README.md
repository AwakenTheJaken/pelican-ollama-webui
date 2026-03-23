# pelican-ollama-webui

A Docker image + Pelican egg that runs **[Ollama](https://ollama.com)** (LLM inference
runtime) and **[Open WebUI](https://github.com/open-webui/open-webui)** (ChatGPT-style
chat interface) together inside a single container, ready to be imported into the
[Pelican](https://pelican.dev) game-hosting panel on a VPS.

---

## Repository contents

| File | Purpose |
|------|---------|
| `Dockerfile` | Single-stage build on Ubuntu 22.04: installs Ollama via install.sh and Open WebUI via pip3 |
| `entrypoint.sh` | Startup script – launches Ollama, waits for it, pulls the configured model, then starts Open WebUI as the foreground process |
| `healthcheck.sh` | Probes Ollama (`:11434`) and Open WebUI (`:WEBUI_PORT`) – runnable manually inside a container |
| `egg.json` | Pelican egg definition (PTDL_v2) – import this into your panel |
| `README.md` | This file |

---

## Build instructions

```bash
docker build -t ghcr.io/awakenthejaken/pelican-ollama-webui:latest .
```

The image is also built and published automatically to
`ghcr.io/awakenthejaken/pelican-ollama-webui:latest` by the GitHub Actions
workflow on every push to `main`.

---

## Run instructions

```bash
docker run -p 3000:3000 ghcr.io/awakenthejaken/pelican-ollama-webui:latest
```

To persist downloaded models and WebUI data across restarts, mount volumes:

```bash
docker run -d \
  -v ollama_data:/root/.ollama \
  -v webui_data:/app/data \
  -p 3000:3000 \
  -e MODEL=llama3 \
  -e WEBUI_SECRET_KEY=supersecret \
  ghcr.io/awakenthejaken/pelican-ollama-webui:latest
```

Open `http://localhost:3000` in your browser once the container is running.

> **GPU support** – if your VPS has an NVIDIA GPU and the NVIDIA Container Toolkit
> installed, add `--gpus all` to the `docker run` command. The image works on
> CPU-only hosts as well.

---

## Pelican usage instructions

### 1 · Import the egg into Pelican

1. In the Pelican admin panel go to **Admin → Eggs**.
2. Click **Import Egg** and upload `egg.json` (or paste its raw GitHub URL).
3. The egg named **"Ollama + Open WebUI"** will appear under the selected nest.

### 2 · Create a server

1. Go to **Admin → Servers → Create Server**.
2. Choose the **Ollama + Open WebUI** egg.
3. Allocate a port (this becomes `WEBUI_PORT` – Open WebUI will listen there).
4. Fill in the variables:
   - **Model** – e.g. `llama3`, `llama3.2`, `mistral`, `gemma3`
   - **Open WebUI Secret Key** – change from the default `changeme`
5. Install and start the server.
6. Open `http://<your-vps-ip>:<allocated-port>` in a browser to access the chat UI.

### 3 · Reinstalling

Reinstalling a Pelican server runs the installation script (which is a no-op
for this egg) and then starts the container fresh. The container is designed to
survive repeated reinstalls without entering the **Created** or **Offline** state.

---

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MODEL` | `llama3` | Model pulled automatically on startup (e.g. `llama3`, `mistral`, `gemma3`) |
| `WEBUI_PORT` | `3000` | Port Open WebUI listens on (set by Pelican allocation) |
| `WEBUI_SECRET_KEY` | `changeme` | Session signing secret – **change this** |
| `OLLAMA_HOST` | `0.0.0.0:11434` | Ollama API bind address inside the container |

---

## Architecture

```
┌─────────────────────────────────────────┐
│            Docker container             │
│                                         │
│  ┌───────────────┐   ┌───────────────┐  │
│  │    Ollama     │◄──│  Open WebUI   │  │
│  │  :11434 (API) │   │  :WEBUI_PORT  │◄─┼── browser
│  └───────────────┘   └───────────────┘  │
│          ▲                              │
│   /root/.ollama  (model storage)        │
│   /app/data      (WebUI data)           │
└─────────────────────────────────────────┘
```

Models are stored in `/root/.ollama` and WebUI data in `/app/data` inside the
container. Mount volumes at those paths to persist data across container restarts.

---

## Startup log output

Every step is logged with a UTC timestamp so you can follow progress in the Pelican
console:

```
[2026-01-01T00:00:00Z] === Pelican Ollama + Open WebUI ===
[2026-01-01T00:00:00Z] OLLAMA_HOST=0.0.0.0:11434 | WEBUI_PORT=3000 | MODEL=llama3
[2026-01-01T00:00:00Z] Starting Ollama...
[2026-01-01T00:00:00Z] Ollama started
[2026-01-01T00:00:00Z] Waiting for Ollama API...
[2026-01-01T00:00:02Z] Ollama ready
[2026-01-01T00:00:02Z] Pulling model llama3...
[2026-01-01T00:02:15Z] Model pull complete
[2026-01-01T00:02:15Z] Starting Open WebUI on 0.0.0.0:3000...
[2026-01-01T00:02:15Z] Application startup complete
```

---

## Health checks

The Docker image includes a built-in `HEALTHCHECK` that probes Open WebUI on
port 3000:

```
HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1
```

A `/healthcheck.sh` script is also included and can be run manually inside a
running container:

```bash
docker exec <container_id> /healthcheck.sh
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Container exits immediately | Entrypoint crash | Run `docker logs <id>` and look for error lines |
| Ollama does not start | Missing binary or install error | Rebuild the image; ensure outbound internet access during build |
| Model pull fails | No internet access from container | Ensure the host has outbound internet; check firewall rules |
| Health check shows `UNHEALTHY` | Service still starting | Wait for Open WebUI to finish initializing |
| Pelican shows server as Offline | Container exited | Check `docker logs` for errors; verify port allocation |

**Useful debug commands:**

```bash
# Stream live logs
docker logs -f <container_id>

# Check health status
docker inspect --format='{{.State.Health.Status}}' <container_id>

# Run health check manually
docker exec <container_id> /healthcheck.sh

# List downloaded models
docker exec <container_id> ollama list

# Open a shell inside the container
docker exec -it <container_id> bash
```

---

## Minimum recommended VPS specs

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 8 GB | 16 GB |
| Disk | 20 GB | 50 GB |
| GPU | — | NVIDIA (any VRAM ≥ 4 GB) |

> Small quantised models (e.g. `llama3.2:1b`, `gemma3:1b`) run acceptably on CPU-only
> hosts with 8 GB RAM. Larger models require more RAM and benefit greatly from a GPU.
