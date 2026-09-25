# Lab 04: Ingesting Community Skills (Web UI)

## Objective
Install a community skill from the open Skills Registry, verify it with SkillSpector, and use it to discover more skills -- all from the web interface.

**Time estimate:** 20 minutes

## Background

So far you have hand-crafted skills and generated them with `/skill-creator`. But there is a growing open-source ecosystem of pre-built skills at the **Skills Registry** ([www.skills.sh](https://www.skills.sh)), maintained by Vercel Labs. These are community-contributed, version-controlled skill packages you can install with a single command.

> **Naming note**: The registry's domain is `skills.sh` -- that is the website address, not a shell script. The CLI tool is `npx skills`.

The skill we will install -- **find-skills** from `vercel-labs/skills` -- is the most popular skill on the registry (3M+ installs, 30K+ GitHub stars). It helps your AI agent discover and install *other* skills from the ecosystem.

> **Trust but verify**: Community skills are powerful, but they inject instructions into your AI. Always audit external skills with SkillSpector before using them in production.

---

## Steps

### 1. Explore the Skills Registry

The Skills Registry at [www.skills.sh](https://www.skills.sh) is a public directory of agent skills -- think of it like npm or PyPI, but for AI agent instructions. Each skill is a SKILL.md file hosted on GitHub, with metadata, install counts, and security audit results.

Ask OpenCode:

```
What is the Vercel Labs Skills Registry and how do community skills work with OpenCode?
```

Key things to notice about the ecosystem:
- Skills are just markdown files -- no code is executed on install
- They work across agents (Claude Code, Cursor, Codex, OpenCode, and more)
- Each skill has install counts, GitHub stars, and security audit badges
- The CLI tool is `npx skills` (add, find, list)

### 2. Install the find-skills Skill

The Skills CLI (`npx skills`) is the package manager for the ecosystem. Ask OpenCode to install the find-skills skill:

```
Run this command: npx skills add https://github.com/vercel-labs/skills --skill find-skills --agent opencode -y
```

The Skills CLI installs to `.agents/skills/` (its own convention), but OpenCode reads from `.opencode/skills/`. Copy the skill to where OpenCode can find it:

```
Run this command: cp -r .agents/skills/find-skills .opencode/skills/find-skills
```

> **Why the copy?** The Skills CLI supports 70+ agents and uses a shared `.agents/skills/` directory. OpenCode scans `.opencode/skills/` at the project root. A simple copy bridges the gap.

### 3. Verify the Installation

Check that the skill is in the right place:

```
Show me the contents of .opencode/skills/find-skills/SKILL.md
```

You should see the skill's YAML frontmatter (name, description) and its instruction body. Read through it -- this is what gets injected into the AI when the skill activates.

### 4. Audit with SkillSpector -- static scan

Before trusting this community skill, run:

```
skillspector scan .opencode/skills/find-skills/ --no-llm --format json
```

Review the risk score, recommendation, provenance, dangerous commands, and dependency findings.

Save a report:

```
skillspector scan .opencode/skills/find-skills/ --no-llm --format markdown --output find-skills-report.md
```

SkillSpector is a static scanner, not a behavioral sandbox.

---

## Key Concepts

| Concept | Takeaway |
|---------|----------|
| **Skills Registry** | Open ecosystem of community-contributed agent skills ([www.skills.sh](https://www.skills.sh)) |
| **`npx skills add`** | Install skills from GitHub repositories |
| **Audit before use** | Always run SkillSpector on external skills |
| **Static + behavioral** | Static scan catches structure issues; sandbox catches behavioral issues |
| **Trust signals** | Install count, GitHub stars, security audits on the registry |
| **find-skills meta-skill** | A skill that helps discover other skills |

## Challenge: Compare Audit Scores

Run SkillSpector on ALL skills in your `.opencode/skills/` directory and compare:

```
Run this command: for d in .opencode/skills/*/; do echo "=== $d ===" && skillspector scan "$d" --no-llm --format json; done
```

Which skill scores highest? What patterns make a skill score well?

---

## Congratulations!

You have completed all four labs in the HackShack OpenCode workshop. You now know how to:

1. **Lab 1** -- Use OpenCode with free cloud AI models
2. **Lab 2** -- Create custom skills (hand-craft, /skill-creator, from documents)
3. **Lab 3** -- Build multi-step agent workflows
4. **Lab 4** -- Ingest and audit community skills from the open ecosystem

### What is Next?

- Explore more skills at [www.skills.sh](https://www.skills.sh)
- Build skills from your own team's runbooks and documentation
- Set up SkillSpector in your CI/CD pipeline to audit skills automatically
- Share your best skills back to the community
