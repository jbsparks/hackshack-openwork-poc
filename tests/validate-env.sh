#!/bin/bash
# HPE HackShack Environment Validation Tests
# Run inside the container: bash ~/tests/validate-env.sh
# Exit codes: 0 = all pass, 1 = failures detected

set -o pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1"; ((WARN++)); }
section() { echo ""; echo "--- $1 ---"; }

# --- SYSTEM BASICS ---

section "System Requirements"

# OS
if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    pass "Ubuntu detected ($(grep VERSION_ID /etc/os-release | cut -d= -f2 | tr -d '"'))"
else
    fail "Expected Ubuntu OS"
fi

# Memory
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_MEM_GB=$((TOTAL_MEM_KB / 1024 / 1024))
if [ "$TOTAL_MEM_GB" -ge 1 ]; then
    pass "Memory: ${TOTAL_MEM_GB} GB"
else
    fail "Memory: ${TOTAL_MEM_GB} GB (insufficient)"
fi

# CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -ge 2 ]; then
    pass "CPU cores: ${CPU_CORES}"
else
    warn "CPU cores: ${CPU_CORES} (2+ recommended)"
fi

# --- REQUIRED TOOLS ---

section "Required Tools"

for cmd in curl git jq python3 node npm; do
    if command -v "$cmd" &>/dev/null; then
        pass "$cmd installed ($(command -v $cmd))"
    else
        fail "$cmd not found"
    fi
done

# --- OPENCODE CLI ---

section "OpenCode CLI"

if command -v opencode &>/dev/null; then
    pass "OpenCode CLI installed"
    OC_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
    pass "OpenCode version: ${OC_VERSION}"
else
    fail "OpenCode CLI not found"
fi

# --- OPENCODE CONFIG ---

section "OpenCode Configuration"

CONFIG_FILE="/root/.config/opencode/config.json"
if [ -f "$CONFIG_FILE" ]; then
    pass "OpenCode config exists"
    if jq -e '.provider.zen' "$CONFIG_FILE" > /dev/null 2>&1; then
        pass "Zen provider configured (free cloud models)"
    else
        fail "Zen provider not configured in opencode config"
    fi
    MODEL_COUNT=$(jq '.provider.zen.models | length' "$CONFIG_FILE" 2>/dev/null || echo 0)
    pass "Models configured: ${MODEL_COUNT}"
else
    fail "OpenCode config missing at ${CONFIG_FILE}"
fi

# --- ZEN MODEL CONNECTIVITY ---

section "Zen Free Model Connectivity"

ZEN_RESPONSE=$(curl -s --max-time 15 https://opencode.ai/zen/v1/models 2>/dev/null)
if [ $? -eq 0 ] && echo "$ZEN_RESPONSE" | jq -e '.data' > /dev/null 2>&1; then
    pass "Zen API reachable (models endpoint)"
else
    fail "Cannot reach Zen API at opencode.ai/zen/v1 -- check network/TLS"
fi

# --- NVIDIA SKILLSPECTOR ---

section "NVIDIA SkillSpector (Skill Auditing)"

if command -v skillspector >/dev/null 2>&1; then
    pass "SkillSpector CLI installed"
else
    fail "SkillSpector CLI not found"
fi

if command -v skillspector >/dev/null 2>&1 && skillspector scan /root/labs/.opencode/skills --no-llm --format json >/tmp/skillspector-validation.json 2>/tmp/skillspector-validation.err; then
    pass "SkillSpector static scan completed"
else
    fail "SkillSpector static scan failed"
fi

# --- LAB MATERIALS ---

section "Lab Materials"

LABS_DIR="/root/labs"

for lab in lab-01-getting-started lab-02-skills lab-03-agent-workflow; do
    if [ -f "${LABS_DIR}/${lab}/README.md" ]; then
        pass "Lab found: ${lab}"
    else
        fail "Lab missing: ${lab}/README.md"
    fi
done

if [ -f "${LABS_DIR}/lab-02-skills/docs/server-troubleshooting-guide.md" ]; then
    pass "Sample document present for Lab 02 Part C"
else
    fail "Sample document missing for Lab 02 Part C"
fi

if [ -f "${LABS_DIR}/lab-03-agent-workflow/sample-project/app.py" ]; then
    pass "Sample project present for Lab 03"
else
    fail "Sample project missing for Lab 03"
fi

# --- WORKSPACE ---

section "Workspace Structure"

if [ -d "${LABS_DIR}" ]; then
    pass "Labs directory exists"
else
    fail "Labs directory missing"
fi

if [ -w "${LABS_DIR}" ]; then
    pass "Labs directory is writable"
else
    fail "Labs directory is not writable"
fi

if [ -d "${LABS_DIR}/.git" ]; then
    pass "Labs directory is a git repo"
else
    warn "Labs directory is not a git repo (opencode may not detect project)"
fi

# --- NETWORK ---

section "Network"

if curl -s --max-time 5 https://opencode.ai > /dev/null 2>&1; then
    pass "Outbound HTTPS to opencode.ai working"
else
    fail "Cannot reach opencode.ai -- Zen models will not work"
fi

# --- SUMMARY ---

echo ""
echo "==========================================="
echo "  RESULTS: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
echo "==========================================="

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "  [FAIL] Environment NOT ready. Fix failures above."
    exit 1
else
    echo ""
    echo "  [OK] Environment ready for HackShack!"
    exit 0
fi
