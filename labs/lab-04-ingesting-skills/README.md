# Lab 04: Ingesting Community Skills

## Objective
Install a community skill from the open Skills Registry, verify it with instrospect, and use it to discover more skills.

**Time estimate:** 20 minutes

## Background

So far you have hand-crafted skills and generated them with `/skill-creator`. But there is a growing open-source ecosystem of pre-built skills at the **Skills Registry** ([www.skills.sh](https://www.skills.sh)), maintained by Vercel Labs. These are community-contributed, version-controlled skill packages you can install with a single command.

> **Naming note**: The registry's domain is `skills.sh` -- that is the website address, not a shell script. The CLI tool is `npx skills`.

The skill we will install -- **find-skills** from `vercel-labs/skills` -- is the most popular skill on the registry (3M+ installs, 30K+ GitHub stars). It helps your AI agent discover and install *other* skills from the ecosystem.

> **Trust but verify**: Community skills are powerful, but they inject instructions into your AI. Always audit external skills with instrospect before using them in production.

## Steps

See the **Lab 4** tab in the tutorial page for full step-by-step instructions (Web and CLI variants).

### Summary

1. Explore the Skills Registry ecosystem
2. Install the `find-skills` skill with `npx skills add`
3. Copy it to `.opencode/skills/` so OpenCode can discover it
4. Verify the installation
5. Audit with instrospect (static scan)
6. Compare audit scores across all your skills
7. Use the skill to discover more community skills

## Key Concepts

- **Skills Registry** is an open ecosystem of community-built AI skills
- `npx skills add` installs skills; `--agent opencode` targets OpenCode
- Installed skills land in `.agents/skills/` and must be copied to `.opencode/skills/`
- **instrospect** audits skill quality and safety before production use
- Always verify external skills -- they inject instructions into your AI agent

## Congratulations!

You have completed all four labs! You now know how to:
- Use OpenCode with free cloud AI models (Lab 1)
- Create custom skills by hand and with /skill-creator (Lab 2)
- Build multi-step agent workflows (Lab 3)
- Ingest, audit, and use community skills (Lab 4)
