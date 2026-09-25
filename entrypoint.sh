#!/bin/bash
set -e

echo "=========================================="
echo "  HPE HackShack - OpenCode Tutorial Lab"
echo "  https://opencode.ai"
echo "=========================================="
echo ""

# Substitute environment variables in opencode.json (OpenCode doesn't resolve env vars in config)
if [ -n "${GITHUB_TOKEN}" ]; then
    sed -i "s|\${GITHUB_TOKEN}|${GITHUB_TOKEN}|g" /root/labs/opencode.json
    echo "[OK] GITHUB_TOKEN injected into opencode.json"
else
    echo "[INFO] No GITHUB_TOKEN set -- using Zen free models only"
fi

# Start tutorial docs server (rendered markdown viewer)
DOCS_PORT="${DOCS_PORT:-8080}"
echo "[*] Starting tutorial docs server on port ${DOCS_PORT}..."
python3 /root/labs/docs-server.py > /tmp/docs-server.log 2>&1 &

# Start OpenCode web UI
OPENCODE_PORT="${OPENCODE_PORT:-5178}"
echo "[*] Starting OpenCode web UI on port ${OPENCODE_PORT}..."
OPENCODE_EXPERIMENTAL_HOT_RELOAD=true BROWSER=none opencode web --port "${OPENCODE_PORT}" --hostname 0.0.0.0 > /tmp/opencode-webui.log 2>&1 &
WEBUI_PID=$!

# Wait for web UI to be ready
WEBUI_READY=false
for i in $(seq 1 60); do
    if curl -s "http://localhost:${OPENCODE_PORT}" > /dev/null 2>&1; then
        WEBUI_READY=true
        break
    fi
    sleep 1
done

if [ "$WEBUI_READY" = true ]; then
    echo "[OK] OpenCode web UI running on port ${OPENCODE_PORT}"
else
    echo "[WARN] OpenCode web UI may still be starting (check /tmp/opencode-webui.log)"
fi

echo ""
echo "=========================================="
echo "  Environment Ready!"
echo ""
echo "  Model: mimo-v2.5-free (Zen Free, no API key needed)"
echo ""
echo "  Workspace:  ~/labs"
echo "  Tutorial:   http://localhost:${DOCS_PORT}  (OpenCode + formatted lab docs)"
echo "  OpenCode:   http://localhost:${OPENCODE_PORT}  (standalone)"
echo "  CLI Mode:   opencode"
echo ""
echo "  Labs:"
echo "    lab-01: Getting Started with OpenCode"
echo "    lab-02: Building Skills (creator, docs, SkillSpector)"
echo "    lab-03: Building an Agent Workflow"
echo "    lab-04: Ingesting Community Skills"
echo "    lab-05: Discovering and Using a Community Skill"
echo ""
echo "  Validate: bash ~/tests/validate-env.sh"
echo "=========================================="
echo ""

# Execute the CMD (defaults to bash)
exec "$@"
