# Lab 03: Building an Agent Workflow (Web UI)

## Objective
Combine skills, tools, and multi-step prompts to build an automated workflow -- all from the web interface.

## Scenario

You are building a "Code Review Agent" that:
1. Scans a project for Python files
2. Checks for common issues (no docstrings, long functions, missing type hints)
3. Generates a review report in markdown

## Steps

### 1. Verify the Sample Project

Ask OpenCode in the left panel:

```
List the files in lab-03-agent-workflow/sample-project/ and show me the first few lines of each
```

A sample Python project with 3 files (app.py, utils.py, database.py) is pre-loaded for you to review. These files have intentional issues for the reviewer to find.

### 2. Create the Code Review Skill

Ask OpenCode to create the skill directory and file. Skills must be created at the **project root** (`/root/labs/.opencode/skills/`) -- not inside a lab subdirectory -- so OpenCode discovers them at session start.

```
Create the directory /root/labs/.opencode/skills/code-reviewer/ and then create a SKILL.md file inside it with this content:

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
```

> **Important**: The `name` and `description` fields in the YAML frontmatter are mandatory. Without `description`, OpenCode will silently ignore the skill.
>
> **Why the project root?** OpenCode scans `.opencode/skills/` relative to the project root (`/root/labs/`). Skills placed inside lab subdirectories (e.g., `lab-03-agent-workflow/.opencode/`) are invisible to OpenCode.

### 3. Run the Workflow

Start a **new session** (click the **+** icon). Then load the newly created skill:

```
Load all local skills
```

> **Known behavior**: OpenCode may show a warning like `Skill "code-reviewer" not found` in its skill registry. This is expected -- skills created mid-session are not automatically registered. However, the "Load all local skills" prompt causes the model to read the SKILL.md files directly, and the skill **will work** despite the warning. A fix is pending upstream.

Once loaded, run the review:

```
Use the code-reviewer skill to review the lab-03-agent-workflow/sample-project/ directory
```

Watch how the AI:
1. Uses Glob to find all `.py` files
2. Reads each file one by one
3. Analyzes the code for issues
4. Generates a structured `review-report.md`

### 4. Examine the Output

Ask OpenCode:

```
Show me the formatted review-report.md that was just generated
```

The AI used multiple tools in sequence to complete a multi-step workflow automatically. Check that it found issues like:
- SQL injection in database.py
- Bare except clauses
- Missing type hints
- Missing docstrings

### 5. Challenge: Extend It

Try adding capabilities to the skill:

```
Update the code-reviewer skill to also include a "fix mode" that auto-corrects simple issues like missing docstrings and type hints
```

Or ask the reviewer to produce different output:

```
Use the code-reviewer skill on lab-03-agent-workflow/sample-project/ but output the results as JSON instead of markdown
```

## Key Concepts

- **Agent workflows** combine skills + tools in multi-step sequences
- The AI decides tool ordering based on the skill's instructions
- Skills can define **structured outputs** (reports, JSON, etc.)
- Good workflows are **decomposable** -- each step is verifiable
- Start a **new session** after creating a skill so OpenCode re-scans and discovers it

## Next Lab
-> Click the **Lab 4** tab above to learn about ingesting community skills

## What You Learned

- How to build multi-step agent workflows from the web UI
- Skills + tools combine to create automated review pipelines
- Structured output (reports, JSON) makes workflows verifiable
