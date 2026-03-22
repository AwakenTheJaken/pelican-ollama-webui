# pelican-ollama-webui
# Combines Ollama (LLM runtime) and Open WebUI (chat interface) in a single
# container designed to run as a Pelican (game-hosting panel) egg on a VPS.

FROM ubuntu:24.04

# ── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
# Ollama listens on all interfaces so Open WebUI can reach it via localhost
ENV OLLAMA_HOST=0.0.0.0:11434
# Default Web UI port (overridden by the Pelican egg / SERVER_PORT variable)
ENV WEBUI_PORT=8080
# Open WebUI secret key – users should override this with a strong random value
ENV WEBUI_SECRET_KEY=changeme

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ── Ollama ────────────────────────────────────────────────────────────────────
RUN curl -fsSL https://ollama.com/install.sh | sh

# ── Open WebUI ────────────────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir open-webui --break-system-packages

# ── Startup script ────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ── Exposed ports ─────────────────────────────────────────────────────────────
# 11434 – Ollama REST API
# 8080  – Open WebUI (default; override with WEBUI_PORT)
EXPOSE 11434 8080

CMD ["/entrypoint.sh"]
