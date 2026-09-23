#!/bin/bash
# Quick smoke test for Docker build (runs outside the container)
# Usage: bash tests/test-docker-build.sh

set -e

IMAGE_NAME="hackshack-openwork-test"
CONTAINER_NAME="hackshack-test-$$"

echo "--- Docker Build Test ---"
echo ""

# Test 0: Docker is actually running
echo "[0/6] Checking Docker daemon..."
if ! command -v docker &>/dev/null; then
    echo "  [FAIL] Docker not installed"
    echo "     Install from https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "  [FAIL] Docker daemon is not running"
    echo "     Start Docker Desktop or run: sudo systemctl start docker"
    exit 1
fi

DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
echo "  [OK] Docker is running (v${DOCKER_VERSION})"

# Test 1: Image builds successfully
echo "[1/6] Building Docker image..."
BUILD_LOG=$(mktemp)
if docker build -t "$IMAGE_NAME" . > "$BUILD_LOG" 2>&1; then
    echo "  [OK] Image builds successfully"
else
    echo "  [FAIL] Docker build failed. Last 25 lines of output:"
    echo ""
    tail -25 "$BUILD_LOG"
    echo ""
    rm -f "$BUILD_LOG"
    exit 1
fi
rm -f "$BUILD_LOG"

# Test 2: Container starts
echo "[2/6] Starting container..."
docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep 300 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "  [OK] Container starts"
else
    echo "  [FAIL] Container failed to start"
    exit 1
fi

# Test 3: OpenCode installed from npm (opencode-ai package)
echo "[3/6] Checking OpenCode package..."
if docker exec "$CONTAINER_NAME" npm list -g opencode-ai > /dev/null 2>&1; then
    echo "  [OK] OpenCode installed from npm (opencode-ai)"
else
    echo "  [FAIL] OpenCode npm package missing"
fi

# Test 4: OpenCode binary exists
echo "[4/6] Checking OpenCode CLI..."
if docker exec "$CONTAINER_NAME" which opencode > /dev/null 2>&1; then
    echo "  [OK] OpenCode CLI present"
else
    echo "  [FAIL] OpenCode CLI missing"
fi

# Test 5: OpenCode config for Zen free models
echo "[5/6] Checking Zen model config..."
if docker exec "$CONTAINER_NAME" test -f /root/.config/opencode/config.json; then
    if docker exec "$CONTAINER_NAME" bash -c 'jq -e ".provider.zen" /root/.config/opencode/config.json' > /dev/null 2>&1; then
        echo "  [OK] Zen provider configured (free cloud models)"
    else
        echo "  [FAIL] Zen provider not in config"
    fi
else
    echo "  [FAIL] OpenCode config missing"
fi

# Test 6: Lab files present
echo "[6/6] Checking lab files..."
LABS_OK=true
for lab in lab-01-getting-started lab-02-skills lab-03-agent-workflow; do
    if ! docker exec "$CONTAINER_NAME" test -f "/root/labs/${lab}/README.md"; then
        echo "  [FAIL] Missing: ${lab}/README.md"
        LABS_OK=false
    fi
done
if [ "$LABS_OK" = true ]; then
    echo "  [OK] All lab files present"
fi

# Cleanup
echo ""
echo "Cleaning up..."
docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
docker rmi "$IMAGE_NAME" > /dev/null 2>&1 || true

echo ""
echo "--- Build test complete ---"
