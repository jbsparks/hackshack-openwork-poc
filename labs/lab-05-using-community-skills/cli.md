# Lab 05: Discover and Use a Community Skill (CLI)

## Objective

Use the `find-skills` skill you installed in Lab 4 to discover a community **science**
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

### 3. Install the selected skill

Replace the placeholders with the URL and skill name you selected:

```bash
npx skills add crazymsn/academic-skills@astropy --skill astropy --agent opencode -y
```

Bridge the Skills CLI directory to OpenCode:

```bash
cp -r .agents/skills/astropy .opencode/skills/astropy
```

### 4. Check the skill before you run it

A skill injects instructions into your agent -- read it and scan it **before** it acts.

Read what you installed:

```bash
cat .opencode/skills/astropy/SKILL.md
```

Then run a static scan:

```bash
skillspector scan .opencode/skills/astropy/ --no-llm --format json
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

The output should look like this:

```bash
Moon phase for 2026-09-25 00:00 UTC
==============================================
  Phase name:          Waxing Gibbous
  Illuminated:         96.7%
  Phase angle:         +159.09 deg
  Sun-Moon elongation: 159.06 deg
  Waning/Waxing:       waxing

  Geocentric ecliptic longitude
    Sun:               181.9538 deg
    Moon:              341.0395 deg

  Earth-Sun distance:  1.003012 AU
  Earth-Moon distance: 386,730.9 km
```

Verify the reported illuminated fraction against a published Moon-phase almanac for
that date. A close match is your proof the skill worked.

### 6. Reflect

Answer:

- Did the skill do what its description promised?
- What did SkillSpector flag?
- Did the fresh session discover the skill automatically?
- What would you check before using this skill in a production repository?

## Key concepts

| Concept | Takeaway |
|---|---|
| Discover | Use `find-skills` to search before installing. |
| Review | Understand scope and requested capabilities first. |
| Audit | Read the `SKILL.md` and run SkillSpector before the skill acts. |
| Refresh | Start a new session after adding a skill. |
| Human control | Approve generated code before running it. |
| Verify | Check scientific output against an independent source. |

## Next

You have completed the HackShack OpenCode workshop.
