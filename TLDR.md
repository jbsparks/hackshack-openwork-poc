# TLDR -- Local Bootstrap

Prerequisites: Docker running, Git installed. HPE VPN for instrospect only.

## Full build (with instrospect)

```bash
git clone <this-repo> && cd HackShack
./build.sh                          # or: GHE_TOKEN=ghp_xxx ./build.sh
docker compose up -d
```

## Quick build (skip instrospect, Lab 2D will be limited)

```bash
git clone <this-repo> && cd HackShack
mkdir -p instrospect/src/sandbox
echo 'import sys; print("[WARN] instrospect not available -- built without HPE VPN. See Lab 2 Part D for details."); sys.exit(1)' > instrospect/src/skill_review.py
echo 'import sys; print("[WARN] instrospect not available -- built without HPE VPN. See Lab 2 Part D for details."); sys.exit(1)' > instrospect/src/sandbox/bootstrap.py
docker compose up -d
```

## Verify

```bash
docker exec -it hackshack-lab bash tests/validate-env.sh
```

## Use

- **Tutorial page**: http://localhost:8080 (OpenCode + formatted lab docs side by side)
- **OpenCode only**: http://localhost:5178 (standalone web UI)
- **CLI**: `docker exec -it hackshack-lab bash` then `cd labs && opencode`

## Model

Uses OpenCode Zen free cloud models -- no API key, no local GPU, no cost.
Default: mimo-v2.5-free. Run `/models` inside OpenCode to see all options.

### GitHub Copilot (optional, for faster testing)

If you have a `GITHUB_TOKEN` with Copilot access, pass it at startup:

```bash
GITHUB_TOKEN=gho_xxx docker compose up -d
```

The entrypoint injects the token into `opencode.json` at runtime. Select
`copilot/gpt-4o` from the model picker or pass `--model copilot/gpt-4o` on
the CLI. Without the token, only Zen free models are available.

## Skills

Skills require YAML frontmatter with `name` and `description` to be
discovered. Without `description`, OpenCode silently ignores the skill.

```markdown
---
name: my-skill
description: What it does and when to trigger it.
---

# My Skill

(instructions here)
```

Skills live in `.opencode/skills/<name>/SKILL.md`. OpenCode loads skills at
startup -- restart the session after creating a new skill.

## Tutorial Structure

The tutorial page (port 8080) has tiered tabs:

| Primary Tab | Sub-tabs | Files |
|-------------|----------|-------|
| Welcome | (none) | `labs/README.md` |
| Lab 1 | Web / CLI | `lab-01-getting-started/web.md`, `cli.md` |
| Lab 2 | Web / CLI | `lab-02-skills/web.md`, `cli.md` |
| Lab 3 | Web / CLI | `lab-03-agent-workflow/web.md`, `cli.md` |
| Lab 4 | Web / CLI | `lab-04-ingesting-skills/web.md`, `cli.md` |

Web is the default sub-tab. The original `README.md` files in each lab dir
are kept for reference but no longer served by the tutorial tabs.

## Tear down

```bash
docker compose down
```

## First run timing

| Step | Duration |
|------|----------|
| `build.sh` (image build) | ~5 min |
| Tutorial + Web UI startup | ~30 sec |

Total first run: ~5 min. Subsequent starts: ~30 sec.

## Image stats

| Metric | Value |
|--------|-------|
| Image size | 1.6 GB |
| RAM requirement | 2 GB |
| Ports | 8080 (tutorial), 5178 (OpenCode) |
| Validation checks | 26 pass, 0 fail, 1 warn (instrospect stub) |
