#!/bin/bash
# entrypoint.sh – starts Ollama and Open WebUI inside the container.
# Designed for the Pelican egg; streams diagnostic output to the panel console.
set -e

# ── Logging helpers ───────────────────────────────────────────────────────────
log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

# ── Environment defaults ──────────────────────────────────────────────────────
MODEL="${MODEL:-llama3}"
WEBUI_PORT="${WEBUI_PORT:-3000}"
WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-changeme}"
OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"

# ── Startup banner ────────────────────────────────────────────────────────────
log "=== Pelican Ollama + Open WebUI ==="
log "OLLAMA_HOST=${OLLAMA_HOST} | WEBUI_PORT=${WEBUI_PORT} | MODEL=${MODEL}"

# ── Start Ollama ──────────────────────────────────────────────────────────────
log "Starting Ollama..."
OLLAMA_HOST="${OLLAMA_HOST}" ollama serve &
log "Ollama started"

# ── Wait for Ollama API ───────────────────────────────────────────────────────
log "Waiting for Ollama API..."
until curl -s http://localhost:11434; do sleep 2; done
log "Ollama ready"

# ── Model auto-pull ───────────────────────────────────────────────────────────
log "Pulling model ${MODEL}..."
ollama pull ${MODEL:-llama3} || true
log "Model pull complete"

# ── Start Open WebUI (foreground) ─────────────────────────────────────────────
log "Starting Open WebUI on 0.0.0.0:${WEBUI_PORT}..."
log "Application startup complete"
export OLLAMA_BASE_URL="http://localhost:11434"
export WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY}"
exec open-webui serve --host 0.0.0.0 --port "${WEBUI_PORT}"
