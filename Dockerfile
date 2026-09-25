# HPE HackShack - OpenCode Tutorial Environment
# OpenCode CLI: https://opencode.ai
# Uses free OpenCode Zen cloud models (no API keys, no local GPU needed)
FROM python:3.12-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive
# Bun/OpenCode needs explicit cert path for TLS on Ubuntu
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# --- System dependencies ---
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    ca-certificates \
    vim \
    nano \
    build-essential \
    expect \
    asciinema \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && printf '#!/bin/sh\nexit 0\n' > /usr/bin/xdg-open && chmod +x /usr/bin/xdg-open

# --- Node.js 22 (LTS) via NodeSource ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- Install OpenCode CLI ---
RUN npm install -g opencode-ai@latest

# --- Install NVIDIA SkillSpector (static skill security scanning) ---
ARG SKILLSPECTOR_REF=main
RUN pip install --no-cache-dir "git+https://github.com/NVIDIA/SkillSpector.git@${SKILLSPECTOR_REF}"

# --- Configure OpenCode ---
RUN mkdir -p /root/labs/.opencode/skills && \
    mkdir -p /root/.opencode/skills && \
    mkdir -p /root/.config/opencode && \
    mkdir -p /root/recordings

COPY config/opencode.json /root/.config/opencode/config.json
COPY config/INSTRUCTIONS.md /root/labs/INSTRUCTIONS.md

# --- Copy tutorial materials and tests ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY labs/ /root/labs/
COPY tests/ /root/tests/
RUN chmod +x /root/tests/*.sh

# Initialize labs as a git repo so OpenCode recognizes it as a project
RUN cd /root/labs && \
    git config --global user.email "student@hackshack.local" && \
    git config --global user.name "HackShack Student" && \
    git init && git add -A && git commit -m "Initial lab content" --quiet

WORKDIR /root/labs

# OpenCode web UI
EXPOSE 5178

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
