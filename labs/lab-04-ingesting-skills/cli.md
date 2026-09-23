# Lab 04: Ingesting Community Skills (CLI)

## Objective
Install a community skill from the open Skills Registry, verify it with instrospect, and use it to discover more skills -- all from the command line.

**Time estimate:** 20 minutes

## Background

So far you have hand-crafted skills and generated them with `/skill-creator`. But there is a growing open-source ecosystem of pre-built skills at the **Skills Registry** ([www.skills.sh](https://www.skills.sh)), maintained by Vercel Labs. These are community-contributed, version-controlled skill packages you can install with a single command.

> **Naming note**: The registry's domain is `skills.sh` -- that is the website address, not a shell script. The CLI tool is `npx skills`.

The skill we will install -- **find-skills** from `vercel-labs/skills` -- is the most popular skill on the registry (3M+ installs, 30K+ GitHub stars). It helps your AI agent discover and install *other* skills from the ecosystem.

> **Trust but verify**: Community skills are powerful, but they inject instructions into your AI. Always audit external skills with instrospect before using them in production.

---

## Steps

### 1. Explore the Skills Registry

The Skills Registry at [www.skills.sh](https://www.skills.sh) is a public directory of agent skills -- think of it like npm or PyPI, but for AI agent instructions. Each skill is a SKILL.md file hosted on GitHub, with metadata, install counts, and security audit results.

Ask OpenCode about it:

```bash
cd /root/labs
opencode
```

Then:

```
What is the Vercel Labs Skills Registry and how do community skills work with OpenCode?
```

Key things to notice about the ecosystem:
- Skills are just markdown files -- no code is executed on install
- They work across agents (Claude Code, Cursor, Codex, OpenCode, and more)
- Each skill has install counts, GitHub stars, and security audit badges
- The CLI tool is `npx skills` (add, find, list)

Exit OpenCode when done:

```
/quit
```

### 2. Install the find-skills Skill

The Skills CLI (`npx skills`) is the package manager for the ecosystem:

```bash
cd /root/labs
npx skills add https://github.com/vercel-labs/skills --skill find-skills --agent opencode -y
```

The Skills CLI installs to `.agents/skills/` (its own convention), but OpenCode reads from `.opencode/skills/`. Copy the skill to where OpenCode can find it:

```bash
cp -r .agents/skills/find-skills .opencode/skills/find-skills
```

> **Why the copy?** The Skills CLI supports 70+ agents and uses a shared `.agents/skills/` directory. OpenCode scans `.opencode/skills/` at the project root. A simple copy bridges the gap.

### 3. Verify the Installation

Check that the skill is in the right place:

```bash
cat .opencode/skills/find-skills/SKILL.md
```

You should see the skill's YAML frontmatter (name, description) and its instruction body. Read through it -- this is what gets injected into the AI when the skill activates.

### 4. Audit with instrospect -- Static Scan

Before trusting this community skill, run a static analysis:

```bash
python3 /opt/instrospect/src/skill_review.py skill .opencode/skills/find-skills/ --json
```

> **Policy warning**: If running this inside OpenCode (rather than a plain terminal), accept the authorization warning for `/opt/instrospect/`.
>
> **Stub notice**: If instrospect shows a warning about not being available, the environment was built without HPE VPN access. In that case, read through the steps to understand the audit workflow -- the concepts still apply.

Review the findings:
- Does it have a proper provenance header?
- Are there any hardcoded secrets or dangerous commands?
- What is the overall quality score?

### 5. Audit with instrospect -- Adversarial Sandbox

Run the behavioral test to see how the skill holds up against adversarial inputs:

```bash
# Simulated mode (no LLM cost, tests the policy engine)
python3 /opt/instrospect/src/sandbox/bootstrap.py --simulated --skill .opencode/skills/find-skills/

# Live mode with a Zen free model (tests real LLM behavior)
python3 /opt/instrospect/src/sandbox/bootstrap.py --skill .opencode/skills/find-skills/ \
    --model opencode/nemotron-3-ultra-free
```

### 6. Read the Audit Report

```bash
cat .opencode/skills/find-skills/sandbox-output/sandbox-report.md
```

Compare the audit scores to the skills you created in Lab 2:

| Skill | Source | Expected Score Range |
|-------|--------|---------------------|
| greeter (Lab 2A) | Hand-crafted | 40-60 (no provenance header) |
| security-reviewer (Lab 2B) | /skill-creator | 50-70 |
| find-skills (Lab 4) | Community (vercel-labs) | Varies -- check it! |

### 7. Use the Skill

Launch OpenCode and load all skills:

```bash
opencode
```

```
Load all local skills
```

> **Known behavior**: OpenCode may show a warning like `Skill "find-skills" not found` in its skill registry. This is expected -- skills created or copied mid-session are not automatically registered. However, the "Load all local skills" prompt causes the model to read the SKILL.md files directly, and the skill **will work** despite the warning. A fix is pending upstream.

Now use find-skills to discover other skills:

```
Find me a skill for writing unit tests
```

Or:

```
Is there a skill for database migrations?
```

The find-skills skill will search the Skills Registry and recommend options with install counts and quality indicators.

### 8. Install Another Skill (Optional)

If find-skills recommends something interesting, exit OpenCode and install it:

```bash
npx skills add <package-url> --skill <skill-name> --agent opencode -y
cp -r .agents/skills/<skill-name> .opencode/skills/<skill-name>
```

Then audit it with instrospect before using it:

```bash
python3 /opt/instrospect/src/skill_review.py skill .opencode/skills/<skill-name>/ --json
```

### 9. Non-Interactive Audit Pipeline

You can script the entire install-copy-audit-use workflow:

```bash
# Install + copy to OpenCode
npx skills add https://github.com/vercel-labs/skills --skill find-skills --agent opencode -y
cp -r .agents/skills/find-skills .opencode/skills/find-skills

# Audit
python3 /opt/instrospect/src/skill_review.py skill .opencode/skills/find-skills/ --json

# Use (non-interactively)
opencode run "Load all local skills. Then find me a skill for writing unit tests." \
    --model opencode/mimo-v2.5-free
```

This pattern -- install, audit, use -- is the recommended workflow for CI/CD integration.

---

## Key Concepts

| Concept | Takeaway |
|---------|----------|
| **Skills Registry** | Open ecosystem of community-contributed agent skills ([www.skills.sh](https://www.skills.sh)) |
| **`npx skills add`** | Install skills from GitHub repositories |
| **Audit before use** | Always run instrospect on external skills |
| **Static + behavioral** | Static scan catches structure issues; sandbox catches behavioral issues |
| **Trust signals** | Install count, GitHub stars, security audits on the registry |
| **find-skills meta-skill** | A skill that helps discover other skills |
| **`opencode run`** | Non-interactive execution for scripting and CI/CD |

## Challenge: Compare Audit Scores

Run instrospect on ALL skills in your `.opencode/skills/` directory and compare:

```bash
for d in .opencode/skills/*/; do
    echo "=== $d ==="
    python3 /opt/instrospect/src/skill_review.py skill "$d" --json 2>&1 | tail -5
done
```

Which skill scores highest? What patterns make a skill score well?

---

## Congratulations!

You have completed all four labs in the HackShack OpenCode workshop. You now know how to:

1. **Lab 1** -- Use OpenCode from the terminal (TUI and non-interactive modes)
2. **Lab 2** -- Create custom skills (hand-craft, /skill-creator, from documents)
3. **Lab 3** -- Build multi-step agent workflows
4. **Lab 4** -- Ingest and audit community skills from the open ecosystem

### What is Next?

- Explore more skills at [www.skills.sh](https://www.skills.sh)
- Build skills from your own team's runbooks and documentation
- Set up instrospect in your CI/CD pipeline to audit skills automatically
- Share your best skills back to the community
- Use `opencode run` to integrate agent workflows into your automation
