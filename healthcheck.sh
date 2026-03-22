#!/bin/bash
# healthcheck.sh – used by the Docker HEALTHCHECK instruction and can be run
# manually to verify that both services inside the container are responsive.
#
# Exit codes:
#   0 – both Ollama and Open WebUI are healthy
#   1 – one or both services are not responding

OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
WEBUI_PORT="${WEBUI_PORT:-3000}"

# Normalize OLLAMA_HOST to extract just the port (handles "addr:port" format).
OLLAMA_PORT="${OLLAMA_HOST##*:}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"

# ── Check Ollama ──────────────────────────────────────────────────────────────
if ! curl -sf "http://localhost:${OLLAMA_PORT}/api/tags" > /dev/null 2>&1; then
    echo "UNHEALTHY: Ollama API (port ${OLLAMA_PORT}) is not responding" >&2
    exit 1
fi

# ── Check Open WebUI ─────────────────────────────────────────────────────────
if ! curl -sf "http://localhost:${WEBUI_PORT}/health" > /dev/null 2>&1; then
    echo "UNHEALTHY: Open WebUI (port ${WEBUI_PORT}) is not responding" >&2
    exit 1
fi

exit 0
