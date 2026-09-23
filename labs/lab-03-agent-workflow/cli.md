# Lab 03: Building an Agent Workflow (CLI)

## Objective
Combine skills, tools, and multi-step prompts to build an automated workflow from the terminal.

## Scenario

You are building a "Code Review Agent" that:
1. Scans a project for Python files
2. Checks for common issues (no docstrings, long functions, missing type hints)
3. Generates a review report in markdown

## Steps

### 1. Set Up the Project to Review

```bash
cd /root/labs
ls lab-03-agent-workflow/sample-project/
```

A sample Python project with 3 files (app.py, utils.py, database.py) is pre-loaded for you to review. These files have intentional issues for the reviewer to find.

### 2. Create the Code Review Skill

Skills must be created at the **project root** (`/root/labs/.opencode/skills/`) -- not inside a lab subdirectory -- so OpenCode discovers them at session start.

```bash
cd /root/labs
mkdir -p .opencode/skills/code-reviewer
```

Create `.opencode/skills/code-reviewer/SKILL.md`:

```bash
cat > .opencode/skills/code-reviewer/SKILL.md << 'EOF'
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
EOF
```

> **Important**: The `name` and `description` fields in the YAML frontmatter are mandatory. Without `description`, OpenCode will silently ignore the skill.
>
> **Why the project root?** OpenCode scans `.opencode/skills/` relative to the project root (`/root/labs/`). Skills placed inside lab subdirectories (e.g., `lab-03-agent-workflow/.opencode/`) are invisible to OpenCode.

### 3. Run the Workflow

Start a fresh OpenCode session so it picks up the new skill:

```bash
opencode
```

Load the newly created skill:
```
Load all local skills
```

> **Known behavior**: OpenCode may show a warning like `Skill "code-reviewer" not found` in its skill registry. This is expected -- skills created mid-session are not automatically registered. However, the "Load all local skills" prompt causes the model to read the SKILL.md files directly, and the skill **will work** despite the warning. A fix is pending upstream.

Then run the review:
```
Use the code-reviewer skill to review the lab-03-agent-workflow/sample-project/ directory
```

Watch how the AI:
1. Uses Glob to find all `.py` files
2. Reads each file one by one
3. Analyzes the code for issues
4. Generates a structured `review-report.md`

### 4. Examine the Output

Exit OpenCode and check the generated report:

```bash
cat review-report.md
```

The AI used multiple tools in sequence to complete a multi-step workflow automatically. Check that it found issues like:
- SQL injection in database.py
- Bare except clauses
- Missing type hints
- Missing docstrings

### 5. Run Non-Interactively

You can also trigger the whole workflow in a single command:

```bash
opencode run "Use the code-reviewer skill to review the lab-03-agent-workflow/sample-project/ directory" \
    --model opencode/mimo-v2.5-free
```

This is useful for integrating agent workflows into CI/CD pipelines or cron jobs.

### 6. Challenge: Extend It

Try adding to the skill:

```bash
# Edit the SKILL.md to add new capabilities
nano .opencode/skills/code-reviewer/SKILL.md
```

Ideas:
- A "fix mode" that auto-corrects simple issues
- A severity rating (info/warning/error) for each finding
- JSON output for CI/CD integration

Then re-run:
```bash
opencode run "Use the code-reviewer skill on lab-03-agent-workflow/sample-project/ and output results as JSON"
```

## Key Concepts

- **Agent workflows** combine skills + tools in multi-step sequences
- The AI decides tool ordering based on the skill's instructions
- Skills can define **structured outputs** (reports, JSON, etc.)
- Good workflows are **decomposable** -- each step is verifiable
- **`opencode run`** executes workflows non-interactively for automation
- Start a **new session** after creating a skill so OpenCode re-scans and discovers it

## Next Lab
-> Switch to the **Lab 4** tab to learn about ingesting community skills

## What You Learned

- How to build multi-step agent workflows from the terminal
- Skills + tools combine to create automated review pipelines
- `opencode run` enables non-interactive execution for CI/CD
