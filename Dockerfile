# pelican-ollama-webui
# Combines Ollama (LLM runtime) and Open WebUI (chat interface) in a single
# container designed to run as a Pelican (game-hosting panel) egg on a VPS.

# ── Stage 1: obtain the Ollama binary from the official image ─────────────────
# This avoids the install.sh approach, which fails in Docker build environments
# because it attempts to configure systemd services that do not exist there.
FROM ollama/ollama:latest AS ollama-source

# ── Stage 2: build the combined image ────────────────────────────────────────
FROM ubuntu:24.04

# ── Environment ──────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
# Ollama listens on all interfaces so Open WebUI can reach it via localhost
ENV OLLAMA_HOST=0.0.0.0:11434
# Default Web UI port (overridden by the Pelican egg / WEBUI_PORT variable)
ENV WEBUI_PORT=3000
# Open WebUI secret key – users should override this with a strong random value
ENV WEBUI_SECRET_KEY=changeme

# ── Ollama binary ─────────────────────────────────────────────────────────────
COPY --from=ollama-source /usr/bin/ollama /usr/local/bin/ollama

# ── System dependencies ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        python3 \
        python3-pip \
        tini \
        zstd \
    && rm -rf /var/lib/apt/lists/*

# ── Open WebUI ────────────────────────────────────────────────────────────────
RUN pip3 install --no-cache-dir open-webui --break-system-packages

# ── Startup and health-check scripts ─────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoint.sh /healthcheck.sh

# ── Exposed ports ─────────────────────────────────────────────────────────────
# 11434 – Ollama REST API
# 3000  – Open WebUI (default; override with WEBUI_PORT)
EXPOSE 11434 3000

# ── Health check ──────────────────────────────────────────────────────────────
# start-period gives both services time to initialise before the first probe.
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD /healthcheck.sh

# ── Entry point ───────────────────────────────────────────────────────────────
# tini reaps zombie processes and forwards signals correctly.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]
