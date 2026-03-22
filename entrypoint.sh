#!/bin/bash
set -e

echo "Starting Ollama..."
ollama serve &

sleep 8

echo "Pulling model..."
ollama pull "${MODEL:-llama3}"

echo "Starting Open WebUI..."
open-webui serve --host 0.0.0.0 --port 3000
