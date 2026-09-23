#!/usr/bin/env bash
# record-cli.sh — Host-side orchestrator for CLI screen recording
#
# Runs the full CLI lab flow inside the container via docker exec,
# captured by asciinema as an asciicast (.cast) file.
#
# Usage:
#   ./record-cli.sh                  # record all labs
#   ./record-cli.sh --lab 1          # record Lab 1 only
#
# Output: recordings/hackshack-cli-<timestamp>.cast
#
# Prerequisites: container must be running (make up)

set -euo pipefail

CONTAINER="hackshack-lab"
RECORDINGS_DIR="$(cd "$(dirname "$0")" && pwd)/recordings"
TIMESTAMP="$(date -u +%Y-%m-%dT%H-%M-%S)"
CAST_FILE="${RECORDINGS_DIR}/hackshack-cli-${TIMESTAMP}.cast"

# Parse args
LAB_ONLY=""
for arg in "$@"; do
  if [[ "$arg" == "--lab" ]]; then shift; LAB_ONLY="$1"; shift; continue; fi
done

mkdir -p "$RECORDINGS_DIR"

echo ""
echo "[*] HackShack CLI Recording"
echo "    Container: ${CONTAINER}"
echo "    Lab: ${LAB_ONLY:-all}"
echo "    Output: ${CAST_FILE}"
echo ""

# Restart container for clean state
echo "[*] Restarting container for clean environment..."
docker compose restart >/dev/null 2>&1 || true
echo "[*] Waiting for services..."
for i in $(seq 1 30); do
  docker exec "$CONTAINER" curl -sf http://localhost:5178 >/dev/null 2>&1 && break
  sleep 2
done
echo "[OK] Container ready"
echo ""

# Install asciinema + expect inside container if missing
echo "[*] Ensuring asciinema + expect are installed..."
docker exec "$CONTAINER" bash -c '
  if ! command -v asciinema >/dev/null 2>&1 || ! command -v expect >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq asciinema expect >/dev/null 2>&1
    echo "[OK] Installed asciinema + expect"
  else
    echo "[OK] Already installed"
  fi
'

# Copy expect scripts into container
echo "[*] Copying expect scripts..."
docker cp expect/ "$CONTAINER":/root/expect/
docker cp record-cli-inner.sh "$CONTAINER":/root/record-cli-inner.sh
docker exec "$CONTAINER" bash -c 'chmod +x /root/record-cli-inner.sh /root/expect/*.exp'

# Run the recording
echo "[*] Starting asciinema recording..."
echo ""

docker exec -it -e LAB_ONLY="${LAB_ONLY}" "$CONTAINER" \
  asciinema rec \
    --command "bash /root/record-cli-inner.sh" \
    --title "HackShack OpenCode CLI Tutorial" \
    --cols 120 \
    --rows 35 \
    "/root/recordings/session.cast"

# Copy recording out
docker cp "$CONTAINER":/root/recordings/session.cast "$CAST_FILE"

echo ""
echo "[OK] Recording saved: ${CAST_FILE}"
echo ""
echo "    Playback:  asciinema play ${CAST_FILE}"
echo "    Upload:    asciinema upload ${CAST_FILE}"
echo "    To GIF:    agg ${CAST_FILE} hackshack-cli.gif"
echo ""
