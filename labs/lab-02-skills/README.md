# Lab 02: Building Skills -- From Scratch, From Documents, and Auditing Them

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

### 1. Create a Skill Directory

```bash
cd /root/labs/lab-02-skills
mkdir -p .opencode/skills/greeter
```

### 2. Write Your Skill

Create `.opencode/skills/greeter/SKILL.md`:

```markdown
---
name: greeter
description: "Generates personalized welcome messages for workshop participants"
---

# Greeter Skill

You are now in Greeter mode. When activated, you:

1. Ask the user for their name and role
2. Generate a personalized welcome message for the workshop
3. Create a `welcome.md` file with:
   - A greeting header
   - Today's date
   - A fun tech fact related to their role
   - Three suggested labs based on their interests

Always be enthusiastic and encouraging!
```

### 3. Test Your Skill

```bash
opencode
```

Then type:
```
Use the greeter skill to welcome me
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

### 1. Launch OpenCode

```bash
cd /root/labs/lab-02-skills
opencode
```

### 2. Invoke the Skill Creator

Type:
```
/skill-creator
```

Then describe the skill you want:
```
Create a skill that reviews Python files for security issues.
It should check for: hardcoded credentials, use of eval/exec,
SQL injection patterns, and insecure HTTP calls.
Output a security-report.md with findings sorted by severity.
```

### 3. Examine the Generated Skill

The skill creator produces a complete SKILL.md in `.opencode/skills/`. Read it:

```bash
cat .opencode/skills/*/SKILL.md
```

Notice how the creator:
- Added proper YAML frontmatter (`name`, `description`)
- Structured the procedure with clear steps
- Defined trigger phrases
- Set up the expected output format

### 4. Test the Generated Skill

Still in OpenCode, try:
```
Use the security reviewer skill on the sample code in ../lab-03-agent-workflow/sample-project/
```

### 5. Iterate on It

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

A sample runbook is provided:

```bash
cat docs/server-troubleshooting-guide.md
```

This is a typical IT troubleshooting guide for Linux servers. We will turn it into a skill.

### 2. Use the Skill Creator with Document Input

```bash
opencode
```

Then:
```
/skill-creator Create a skill from the document at docs/server-troubleshooting-guide.md.
The skill should guide users through the troubleshooting steps interactively,
asking diagnostic questions and recommending actions based on the answers.
```

### 3. Try It Out

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
-> [Lab 03: Building an Agent Workflow](../lab-03-agent-workflow/README.md)
