#!/bin/bash
set -e

echo "Starting Ollama..."

ollama serve &

echo "Waiting for Ollama..."

WAIT=0
until curl -s http://localhost:11434 > /dev/null; do
    sleep 2
    WAIT=$((WAIT + 2))
    if [ "$WAIT" -ge 60 ]; then
        echo "Ollama did not start within 60 seconds, exiting"
        exit 1
    fi
done

echo "Ollama ready"

MODEL=${MODEL:-llama3}

echo "Pulling model: $MODEL"
ollama pull "$MODEL" || echo "WARNING: Could not pull model $MODEL"

echo "Starting Open WebUI..."

exec open-webui serve --host 0.0.0.0 --port 3000
