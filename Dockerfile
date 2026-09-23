# HPE HackShack - OpenCode Tutorial Environment
# OpenCode CLI: https://opencode.ai
# Uses free OpenCode Zen cloud models (no API keys, no local GPU needed)
FROM ubuntu:22.04

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
    python3 \
    python3-pip \
    vim \
    nano \
    build-essential \
    expect \
    asciinema \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && printf '#!/bin/sh\nexit 0\n' > /usr/bin/xdg-open && chmod +x /usr/bin/xdg-open

# --- Corporate proxy/TLS inspection certs (e.g. Zscaler on HPE VPN) ---
# If config/zscaler-root-ca.crt exists, add it to the trust store.
# Safe to skip for non-corporate environments.
COPY config/zscaler-root-ca.crt /usr/local/share/ca-certificates/zscaler-root-ca.crt
RUN update-ca-certificates

# --- Node.js 22 (LTS) via NodeSource ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- Install OpenCode CLI ---
RUN npm install -g opencode-ai@latest

# --- Install HPE instrospect (skill auditing) ---
# Source: https://github.hpe.com/jonathan-sparks/instrospect
# If instrospect/ is not in build context, create a stub (Lab 2D will be limited)
COPY instrospect/ /opt/instrospect/
RUN if [ -f /opt/instrospect/src/skill_review.py ] && ! grep -q "instrospect not available" /opt/instrospect/src/skill_review.py; then \
        ln -sf /opt/instrospect/src/skill_review.py /usr/local/bin/skill-review && \
        chmod +x /opt/instrospect/src/skill_review.py && \
        chmod +x /opt/instrospect/src/sandbox/bootstrap.py; \
    else \
        echo "[NOTE] instrospect stub installed -- Lab 2D will be limited"; \
    fi

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
