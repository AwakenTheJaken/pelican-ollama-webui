#!/bin/bash
# entrypoint.sh – starts Ollama and Open WebUI inside the container.
# Designed for the Pelican egg; streams diagnostic output to the panel console.
set -euo pipefail

# ── Logging helpers ───────────────────────────────────────────────────────────
log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }
die() { log "FATAL: $*" >&2; exit 1; }

# ── Environment defaults ──────────────────────────────────────────────────────
WEBUI_PORT="${WEBUI_PORT:-3000}"
OLLAMA_MODEL="${OLLAMA_MODEL:-}"
WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-changeme}"
OLLAMA_HOST="${OLLAMA_HOST:-0.0.0.0:11434}"
MAX_WAIT=60

# ── Startup banner ────────────────────────────────────────────────────────────
log "=== Pelican Ollama + Open WebUI ==="
log "OLLAMA_HOST=${OLLAMA_HOST} | WEBUI_PORT=${WEBUI_PORT} | MODEL=${OLLAMA_MODEL:-<none>}"

# ── Pre-flight checks ─────────────────────────────────────────────────────────
command -v ollama     > /dev/null 2>&1 || die "ollama binary not found in PATH"
command -v open-webui > /dev/null 2>&1 || die "open-webui command not found"
command -v curl       > /dev/null 2>&1 || die "curl not found in PATH"

# ── Start Ollama ──────────────────────────────────────────────────────────────
log "Starting Ollama..."
OLLAMA_HOST="${OLLAMA_HOST}" ollama serve &
OLLAMA_PID=$!
log "Ollama started (PID=${OLLAMA_PID})"

# ── Signal handler: clean shutdown ────────────────────────────────────────────
cleanup() {
    log "Shutdown signal received – stopping services..."
    kill "${WEBUI_PID:-}" 2>/dev/null || true
    kill "${OLLAMA_PID}"  2>/dev/null || true
    wait 2>/dev/null || true
    log "Shutdown complete."
}
trap cleanup EXIT INT TERM

# ── Wait for Ollama API ───────────────────────────────────────────────────────
log "Checking Ollama health..."
OLLAMA_READY=0
for i in $(seq 1 ${MAX_WAIT}); do
    if curl -sf "http://localhost:11434/api/tags" > /dev/null 2>&1; then
        log "Ollama ready (after ${i}s)"
        OLLAMA_READY=1
        break
    fi
    kill -0 "${OLLAMA_PID}" 2>/dev/null || die "Ollama process exited unexpectedly (waited ${i}s)"
    sleep 1
done
[ "${OLLAMA_READY}" -eq 1 ] || die "Ollama did not respond within ${MAX_WAIT}s"

# ── Model auto-pull ───────────────────────────────────────────────────────────
if [ -n "${OLLAMA_MODEL}" ]; then
    log "Pulling model ${OLLAMA_MODEL}..."
    if ollama pull "${OLLAMA_MODEL}"; then
        log "Model ready: ${OLLAMA_MODEL}"
    else
        log "WARNING: Could not pull ${OLLAMA_MODEL} – container will start without it"
    fi
else
    log "No model specified – skipping auto-pull."
fi

# ── Start Open WebUI ──────────────────────────────────────────────────────────
log "Starting Open WebUI on 0.0.0.0:${WEBUI_PORT}..."
OLLAMA_BASE_URL="http://localhost:11434" \
WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY}" \
    open-webui serve --host 0.0.0.0 --port "${WEBUI_PORT}" &
WEBUI_PID=$!
log "Open WebUI started (PID=${WEBUI_PID})"

# ── Wait for Open WebUI ───────────────────────────────────────────────────────
log "Waiting for Open WebUI to be ready..."
WEBUI_READY=0
for i in $(seq 1 ${MAX_WAIT}); do
    if curl -sf "http://localhost:${WEBUI_PORT}/health" > /dev/null 2>&1; then
        log "Open WebUI running on port ${WEBUI_PORT}"
        WEBUI_READY=1
        break
    fi
    kill -0 "${WEBUI_PID}" 2>/dev/null || die "Open WebUI process exited unexpectedly (waited ${i}s)"
    sleep 1
done
if [ "${WEBUI_READY}" -eq 0 ]; then
    log "WARNING: Open WebUI health check timed out after ${MAX_WAIT}s – service may still be initializing"
fi

# ── Ready ─────────────────────────────────────────────────────────────────────
log "Application startup complete"

# Keep the container alive; exit if either service crashes.
wait
