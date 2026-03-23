FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    python3 \
    python3-pip \
    jq \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install Open WebUI
RUN pip3 install open-webui --break-system-packages

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME /root/.ollama
VOLUME /app/data

EXPOSE 3000
EXPOSE 11434

HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
