# pelican-ollama-webui

A Docker image + Pelican egg that runs **[Ollama](https://ollama.com)** (LLM inference
runtime) and **[Open WebUI](https://github.com/open-webui/open-webui)** (ChatGPT-style
chat interface) together inside a single container, ready to be imported into the
[Pelican](https://pelican.dev) game-hosting panel on a VPS.

---

## Repository contents

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the combined Ollama + Open WebUI image (Ubuntu 24.04 base) |
| `entrypoint.sh` | Startup script – launches Ollama, waits for it, optionally pulls a model, then starts Open WebUI |
| `egg.json` | Pelican egg definition (PTDL_v2) – import this into your panel |
| `README.md` | This file |

---

## Quick start

### 1 · Build and push the Docker image

The image is built and published automatically to
`ghcr.io/awakenthejaken/pelican-ollama-webui:latest` by the GitHub Actions
workflow (`.github/workflows/docker-publish.yml`) on every push to `main`.
No manual steps are needed for the published image.

If you want to build a local copy, clone the repository first and run the
commands **from inside the repository directory**:

```bash
# Clone the repo and enter it
git clone https://github.com/AwakenTheJaken/pelican-ollama-webui.git
cd pelican-ollama-webui

# Replace with your own container registry / username if desired
IMAGE=ghcr.io/awakenthejaken/pelican-ollama-webui:latest

docker build -t "$IMAGE" .
docker push "$IMAGE"
```

> **GPU support** – if your VPS has an NVIDIA GPU and the NVIDIA Container Toolkit
> installed, add `--gpus all` when starting the container (or configure it in Pelican's
> Wings settings). The image works on CPU-only hosts as well.

### 2 · Import the egg into Pelican

1. In the Pelican admin panel go to **Admin → Eggs**.
2. Click **Import Egg** and upload `egg.json` (or paste its raw GitHub URL).
3. The egg named **"Ollama + Open WebUI"** will appear under the selected nest.

### 3 · Create a server

1. Go to **Admin → Servers → Create Server**.
2. Choose the **Ollama + Open WebUI** egg.
3. Allocate a port (this becomes `WEBUI_PORT` – Open WebUI will listen there).
4. Fill in the variables:
   - **Ollama Model** – e.g. `llama3.2`, `mistral`, `gemma3` (leave blank to skip auto-pull)
   - **Open WebUI Secret Key** – change from the default `changeme`
5. Install and start the server.
6. Open `http://<your-vps-ip>:<allocated-port>` in a browser to access the chat UI.

---

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WEBUI_PORT` | `8080` | Port Open WebUI listens on (set by Pelican allocation) |
| `OLLAMA_MODEL` | `llama3.2` | Model pulled automatically on first start (empty = skip) |
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
└─────────────────────────────────────────┘
```

Models are stored in `/root/.ollama` inside the container. Mount a volume or bind-mount
that path to persist models across container restarts:

```bash
docker run -d \
  -v ollama_data:/root/.ollama \
  -p 8080:8080 \
  -e OLLAMA_MODEL=llama3.2 \
  -e WEBUI_SECRET_KEY=supersecret \
  ghcr.io/awakenthejaken/pelican-ollama-webui:latest
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
