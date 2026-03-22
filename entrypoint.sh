#!/bin/bash
set -e

echo "==> Starting Ollama..."
ollama serve &
OLLAMA_PID=$!
# Propagate termination to Ollama when this script exits
trap 'kill "$OLLAMA_PID" 2>/dev/null; wait "$OLLAMA_PID" 2>/dev/null' EXIT TERM INT

echo "==> Waiting for Ollama API to be ready..."
until curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; do
    sleep 1
done
echo "==> Ollama is ready."

# Pull the requested model if one is specified and it isn't already present
if [ -n "${OLLAMA_MODEL}" ]; then
    echo "==> Pulling model: ${OLLAMA_MODEL}"
    ollama pull "${OLLAMA_MODEL}"
fi

echo "==> Starting Open WebUI on 0.0.0.0:${WEBUI_PORT:-8080}..."
OLLAMA_BASE_URL=http://localhost:11434 \
    exec open-webui serve \
        --host 0.0.0.0 \
        --port "${WEBUI_PORT:-8080}"
