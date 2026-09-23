# Lab 03: Building an Agent Workflow

## Objective
Combine skills, tools, and multi-step prompts to build an automated workflow.

## Scenario

You are building a "Code Review Agent" that:
1. Scans a project for Python files
2. Checks for common issues (no docstrings, long functions, missing type hints)
3. Generates a review report in markdown

## Steps

### 1. Set Up the Project to Review

```bash
cd /root/labs/lab-03-agent-workflow
ls sample-project/
```

A sample Python project is pre-loaded for you to review.

### 2. Create the Code Review Skill

Create `.opencode/skills/code-reviewer/SKILL.md`:

```bash
mkdir -p .opencode/skills/code-reviewer
```

Then create the file with this content (the YAML frontmatter block at the top is required -- without `name` and `description`, OpenCode will not discover the skill):

```markdown
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
3. **Report**: Generate `review-report.md` with:
   - Summary (total files, total issues)
   - Per-file findings table
   - Top 3 priority fixes
   - Overall code health score (A-F)

## Rules
- Be constructive, not critical
- Suggest fixes, don't just flag problems
- Score generously for tutorial/learning code
```

> **Important**: OpenCode discovers skills at startup. After creating the skill file, you need to start a new `opencode` session for it to appear.

### 3. Run the Workflow

Start a fresh OpenCode session so it picks up the new skill:

```bash
opencode
```

Then:
```
Use the code-reviewer skill to review the sample-project/ directory
```

### 4. Examine the Output

Check the generated `review-report.md` -- the AI used multiple tools in sequence to complete a multi-step workflow automatically.

### 5. Challenge: Extend It

Try adding:
- A "fix mode" that auto-corrects simple issues
- A severity rating (info/warning/error)
- JSON output for CI/CD integration

## Key Concepts

- **Agent workflows** combine skills + tools in multi-step sequences
- The AI decides tool ordering based on the skill's instructions
- Skills can define **structured outputs** (reports, JSON, etc.)
- Good workflows are **decomposable** -- each step is verifiable

## Congratulations!

You have completed the HackShack OpenCode tutorial series. You now know how to:
- Use OpenCode with free cloud AI models
- Create custom skills
- Build multi-step agent workflows

## Next Lab
-> [Lab 04: Ingesting Community Skills](../lab-04-ingesting-skills/README.md)
