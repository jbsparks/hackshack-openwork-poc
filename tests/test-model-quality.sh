#!/bin/bash
# Test that Zen free models can handle tool-use-like structured prompts
# This validates the model is good enough for OpenCode's skill/tool workflow
# Run inside the container: bash ~/tests/test-model-quality.sh

set -o pipefail

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }

echo "--- Model Quality Tests (Zen free: nemotron-3-ultra-free) ---"
echo ""

# Helper: send prompt, get response via Zen API
ask() {
    local prompt="$1"
    curl -s --max-time 30 https://opencode.ai/zen/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer free" \
        -d "{\"model\": \"nemotron-3-ultra-free\", \"messages\": [{\"role\": \"user\", \"content\": \"${prompt}\"}], \"max_tokens\": 200}" \
        | jq -r '.choices[0].message.content // ""'
}

# Test 1: Can follow simple instructions
echo "[1/5] Instruction following..."
RESP=$(ask "Reply with ONLY the number 42. No other text.")
if echo "$RESP" | grep -q "42"; then
    pass "Follows simple instructions"
else
    fail "Instruction following (got: '${RESP:0:80}')"
fi

# Test 2: JSON output
echo "[2/5] JSON generation..."
RESP=$(ask 'Output a JSON object with keys \"name\" and \"language\". Values: \"test\" and \"python\". Output ONLY valid JSON, no explanation.')
if echo "$RESP" | jq -e '.name' > /dev/null 2>&1; then
    pass "Can generate valid JSON"
else
    fail "JSON generation (got: '${RESP:0:100}')"
fi

# Test 3: Code generation
echo "[3/5] Code generation..."
RESP=$(ask "Write a Python function called add that takes two numbers and returns their sum. Only output the code, no explanation.")
if echo "$RESP" | grep -q "def add"; then
    pass "Can generate Python code"
else
    fail "Code generation (got: '${RESP:0:100}')"
fi

# Test 4: Multi-step reasoning
echo "[4/5] Multi-step reasoning..."
RESP=$(ask "I have 3 apples. I buy 2 more. I give away 1. How many do I have? Reply with ONLY the number.")
if echo "$RESP" | grep -q "4"; then
    pass "Basic reasoning works"
else
    fail "Reasoning (got: '${RESP:0:80}')"
fi

# Test 5: Tool-call-like structured output
echo "[5/5] Structured tool-call format..."
RESP=$(ask 'You are an AI assistant with tools. The user says \"list files in /tmp\". Respond with a tool call in this exact format: <tool_call>{\"name\": \"bash\", \"arguments\": {\"command\": \"ls /tmp\"}}</tool_call>. Output ONLY the tool call block.')
if echo "$RESP" | grep -q "bash\|ls\|tool_call"; then
    pass "Can produce tool-call-like structured output"
else
    fail "Tool-call format (got: '${RESP:0:120}')"
fi

# Summary
echo ""
echo "==========================================="
echo "  MODEL QUALITY: ${PASS}/5 passed, ${FAIL}/5 failed"
echo "==========================================="

if [ "$FAIL" -gt 2 ]; then
    echo "  [WARNING] Model may not be suitable for skill-based workflows."
    exit 1
elif [ "$FAIL" -gt 0 ]; then
    echo "  [WARNING] Some tests failed -- model works but may struggle with complex skills"
    exit 0
else
    echo "  [OK] Model is well-suited for the tutorial labs"
    exit 0
fi
