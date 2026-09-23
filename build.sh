#!/bin/bash
# Build the HackShack OpenWork Workshop Docker image
#
# Clones instrospect from HPE GitHub Enterprise automatically.
# Requires access to github.hpe.com (VPN or internal network).
#
# Authentication options (tried in order):
#   1. GHE_TOKEN env var (personal access token)
#   2. SSH key (~/.ssh with github.hpe.com access)
#   3. git credential manager / cached credentials
#
# Usage:
#   ./build.sh                          # clone via SSH (default)
#   GHE_TOKEN=ghp_xxx ./build.sh        # clone via HTTPS with token
#   INSTROSPECT_BRANCH=main ./build.sh  # specify branch
#   ./build.sh --build-arg FOO=bar                  # pass args to docker
#
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTROSPECT_DIR="$SCRIPT_DIR/instrospect"
INSTROSPECT_BRANCH="${INSTROSPECT_BRANCH:-main}"

INSTROSPECT_REPO_SSH="git@github.hpe.com:jonathan-sparks/instrospect.git"
INSTROSPECT_REPO_HTTPS="https://github.hpe.com/jonathan-sparks/instrospect.git"

echo "--- HackShack OpenWork Workshop -- Docker Build ---"
echo ""

# ---- Pre-flight: Docker ----

if ! command -v docker &>/dev/null; then
    echo "[ERROR] Docker is not installed."
    echo "        Install from https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] Docker daemon is not running."
    echo "        Start Docker Desktop or run: sudo systemctl start docker"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo "[ERROR] git is not installed."
    exit 1
fi

# ---- Clone instrospect ----

echo "[*] Fetching instrospect from github.hpe.com..."

# Clean up any previous build artifact
rm -rf "$INSTROSPECT_DIR"

clone_succeeded=false

# Method 1: HTTPS with token (if GHE_TOKEN is set)
if [ -n "$GHE_TOKEN" ]; then
    echo "    Using HTTPS with GHE_TOKEN..."
    REPO_URL="https://${GHE_TOKEN}@github.hpe.com/jonathan-sparks/instrospect.git"
    if git clone --depth 1 --branch "$INSTROSPECT_BRANCH" "$REPO_URL" "$INSTROSPECT_DIR" 2>/dev/null; then
        clone_succeeded=true
        echo "    [OK] Cloned via HTTPS token"
    else
        echo "    [WARN] HTTPS token clone failed, trying SSH..."
    fi
fi

# Method 2: SSH
if [ "$clone_succeeded" = false ]; then
    echo "    Trying SSH ($INSTROSPECT_REPO_SSH)..."
    if git clone --depth 1 --branch "$INSTROSPECT_BRANCH" "$INSTROSPECT_REPO_SSH" "$INSTROSPECT_DIR" 2>/dev/null; then
        clone_succeeded=true
        echo "    [OK] Cloned via SSH"
    else
        echo "    [WARN] SSH clone failed, trying HTTPS with credentials..."
    fi
fi

# Method 3: HTTPS with git credential manager
if [ "$clone_succeeded" = false ]; then
    echo "    Trying HTTPS ($INSTROSPECT_REPO_HTTPS)..."
    echo "    (git may prompt for credentials)"
    if git clone --depth 1 --branch "$INSTROSPECT_BRANCH" "$INSTROSPECT_REPO_HTTPS" "$INSTROSPECT_DIR"; then
        clone_succeeded=true
        echo "    [OK] Cloned via HTTPS"
    fi
fi

# Handle failure
if [ "$clone_succeeded" = false ]; then
    echo ""
    echo "[ERROR] Could not clone instrospect from github.hpe.com"
    echo ""
    echo "  This repo requires HPE GitHub Enterprise access."
    echo "  Make sure you are on the HPE network (or VPN) and have one of:"
    echo ""
    echo "  Option A: Personal access token"
    echo "    1. Go to https://github.hpe.com/settings/tokens"
    echo "    2. Create a token with 'repo' scope"
    echo "    3. Run: GHE_TOKEN=your_token ./build.sh"
    echo ""
    echo "  Option B: SSH key"
    echo "    1. Add your SSH public key at https://github.hpe.com/settings/keys"
    echo "    2. Verify: ssh -T git@github.hpe.com"
    echo "    3. Run: ./build.sh"
    echo ""
    exit 1
fi

# Remove .git from the clone (not needed in Docker build context)
rm -rf "$INSTROSPECT_DIR/.git"

# ---- Build Docker image ----

echo ""
echo "[*] Building Docker image..."

BUILD_LOG=$(mktemp)
if docker compose build "$@" > "$BUILD_LOG" 2>&1; then
    echo "[OK] Docker image built successfully"
else
    echo "[FAIL] Docker build failed. Last 25 lines of output:"
    echo ""
    tail -25 "$BUILD_LOG"
    echo ""
    rm -f "$BUILD_LOG"
    rm -rf "$INSTROSPECT_DIR"
    exit 1
fi
rm -f "$BUILD_LOG"

# ---- Cleanup ----

# Remove instrospect from build context (it was only needed during docker build)
rm -rf "$INSTROSPECT_DIR"

echo ""
echo "--- Build complete ---"
echo ""
echo "  Start:    docker compose up -d"
echo "  Connect:  docker exec -it hackshack-lab bash"
echo "  Validate: docker exec -it hackshack-lab bash tests/validate-env.sh"
