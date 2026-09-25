# hackshack-cli.tape — VHS deterministic recording of shell-only portions
#
# This captures the shell commands (mkdir, cat, ls, SkillSpector) as a clean
# GIF/MP4. TUI sessions (opencode) are NOT included here — those are
# captured by the asciinema+expect flow in record-cli.sh.
#
# Usage:
#   vhs hackshack-cli.tape
#
# Prerequisites:
#   - brew install charmbracelet/tap/vhs
#   - Container running: make up

Output recordings/hackshack-cli-shell.gif
Output recordings/hackshack-cli-shell.mp4

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 700
Set Padding 20
Set Theme "Dracula"
Set TypingSpeed 30ms
Set PlaybackSpeed 1.5

# --- Connect to container ---

Type "docker exec -it hackshack-lab bash"
Enter
Sleep 2s

# --- Lab 1: Getting Started ---

Type "echo '=== Lab 1: Getting Started ==='"
Enter
Sleep 1s

Type "cd /root/labs && ls -la"
Enter
Sleep 2s

Type "# TUI session would happen here (see asciinema recording)"
Enter
Sleep 1s

Type "opencode run 'List the Python files in this directory' --model opencode/mimo-v2.5-free"
Enter
Sleep 30s

# --- Lab 2: Building Skills ---

Type "echo '=== Lab 2: Building Skills ==='"
Enter
Sleep 1s

Type "mkdir -p .opencode/skills/greeter"
Enter
Sleep 500ms

Type@50ms "cat > .opencode/skills/greeter/SKILL.md << 'EOF'"
Enter
Type "---"
Enter
Type "name: greeter"
Enter
Type 'description: "Generates personalized welcome messages for workshop participants"'
Enter
Type "---"
Enter
Type "# Greeter Skill"
Enter
Type "EOF"
Enter
Sleep 1s

Type "cat .opencode/skills/greeter/SKILL.md"
Enter
Sleep 2s

Type "# TUI session: test greeter, run /skill-creator (see asciinema)"
Enter
Sleep 1s

Type "skillspector scan skill .opencode/skills/greeter/ --json"
Enter
Sleep 5s

# --- Lab 3: Agent Workflow ---

Type "echo '=== Lab 3: Agent Workflow ==='"
Enter
Sleep 1s

Type "ls lab-03-agent-workflow/sample-project/"
Enter
Sleep 1s

Type "head -20 lab-03-agent-workflow/sample-project/*.py"
Enter
Sleep 3s

Type "mkdir -p .opencode/skills/code-reviewer"
Enter
Sleep 500ms

Type "# (creating code-reviewer SKILL.md — see full script)"
Enter
Sleep 1s

Type "# TUI session: run code review workflow (see asciinema)"
Enter
Sleep 1s

# --- Lab 4: Ingesting Community Skills ---

Type "echo '=== Lab 4: Ingesting Community Skills ==='"
Enter
Sleep 1s

Type "npx skills add https://github.com/vercel-labs/skills --skill find-skills"
Enter
Sleep 15s

Type "cat .opencode/skills/find-skills/SKILL.md | head -30"
Enter
Sleep 2s

Type "skillspector scan skill .opencode/skills/find-skills/ --json"
Enter
Sleep 5s

Type "# Compare all skills"
Enter
Type "for d in .opencode/skills/*/; do echo \"=== $d ===\"; skillspector scan skill \"$d\" --json 2>&1 | tail -5; done"
Enter
Sleep 10s

Type "echo '=== Tutorial Complete! ==='"
Enter
Sleep 2s

Type "exit"
Enter
Sleep 1s
