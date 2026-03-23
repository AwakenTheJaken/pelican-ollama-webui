# pelican-ollama-webui
# Combines Ollama (LLM runtime) and Open WebUI (chat interface) in a single
# container designed to run as a Pelican (game-hosting panel) egg on a VPS.

FROM ubuntu:22.04

# ── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
# Ollama listens on all interfaces so Open WebUI can reach it via localhost
ENV OLLAMA_HOST=0.0.0.0:11434
# Default Web UI port (overridden by the Pelican egg / WEBUI_PORT variable)
ENV WEBUI_PORT=3000
# Open WebUI secret key – users should override this with a strong random value
ENV WEBUI_SECRET_KEY=changeme
# Default model to pull on startup
ENV MODEL=llama3

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        python3 \
        python3-pip \
        jq \
    && rm -rf /var/lib/apt/lists/*

# ── Install Ollama ────────────────────────────────────────────────────────────
RUN curl -fsSL https://ollama.com/install.sh | sh

# ── Open WebUI ────────────────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir open-webui

# ── Startup script ────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ── Persistent storage ────────────────────────────────────────────────────────
VOLUME /root/.ollama
VOLUME /app/data

# ── Exposed ports ─────────────────────────────────────────────────────────────
# 3000  – Open WebUI
# 11434 – Ollama REST API
EXPOSE 3000
EXPOSE 11434

# ── Health check ──────────────────────────────────────────────────────────────
HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1

# ── Entry point ───────────────────────────────────────────────────────────────
ENTRYPOINT ["/entrypoint.sh"]
