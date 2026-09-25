# Lab 02: Building Skills (Web UI)

## Objective
Learn multiple ways to create OpenCode skills, then audit them for quality and safety using the SkillSpector tool.

This lab has 4 parts:
- **Part A:** Hand-craft a skill from scratch (understand the anatomy)
- **Part B:** Use the `/skill-creator` to generate skills from a description
- **Part C:** Create a skill from an existing document (turn docs into expertise)
- **Part D:** Audit your skills with SkillSpector (provenance, safety, adversarial testing)

---

## Part A: Hand-Craft a Skill

### What is a Skill?

A skill is a markdown file (`SKILL.md`) with optional YAML frontmatter that injects domain-specific instructions into the AI when triggered. Think of it as a reusable "expert mode."

> **Best practice references:**
> - [OpenCode Skills Documentation](https://opencode.ai/docs/skills/) -- placement, frontmatter, naming, globs, auto-loading
> - [Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- clear instructions, role assignment, structured output

### Key Skill Design Principles

From the docs above, keep these in mind when writing skills:

1. **Be specific** -- tell the AI exactly what to do, in what order, and what output to produce
2. **Use structured steps** -- numbered workflows outperform vague instructions
3. **Define the persona** -- "You are a senior Python code reviewer" is better than "Review code"
4. **Specify output format** -- describe the exact structure of reports, files, or responses
5. **Set boundaries** -- tell it what NOT to do (e.g., "Be constructive, not critical")

### 1. Create a Skill Directory

Skills must live at the **project root** (`.opencode/skills/` under `/root/labs/`), not inside a lab subdirectory. Ask OpenCode in the left panel:

```
Create a directory at /root/labs/.opencode/skills/greeter/
```

### 2. Write Your Skill

Ask OpenCode to create the skill file:

```
Create the file /root/labs/.opencode/skills/greeter/SKILL.md with this content:

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
```

> **Frontmatter is required**: The `name` and `description` fields in the YAML block (`---`) are mandatory. Without `description`, OpenCode silently ignores the skill.
>
> **Why the project root?** OpenCode scans `.opencode/skills/` relative to the project root (`/root/labs/`). Skills placed inside lab subdirectories (e.g., `lab-02-skills/.opencode/`) are invisible to OpenCode.

### 3. Test Your Skill

Start a **new session** by clicking the **+** button in the top tab bar of the left panel. Then load your skills:

```
Load all local skills
```

> **Known behavior**: OpenCode may show a warning like `Skill "greeter" not found` in its skill registry. This is expected -- skills created mid-session are not automatically registered. However, the "Load all local skills" prompt causes the model to read the SKILL.md files directly, and the skill **will work** despite the warning. A fix is pending upstream.

Once loaded, invoke the greeter:

```
Use the greeter skill to welcome me
```

When asked, provide your name and role (e.g., "Alex, Developer").

Then view the output:

```
Show me the contents of welcome.md
```

### 4. Skill Anatomy Reference

```
.opencode/skills/my-skill/
+-- SKILL.md          # Instructions + YAML header (required)
+-- templates/        # Optional reference files the skill can read
|   +-- example.md
+-- scripts/          # Optional helper scripts
    +-- validate.sh
```

The YAML frontmatter tells OpenCode *when* to suggest the skill. The body tells the AI *what to do*.

---

## Part B: Use the Skill Creator

OpenCode has a built-in skill builder that generates skills from a description. Instead of hand-writing SKILL.md, you describe what you want.

### How Skill Activation Works

Before we create a new skill, it helps to understand how OpenCode decides which skill to use:

1. **Scanning**: At startup, OpenCode scans all `.opencode/skills/*/SKILL.md` files in the project
2. **Matching**: When you send a message, OpenCode compares your prompt against each skill's `name` and `description` from the YAML frontmatter
3. **Selection**: If your prompt matches a skill's description, OpenCode automatically injects that skill's instructions into the AI's context
4. **Explicit trigger**: You can also force a skill by name -- e.g., "Use the greeter skill" matches the skill with `name: greeter`

This is why the `description` field matters so much -- it is the primary signal OpenCode uses to decide when a skill is relevant. A vague description means the skill rarely activates. A specific description with clear trigger phrases means it activates reliably.

For example, with our greeter skill:
- `description: "Generates personalized welcome messages"` -- activates when you say "welcome me" or "generate a greeting"
- Saying "Use the greeter skill" -- activates by explicit name match

### 1. Invoke the Skill Creator

In the left panel, type:
```
/skill-creator
```

Then describe the skill you want:
```
Use the skill-creator to create a skill that reviews Python files for security issues.
It should check for: hardcoded credentials, use of eval/exec,
SQL injection patterns, and insecure HTTP calls.
Output a security-report.md with findings sorted by severity.
```

### 2. Examine the Generated Skill

Ask OpenCode to show you what it created:

```
Show me the SKILL.md file that was just generated
```

Notice how the creator:
- Added proper YAML frontmatter (`name`, `description`)
- Structured the procedure with clear steps
- Defined trigger phrases
- Set up the expected output format

### 3. Test the Generated Skill

Start a **new session** and load the newly created skill:

```
Load all local skills
```

Then:

```
Use the security reviewer skill on the sample code in lab-03-agent-workflow/sample-project/
```

### 4. Iterate on It

Not happy with the result? Tell the skill creator what to change:
```
/skill-creator Update the security reviewer to also check for
subprocess calls with shell=True and rate each finding as
Critical, High, Medium, or Low
```

---

## Part C: Create a Skill from a Document

The most powerful skill-building technique: turn existing documentation, runbooks, or guides into skills. The AI becomes an expert on *your* processes.

### 1. Examine the Sample Document

Ask OpenCode:

```
Format and show me the file docs/server-troubleshooting-guide.md
```

This is a typical IT troubleshooting guide for Linux servers. We will turn it into a skill.

### 2. Use the Skill Creator with Document Input

```
/skill-creator Create a skill from the document at docs/server-troubleshooting-guide.md.
The skill should guide users through the troubleshooting steps interactively,
asking diagnostic questions and recommending actions based on the answers.
```

### 3. Try It Out

Start a new session, then load skills:

```
Load all local skills
```

Then:

```
Use the server troubleshooter skill. My server has high CPU usage.
```

### 4. Create Your Own Document-Based Skill

Got your own runbook, playbook, or process doc? Try it:

```
/skill-creator Create a skill from <paste or describe your document>.
Make it interactive -- the skill should ask clarifying questions
before making recommendations.
```

### 5. Try It with Real-World HPC Documentation

Here are some publicly available documents that make excellent skill sources for HPC workflows involving Quantum Espresso, GPUs, and containers:

| Source | URL |
|--------|-----|
| Nvidia NGC -- Quantum Espresso Container | https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/quantum_espresso |
| NERSC -- Quantum Espresso Docs | https://docs.nersc.gov/applications/quantum-espresso/ |
| Pawsey -- Singularity/Apptainer Guide | https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity |

Try creating a skill from one of these:

```
/skill-creator Create a skill from the Quantum Espresso container guide at
https://catalog.ngc.nvidia.com/orgs/hpc/-/containers/quantum_espresso,
https://docs.nersc.gov/applications/quantum-espresso/, and
https://pawsey.atlassian.net/wiki/spaces/US/pages/51925894/Singularity.
The skill should help users pull the container, configure GPU offload,
and launch via Slurm and singularity/apptainer a QE calculation with optimal GPU settings.
```

Then ask OpenCode to show what it created:

```
Show me the SKILL.md file that was just generated
```

> **Important -- public models and proprietary information**: This lab uses free public cloud models. Anything you paste into the prompt is sent to a third-party model provider. **Do not paste proprietary, confidential, or export-controlled documents** into prompts when using public models. Use only publicly available sources like the ones listed above. For internal/proprietary documents, use a self-hosted or private model deployment.

### Key Insight

Any structured knowledge -- troubleshooting guides, coding standards, review checklists, onboarding docs -- can become a skill. The document is the expertise; the skill makes it *actionable*.

---

## Part D: Scan Skills with NVIDIA SkillSpector

NVIDIA SkillSpector is an open-source static security scanner for agent skills. This lab uses `--no-llm`, so no provider key is required and skill content is not sent to an external model. SkillSpector analyzes files; it does not execute the scanned skill as a behavioral sandbox.

Run a scan:

```
skillspector scan .opencode/skills/greeter/ --no-llm --format json
```

Save a machine-readable report:

```
skillspector scan .opencode/skills/greeter/ --no-llm --format json --output greeter-scan.json
```

You can produce SARIF for security tooling:

```
skillspector scan .opencode/skills/greeter/ --no-llm --format sarif --output greeter-scan.sarif
```

Audit the generated skill:

```
skillspector scan .opencode/skills/security-reviewer/ --no-llm --format json
```

Pick a finding, ask OpenCode to fix it, and rerun the scan.

## Key Concepts

| Concept | Takeaway |
|---------|----------|
| **Skills are declarative** | Describe WHAT the AI should do, not HOW |
| **`/skill-creator`** | Generates skills from descriptions or documents |
| **Document -> Skill** | Any structured knowledge can become actionable |
| **Provenance headers** | Track who made it, when, and how |
| **SkillSpector** | Static analysis + adversarial behavioral testing |
| **Audit before deploy** | Especially for skills from external sources |

## Next Lab
-> Click the **Lab 3** tab above to build an Agent Workflow
