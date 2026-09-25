# Lab 05: Discover and Use a Community Skill (CLI)

## Objective

Use the `find-skills` skill from Lab 4 to discover a community **science**
skill -- an astronomy toolkit -- audit it with SkillSpector, install it, and use it in a
new OpenCode session to compute a real astronomical quantity (the Moon's phase).

**Time estimate:** 20 minutes

> Treat community skills as untrusted instructions. Review the recommendation and
> audit the skill before copying it into `.opencode/skills/`.

## Steps

### 1. Start a fresh session

```bash
cd /root/labs
opencode
```

Ask OpenCode:

```
Load all local skills. Use find-skills to find a community skill for astronomy or astronomical calculations in Python. Show me the top two recommendations, their repository URLs, and what each skill does. Do not install anything yet.
```

Choose a recommendation that is clearly relevant to the lab. Record its repository
URL and skill name.

> **Expected pick:** at time of writing the strongest match is **astropy-astronomy**
> from `https://github.com/jaechang-hits/sciagent-skills`, a wrapper around the
> [Astropy](https://www.astropy.org/) scientific library. Rankings shift over time,
> so any clearly relevant astronomy skill is fine.

### 2. Review before installing

Ask OpenCode:

```
Before installing the recommended skill, explain what files it will add, what commands it may ask an agent to run, and what permissions or external services it appears to need.
```

Only continue if the scope is appropriate for this workshop.

### 3. Install and expose the skill to OpenCode

Replace the placeholders with the URL and skill name you selected:

```bash
npx skills add <REPOSITORY_URL> --skill <SKILL_NAME> --agent opencode -y
cp -r .agents/skills/<SKILL_NAME> .opencode/skills/<SKILL_NAME>
```

### 4. Check the skill before you run it

A skill injects instructions into your agent -- read it and scan it **before** it acts.

Read what you installed:

```bash
cat .opencode/skills/<SKILL_NAME>/SKILL.md
```

Then run a static scan:

```bash
skillspector scan .opencode/skills/<SKILL_NAME>/ --no-llm --format json
```

Review the score, recommendation, and findings. Do not use a skill with a
`DO_NOT_INSTALL` recommendation for this exercise. For `astropy-astronomy` you
should see passing audits and only a scientific-Python dependency (`astropy`).

### 5. Start a new session and use it

Exit and restart OpenCode so it discovers the new skill:

```text
/quit
```

```bash
cd /root/labs
opencode
```

Astropy is the skill's one dependency. From inside the OpenCode session, ask it to install:

```
Run: pip install astropy
```

Then ask it to do some science:

```
Load all local skills. Use the newly installed astronomy skill to compute the Moon's phase and illuminated fraction for 2026-09-25 (UTC). Show the `astropy` code and write it to moon_phase.py. Do not run anything until I approve the script.
```

Review the proposed script. Approve it, then have OpenCode run it:

```bash
python moon_phase.py
```

Verify the reported illuminated fraction against a published Moon-phase almanac for
that date. A close match is your proof the skill worked.

### 6. Reflect

Record what the skill did, what SkillSpector found, and why a new session was needed.

## Key concepts

- Discover before installing.
- Read the `SKILL.md` and audit it before you let the skill act.
- Start a new session after adding a skill.
- Keep a human approval step before running generated code.
- Verify scientific output against an independent source.

## Next

You have completed the HackShack OpenCode workshop.
