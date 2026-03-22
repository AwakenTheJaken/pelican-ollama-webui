# pelican-ollama-webui
# Combines Ollama (LLM runtime) and Open WebUI (chat interface) in a single
# container designed to run as a Pelican (game-hosting panel) egg on a VPS.

FROM ubuntu:22.04

# ── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
# Ollama listens on all interfaces so Open WebUI can reach it via localhost
ENV OLLAMA_HOST=0.0.0.0:11434

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        python3 \
        python3-pip \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ── Ollama ────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://ollama.com/install.sh | sh

# ── Open WebUI ────────────────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir open-webui

# ── Startup script ────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ── Exposed ports ─────────────────────────────────────────────────────────────
# 11434 – Ollama REST API
# 3000  – Open WebUI
EXPOSE 11434 3000

ENTRYPOINT ["/entrypoint.sh"]
