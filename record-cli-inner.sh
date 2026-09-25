#!/usr/bin/env bash
# record-cli-inner.sh — Runs INSIDE the container under asciinema
#
# Drives the full CLI lab sequence: shell commands + expect-driven TUI sessions.
# Each lab is a function so we can record individual labs with LAB_ONLY env var.

set -euo pipefail

LABS_DIR="/root/labs"
EXPECT_DIR="/root/expect"
RESPONSE_WAIT=90   # seconds to wait for AI response in TUI

cd "$LABS_DIR"

# --- Helpers ---

banner() {
  echo ""
  echo "============================================"
  echo "  $1"
  echo "============================================"
  echo ""
  sleep 2
}

pause() { sleep "${1:-2}"; }

# --- Lab 1 ---

lab1() {
  banner "Lab 1: Getting Started"

  echo "[*] Exploring the workspace..."
  pause
  ls -la
  pause 3

  echo ""
  echo "[*] Launching OpenCode TUI..."
  pause
  expect "$EXPECT_DIR/lab1.exp" "$RESPONSE_WAIT"
  pause 2

  echo ""
  echo "[*] Non-interactive mode: opencode run"
  pause
  opencode run "List the Python files in this directory" --model opencode/mimo-v2.5-free
  pause 3
}

# --- Lab 2 ---

lab2() {
  banner "Lab 2: Building Skills"

  # Part A: Hand-craft a skill
  echo "[*] Part A: Hand-crafting the greeter skill..."
  pause
  mkdir -p .opencode/skills/greeter
  cat > .opencode/skills/greeter/SKILL.md << 'SKILLEOF'
---
name: greeter
description: "Generates personalized welcome messages for workshop participants"
---

# Greeter Skill

You are now in Greeter mode. When activated, you:

1. Ask the user for their name and role
2. Generate a personalized welcome message for the workshop
3. Create a welcome.md file with:
   - A greeting header
   - Today's date
   - A fun tech fact related to their role
   - Three suggested labs based on their interests

Always be enthusiastic and encouraging!
SKILLEOF
  echo "[OK] Skill created"
  pause
  echo ""
  echo "[*] Verifying skill file:"
  cat .opencode/skills/greeter/SKILL.md
  pause 3

  echo ""
  echo "[*] Testing greeter skill in TUI..."
  pause
  expect "$EXPECT_DIR/lab2a.exp" "$RESPONSE_WAIT"
  pause 2

  # Part B: Skill creator
  echo ""
  echo "[*] Part B: Using /skill-creator..."
  pause
  expect "$EXPECT_DIR/lab2b.exp" "$RESPONSE_WAIT"
  pause 2

  echo ""
  echo "[*] Checking generated skill from shell:"
  ls .opencode/skills/
  pause 2

  # Part D: SkillSpector
  echo ""
  echo "[*] Part D: Auditing with SkillSpector..."
  pause
  skillspector scan skill .opencode/skills/greeter/ --json 2>&1 || echo "[WARN] SkillSpector not available (stub mode)"
  pause 3
}

# --- Lab 3 ---

lab3() {
  banner "Lab 3: Agent Workflow"

  echo "[*] Examining sample project..."
  pause
  ls lab-03-agent-workflow/sample-project/
  pause 2
  head -20 lab-03-agent-workflow/sample-project/*.py
  pause 3

  echo ""
  echo "[*] Creating code-reviewer skill..."
  pause
  mkdir -p .opencode/skills/code-reviewer
  cat > .opencode/skills/code-reviewer/SKILL.md << 'SKILLEOF'
---
name: code-reviewer
description: Review Python code for quality issues including missing docstrings, long functions, bare excepts, and missing type hints. Use when asked to review or audit Python code.
---

# Code Reviewer Skill

You are a senior Python code reviewer. When activated:

## Workflow

1. **Discovery**: Use Glob to find all .py files in the target directory
2. **Analysis**: For each file, Read it and check for:
   - Missing module/function docstrings
   - Functions longer than 20 lines
   - Missing type hints on function parameters
   - Bare except clauses
   - TODO/FIXME comments
3. **Report**: Generate review-report.md with:
   - Summary (total files, total issues)
   - Per-file findings table
   - Top 3 priority fixes
   - Overall code health score (A-F)

## Rules
- Be constructive, not critical
- Suggest fixes, don't just flag problems
- Score generously for tutorial/learning code
SKILLEOF
  echo "[OK] Skill created"
  pause 2

  echo ""
  echo "[*] Running code review in TUI..."
  pause
  expect "$EXPECT_DIR/lab3.exp" "$RESPONSE_WAIT"
  pause 2

  echo ""
  echo "[*] Checking output:"
  cat review-report.md 2>/dev/null || echo "[WARN] review-report.md not generated (model may have used different path)"
  pause 3

  echo ""
  echo "[*] Non-interactive run:"
  pause
  opencode run "Use the code-reviewer skill to review lab-03-agent-workflow/sample-project/" --model opencode/mimo-v2.5-free
  pause 3
}

# --- Lab 4 ---

lab4() {
  banner "Lab 4: Ingesting Community Skills"

  echo "[*] Installing find-skills from the Skills Registry..."
  pause
  npx skills add https://github.com/vercel-labs/skills --skill find-skills --agent opencode -y 2>&1 || echo "[WARN] npx skills command failed -- checking if skill was installed"
  pause 2

  echo ""
  echo "[*] Copying skill to .opencode/skills/ for OpenCode..."
  cp -r .agents/skills/find-skills .opencode/skills/find-skills 2>/dev/null || echo "[WARN] copy failed -- skill may not have installed"
  pause

  echo ""
  echo "[*] Inspecting installed skill:"
  cat .opencode/skills/find-skills/SKILL.md 2>/dev/null || echo "[WARN] find-skills not found at expected path"
  pause 3

  echo ""
  echo "[*] Auditing with SkillSpector..."
  pause
  skillspector scan skill .opencode/skills/find-skills/ --json 2>&1 || echo "[WARN] SkillSpector not available (stub mode)"
  pause 3

  echo ""
  echo "[*] Using find-skills in TUI..."
  pause
  expect "$EXPECT_DIR/lab4.exp" "$RESPONSE_WAIT"
  pause 2

  echo ""
  echo "[*] Comparing all skills:"
  pause
  for d in .opencode/skills/*/; do
    echo "=== $d ==="
    skillspector scan skill "$d" --json 2>&1 | tail -5 || echo "[WARN] scan failed"
    echo ""
  done
  pause 3
}

# --- Main ---

banner "HackShack OpenCode CLI Tutorial"

if [ -z "${LAB_ONLY:-}" ]; then
  lab1
  lab2
  lab3
  lab4
else
  case "$LAB_ONLY" in
    1) lab1 ;;
    2) lab2 ;;
    3) lab3 ;;
    4) lab4 ;;
    *) echo "[FAIL] Unknown lab: $LAB_ONLY"; exit 1 ;;
  esac
fi

banner "Tutorial Complete!"
echo "You have completed the HackShack OpenCode CLI workshop."
echo ""
pause 3
