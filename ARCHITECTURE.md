# HackShack OpenCode Workshop -- Architecture Document

This document describes the architecture of the HackShack OpenCode tutorial environment and how it integrates with the HPE Workshops-on-Demand (WoD) infrastructure.

---

## 1. High-Level Overview

**IDEA**: The HackShack Agentic workshop is a Docker-based, self-contained lab environment that teaches students to use OpenCode (an AI coding assistant) and build AI skills. Each student gets an isolated container with two web services: the **Tutorial Page** (lab docs + embedded OpenCode) and the **OpenCode Web UI** (standalone). The container requires only outbound HTTPS to reach free Zen cloud models -- **no** local GPU, **no** API keys, **no** HPE proprietary dependencies.

```mermaid
graph TB
    subgraph "WoD Backend Server"
        JH[JupyterHub]
        PM[procmail-action.sh]
        CS[create-appliance.sh]
        RS[reset-appliance.sh]
        CL[cleanup-appliance.sh]
    end

    subgraph "Per-Student Container"
        EP[entrypoint.sh]
        DS[docs-server.py :8080]
        OC[opencode web :5178]
        FS["/root/labs/ filesystem"]
    end

    subgraph "External Services"
        ZEN[Zen Free Models API<br/>opencode.ai/zen/v1]
        CP[GitHub Copilot API<br/>api.githubcopilot.com]
    end

    Student((Student Browser)) -->|"http://host:TUTORIAL_PORT"| DS
    Student -->|"http://host:OW_PORT"| OC
    JH -->|"Notebook cell"| Student

    PM -->|"CREATE"| CS
    PM -->|"RESET"| RS
    PM -->|"CLEANUP"| CL
    CS -->|"docker run"| EP
    CL -->|"docker rm"| EP

    EP --> DS
    EP --> OC
    OC -->|"HTTPS"| ZEN
    OC -.->|"HTTPS (optional)"| CP
    OC --> FS
    DS --> FS
```

---

## 2. Container Architecture

### 2.1 Docker Image Layers

The image is built from Ubuntu 22.04 and installs all dependencies in a single build. No volumes are mounted -- the container is fully self-contained and disposable.

```mermaid
graph TB
    subgraph "Docker Image (1.6 GB)"
        L1["Ubuntu 22.04 base"]
        L2["System packages<br/>curl, git, jq, python3, vim, nano, build-essential"]
        L3["Zscaler CA cert<br/>config/zscaler-root-ca.crt"]
        L4["Node.js 22 LTS<br/>via NodeSource"]
        L5["opencode-ai (npm -g)"]
        L6["HPE instrospect<br/>/opt/instrospect/ or stub"]
        L7["OpenCode config<br/>/root/.config/opencode/config.json"]
        L8["Lab materials<br/>/root/labs/ (git init)"]
        L9["Validation tests<br/>/root/tests/validate-env.sh"]
        L10["xdg-open stub<br/>/usr/bin/xdg-open (exit 0)"]
    end

    L1 --> L2 --> L3 --> L4 --> L5 --> L6 --> L7 --> L8 --> L9 --> L10

    style L5 fill:#01A982,color:#fff
    style L6 fill:#f9a825,color:#000
```

| Layer | Purpose | Size Impact |
|-------|---------|-------------|
| Ubuntu 22.04 | Base OS | ~77 MB |
| System packages | Build tools, editors, utilities | ~200 MB |
| Node.js 22 | JavaScript runtime for OpenCode | ~100 MB |
| opencode-ai (npm) | AI coding assistant CLI + web UI | ~800 MB |
| instrospect | HPE Skill auditing tool (or stub) | ~5 MB |
| Lab materials | Markdown docs, sample code, configs | ~1 MB |

### 2.2 Build Variants

```mermaid
graph LR
    A{{"HPE VPN<br/>available?"}}
    A -->|Yes| B["./build.sh<br/>Clones instrospect from<br/>github.hpe.com via SSH/HTTPS"]
    A -->|No| C["make build-quick<br/>Creates instrospect stub"]
    B --> D["Full image<br/>Lab 2D: instrospect audit"]
    C --> E["Stub image<br/>Lab 2D: limited<br/>(prints warning + exit 1)"]

    style D fill:#01A982,color:#fff
    style E fill:#f9a825,color:#000
```

The `build.sh` script tries three clone methods in order: HTTPS with `GHE_TOKEN`, SSH key, then HTTPS with git credential manager. If all fail, the build aborts with instructions. The `make build-quick` target creates a Python stub that prints a warning and exits non-zero, allowing all other labs to work without VPN access.

### 2.3 Instrospect Stub Detection

The Dockerfile uses a grep-based check (not exact first-line match) to distinguish real instrospect from the stub:

```
if [ -f /opt/instrospect/src/skill_review.py ] && \
   ! grep -q "instrospect not available" /opt/instrospect/src/skill_review.py; then
    # Real instrospect -- symlink to /usr/local/bin
else
    # Stub -- print note during build
fi
```

---

## 3. Container Startup Sequence

The entrypoint script orchestrates startup of both services inside the container.

```mermaid
sequenceDiagram
    participant Docker
    participant EP as entrypoint.sh
    participant DS as docs-server.py
    participant OC as opencode web
    participant ZEN as Zen API

    Docker->>EP: ENTRYPOINT
    EP->>EP: Banner + GITHUB_TOKEN sed inject
    Note over EP: sed replaces ${GITHUB_TOKEN}<br/>in /root/labs/opencode.json

    EP->>DS: Start (background, :8080)
    DS-->>EP: Serving tutorial.html + /docs/

    EP->>OC: Start (background, :5178)
    Note over EP: BROWSER=none opencode web<br/>--port 5178 --hostname 0.0.0.0

    loop Poll up to 60s
        EP->>OC: curl localhost:5178
        OC-->>EP: 200 OK
    end

    EP->>EP: Print "Environment Ready!" banner
    EP->>Docker: exec CMD (bash)

    Note over OC,ZEN: AI requests flow over HTTPS<br/>on student's first prompt
```

### 3.1 Environment Variables

| Variable | Source | Purpose |
|----------|--------|---------|
| `GITHUB_TOKEN` | docker-compose / WoD | Optional: Copilot API access for faster testing |
| `DOCS_PORT` | Default: 8080 | Tutorial docs server port |
| `OPENCODE_PORT` | Default: 5178 | OpenCode web UI port |
| `SSL_CERT_FILE` | Dockerfile | TLS cert path for Bun/Node |
| `NODE_EXTRA_CA_CERTS` | Dockerfile | Additional CA certs (Zscaler) |
| `STUDENT_NUM` | WoD create script | Student number for port mapping |
| `STUDENT_PWD` | WoD create script | Student password (passed but unused currently) |

### 3.2 Token Injection

OpenCode does not resolve environment variables in its JSON config. The entrypoint uses `sed` to substitute `${GITHUB_TOKEN}` in `/root/labs/opencode.json` at runtime:

```bash
sed -i "s|\${GITHUB_TOKEN}|${GITHUB_TOKEN}|g" /root/labs/opencode.json
```

If no token is provided, the placeholder remains and only built-in Zen free models are available.

---

## 4. Network Topology

### 4.1 Local Development

```mermaid
graph LR
    subgraph "Developer Machine"
        Browser((Browser))
        PW[Playwright<br/>record-demo.js]
    end

    subgraph "Docker Container (hackshack-lab)"
        DS["docs-server.py<br/>:8080"]
        OC["opencode web<br/>:5178"]
    end

    subgraph "Internet"
        ZEN["opencode.ai/zen/v1<br/>(Zen Free Models)"]
        GHC["api.githubcopilot.com<br/>(Copilot, optional)"]
    end

    Browser -->|":8080"| DS
    Browser -->|":5178"| OC
    PW -->|":8080"| DS
    OC -->|"HTTPS"| ZEN
    OC -.->|"HTTPS"| GHC
```

Ports **8080** and **5178** are mapped 1:1 from host to container.

### 4.2 WoD Production (Multi-Student)

```mermaid
graph TB
    subgraph "WoD Backend Server"
        JH[JupyterHub]
        subgraph "Student 1"
            C1["Container<br/>openwork-student1"]
            P1["8081:8080<br/>5179:5178"]
        end
        subgraph "Student 2"
            C2["Container<br/>openwork-student2"]
            P2["8082:8080<br/>5180:5178"]
        end
        subgraph "Student N"
            CN["Container<br/>openwork-studentN"]
            PN["8080+N:8080<br/>5178+N:5178"]
        end
    end

    S1((Student 1)) -->|":8081"| C1
    S2((Student 2)) -->|":8082"| C2
    SN((Student N)) -->|":8080+N"| CN

    JH -->|"Notebook"| S1
    JH -->|"Notebook"| S2
    JH -->|"Notebook"| SN

    C1 & C2 & CN -->|"HTTPS"| ZEN["Zen Free Models"]

    style JH fill:#01A982,color:#fff
```

Each student gets unique ports: `TUTORIAL_PORT = 8080 + STUDENT_NUM` and `OW_PORT = 5178 + STUDENT_NUM`. Containers are named `openwork-student${N}` for lifecycle management.

---

## 5. WoD Integration -- __Work-in-Progress__

### 5.1 Integration Architecture

The WoD platform uses JupyterHub as its student-facing entry point. Each workshop provides a thin Jupyter notebook that bootstraps the student into the real lab environment. For this workshop, the notebook is a launcher -- it calculates the student's unique URLs and directs them to the OpenCode tutorial page.

```mermaid
sequenceDiagram
    actor Student
    participant Email as WoD Email System
    participant PM as procmail-action.sh
    participant CS as create-appliance.sh
    participant Docker
    participant JH as JupyterHub
    participant NB as 0-ReadMeFirst.ipynb
    participant Tutorial as Tutorial Page :8080+N

    Student->>Email: Register for workshop
    Email->>PM: Incoming registration
    PM->>CS: CREATE student1 password123
    CS->>Docker: docker run hackshack-openwork<br/>-p 8081:8080 -p 5179:5178
    Docker-->>CS: Container started
    CS->>CS: Poll until tutorial page ready

    Student->>JH: Log in to JupyterHub
    JH->>NB: Open 0-ReadMeFirst.ipynb
    NB->>NB: Calculate port from $USER
    NB-->>Student: "Your Tutorial URL:<br/>http://host:8081"
    Student->>Tutorial: Open in new browser tab
    Note over Student,Tutorial: Student works entirely<br/>in the Tutorial Page from here
```

### 5.2 WoD Configuration Files

| File | Purpose |
|------|---------|
| `WKSHP-OpenWork/wod.conf` | Workshop metadata: name, description, duration (105 min), category (AI), backend flag |
| `WKSHP-OpenWork/0-ReadMeFirst.ipynb` | Launcher notebook: calculates student-specific URLs, displays link, health check cell |
| `wod-scripts/create-appliance.sh` | Called on student registration: starts per-student container with unique port mapping |
| `wod-scripts/cleanup-appliance.sh` | Called on session expiry: `docker rm -f` the student's container |
| `wod-scripts/reset-appliance.sh` | Called on reset request: removes container, then re-runs create |

### 5.3 WoD Template Variables

The notebook uses WoD template variables that are substituted at deploy time:

| Variable | Substituted With |
|----------|-----------------|
| `{{ BRANDINGLOGO }}` | HPE HackShack logo HTML |
| `{{ YOURWKSHPBE }}` | Backend server hostname |
| `{{ YOURWORKSHOPDESC }}` | Workshop description from wod.conf |

### 5.4 Appliance Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Registered: Student registers via email
    Registered --> Creating: procmail triggers CREATE
    Creating --> Running: Container started + health check passed
    Running --> Running: Student works through labs
    Running --> Resetting: Student requests reset
    Resetting --> Creating: destroy + re-create
    Running --> Expired: Time limit reached (105 min)
    Expired --> Cleaning: procmail triggers CLEANUP
    Cleaning --> [*]: Container removed
```

---

## 6. Tutorial Page Architecture

The tutorial page is the primary student interface. It splits the browser into two halves: OpenCode on the left, formatted lab documentation on the right.

```mermaid
graph TB
    subgraph "Browser Window"
        subgraph "Left Half (50%)"
            IFRAME["iframe src=localhost:5178<br/>(OpenCode Web UI)"]
        end
        subgraph "Right Half (50%)"
            PT["Primary Tabs<br/>Welcome | Lab 1 | Lab 2 | Lab 3 | Lab 4"]
            ST["Sub-tabs (Labs only)<br/>WEB (default) | CLI"]
            DC["Doc Content<br/>(Rendered Markdown)"]
        end
    end

    subgraph "docs-server.py (:8080)"
        TH["/ -> tutorial.html"]
        MD["/docs/path -> /root/labs/path"]
    end

    IFRAME -->|"direct connection"| OC["opencode web :5178"]
    PT --> ST --> DC
    DC -->|"fetch /docs/lab-01-getting-started/web.md"| MD
    TH -->|"serves"| PT

    style PT fill:#01A982,color:#fff
    style ST fill:#e8f5e9,color:#333
```

### 6.1 Tab Structure

| Primary Tab | Sub-tabs | Markdown Source |
|-------------|----------|----------------|
| Welcome | (none) | `labs/README.md` |
| Lab 1 | Web / CLI | `lab-01-getting-started/web.md` or `cli.md` |
| Lab 2 | Web / CLI | `lab-02-skills/web.md` or `cli.md` |
| Lab 3 | Web / CLI | `lab-03-agent-workflow/web.md` or `cli.md` |
| Lab 4 | Web / CLI | `lab-04-ingesting-skills/web.md` or `cli.md` |

The "Web" sub-tab is selected by default. Each sub-tab loads a different markdown file -- the Web variant contains instructions referencing the OpenCode web UI (click buttons, use the composer), while the CLI variant has equivalent terminal commands.

### 6.2 Content Rendering Pipeline

```mermaid
graph LR
    A["web.md / cli.md<br/>(raw markdown)"] -->|"fetch /docs/..."| B["docs-server.py<br/>(rewrites path)"]
    B -->|"serves from /root/labs/"| C["tutorial.html<br/>(JavaScript)"]
    C -->|"marked.parse()"| D["Rendered HTML<br/>(in #doc-content div)"]

    style B fill:#01A982,color:#fff
```

The docs-server.py is a minimal Python HTTP server (22 lines) that:
- Serves `tutorial.html` at `/` and `/index.html`
- Rewrites `/docs/path` to `/path` (relative to `/root/labs/`)
- Lets the browser fetch lab markdown files via the `/docs/` prefix

Markdown is rendered client-side using the `marked` library loaded from CDN.

---

## 7. OpenCode Configuration

### 7.1 Two Config Files

The project has two OpenCode config files serving different purposes:

```mermaid
graph LR
    subgraph "Global Config"
        GC["config/opencode.json<br/>Copied to /root/.config/opencode/config.json"]
        GC_CONTENT["model: opencode/mimo-v2.5-free<br/>instructions: INSTRUCTIONS.md"]
    end

    subgraph "Project Config"
        PC["labs/opencode.json<br/>In /root/labs/ (project root)"]
        PC_CONTENT["model: opencode/mimo-v2.5-free<br/>+ Copilot provider (optional)<br/>instructions: INSTRUCTIONS.md"]
    end

    GC --> GC_CONTENT
    PC --> PC_CONTENT

    Note["Project config overrides global.<br/>Copilot provider only activates<br/>if GITHUB_TOKEN is injected."]

    style GC fill:#e3f2fd,color:#333
    style PC fill:#01A982,color:#fff
```

| Config | Path in Container | Contents |
|--------|-------------------|----------|
| Global | `/root/.config/opencode/config.json` | Minimal: model + instructions only |
| Project | `/root/labs/opencode.json` | Model + instructions + optional Copilot provider |

### 7.2 Model Hierarchy

```mermaid
graph TB
    DEFAULT["Default: opencode/mimo-v2.5-free<br/>(built-in, free, fast, no API key)"]
    COPILOT["Optional: copilot/gpt-4o<br/>(requires GITHUB_TOKEN)"]
    OTHER["Other Zen models<br/>(nemotron, etc. -- may be slow)"]

    DEFAULT -->|"Always available"| USE["Student uses model"]
    COPILOT -.->|"If token provided"| USE
    OTHER -.->|"Via /models command"| USE

    style DEFAULT fill:#01A982,color:#fff
    style COPILOT fill:#e3f2fd,color:#333
```

### 7.3 Skill Discovery

OpenCode scans for skills at startup. Skills must have YAML frontmatter with `name` and `description` fields to be discovered:

```markdown
---
name: my-skill
description: What it does and when to trigger it.
---
```

Skills live in `.opencode/skills/<name>/SKILL.md` relative to the project root. Skills created after `opencode web` starts require a new session or restart to be discovered.

---

## 8. Lab Content Architecture

### 8.1 Filesystem Layout

```
/root/labs/                          # Project root (git repo)
  opencode.json                      # Project-level OpenCode config
  INSTRUCTIONS.md                    # System prompt (lab tutor persona)
  README.md                          # Welcome page content
  tutorial.html                      # Tutorial wrapper page
  docs-server.py                     # HTTP server for tutorial + docs
  lab-01-getting-started/
    web.md                           # Lab 1 -- Web UI instructions
    cli.md                           # Lab 1 -- CLI instructions
  lab-02-skills/
    web.md                           # Lab 2 -- Web UI instructions (Parts A-D)
    cli.md                           # Lab 2 -- CLI instructions
    docs/                            # Reference docs for Lab 2 Part C
      server-troubleshooting-guide.md
  lab-03-agent-workflow/
    web.md                           # Lab 3 -- Web UI instructions
    cli.md                           # Lab 3 -- CLI instructions
    sample-project/                  # Intentionally buggy Python files
      app.py
      utils.py
      config.py
  lab-04-ingesting-skills/
    web.md                           # Lab 4 -- Web UI instructions
    cli.md                           # Lab 4 -- CLI instructions
```

### 8.2 Lab Progression

```mermaid
graph LR
    L1["Lab 1<br/>Getting Started<br/>(20 min)"]
    L2["Lab 2<br/>Building Skills<br/>(45 min)"]
    L3["Lab 3<br/>Agent Workflows<br/>(40 min)"]
    L4["Lab 4<br/>Ingesting Skills<br/>(20 min)"]

    L1 -->|"Knows: prompts, tools,<br/>file operations"| L2
    L2 -->|"Knows: SKILL.md format,<br/>skill-creator, instrospect"| L3
    L3 -->|"Knows: multi-step workflows,<br/>code review automation"| L4

    subgraph "Lab 2 Parts"
        A["A: Hand-craft a skill<br/>(greeter)"]
        B["B: /skill-creator<br/>(auto-generate)"]
        C["C: Skill from docs<br/>(QE/HPC references)"]
        D["D: instrospect audit<br/>(requires VPN build)"]
    end

    L2 --- A --> B --> C --> D

    style L1 fill:#e3f2fd,color:#333
    style L2 fill:#01A982,color:#fff
    style L3 fill:#1565c0,color:#fff
    style L4 fill:#7b1fa2,color:#fff
```

---

## 9. Demo Recording Pipeline

The project includes a Playwright-based recording script that captures a full walkthrough video of all labs.

```mermaid
sequenceDiagram
    participant RD as record-demo.js
    participant DC as Docker Compose
    participant PW as Playwright/Chromium
    participant TP as Tutorial Page :8080
    participant IF as OpenCode iframe :5178
    participant FF as ffmpeg

    RD->>DC: docker compose restart
    Note over DC: Clean container state<br/>(no leftover files)
    DC-->>RD: Services ready

    RD->>PW: Launch Chromium<br/>--disable-web-security
    PW->>TP: Navigate to localhost:8080
    PW->>IF: Find cross-origin iframe
    PW->>IF: Setup: Add project > ~/labs/ > New session

    loop Each Lab
        PW->>TP: Click primary tab
        PW->>TP: Click "WEB" sub-tab
        PW->>IF: fill() for multi-line / type() for single-line
        PW->>IF: Submit prompt (button or Ctrl+Enter)
        PW->>IF: Poll for stable response
    end

    PW-->>RD: session-<timestamp>/page@xxx.webm
    RD->>FF: ffmpeg -c:v libx264 -crf 23
    FF-->>RD: hackshack-demo-<timestamp>.mp4
```

### 9.1 Key Recording Details

| Concern | Solution |
|---------|----------|
| Cross-origin iframe | `--disable-web-security` + `--disable-features=IsolateOrigins,site-per-process` |
| Multi-line prompts | `fill()` pastes entire prompt (avoids Enter sending per-line) |
| Single-line prompts | `keyboard.type()` for visual character-by-character effect |
| Clean state | Container restarted before recording |
| Response detection | Poll iframe content until stable (no new text for 3s) |
| Video format | Playwright records WebM; ffmpeg converts to MP4 |

### 9.2 Makefile Targets

```
make video          # Full recording (all labs, ~6 min)
make video-lab1     # Lab 1 only
make video-lab2     # Lab 2 only
make video-lab3     # Lab 3 only
make video-headless # All labs, no visible browser window
```

---

## 10. Resource Requirements

### 10.1 Per-Container

| Resource | Limit | Notes |
|----------|-------|-------|
| Memory | 2 GB | Set via docker-compose / create-appliance.sh |
| CPU | 2 cores | Set via docker-compose / create-appliance.sh |
| Disk | ~1.6 GB (image) + ephemeral writes | No persistent volumes |
| Network | Outbound HTTPS only | opencode.ai (Zen), optionally api.githubcopilot.com |

### 10.2 Server Capacity Planning

With 20+ concurrent students, each needing a 2 GB / 2 CPU container:

| Students | Memory | CPUs | Ports |
|----------|--------|------|-------|
| 10 | 20 GB | 20 | 8081-8090, 5179-5188 |
| 20 | 40 GB | 40 | 8081-8100, 5179-5198 |
| 40 | 80 GB | 80 | 8081-8120, 5179-5218 |

### 10.3 Known Constraints

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| Zen free models have no SLA | Responses may be slow (30s+) or unavailable | mimo-v2.5-free is reliable; warn students about slow alternatives |
| Free models skip system instructions | Tutor persona (INSTRUCTIONS.md) may not activate | Labs still work; greeting just won't match tutor template |
| No persistent storage | Container restart = clean slate | By design for lab isolation; could add volumes if needed |
| Port arithmetic (`8080+N`) | Limited to ~900 students per server | Sufficient for WoD scale |

---

## 11. Security Considerations

| Area | Status |
|------|--------|
| No API keys required | Zen free models work without credentials |
| GITHUB_TOKEN (optional) | Injected via env var, sed-substituted at runtime, never committed |
| No volume mounts | Container filesystem is isolated; no host data exposure |
| No privileged mode | Containers run as root inside container only |
| Zscaler CA | Baked into image for corporate TLS inspection; harmless in non-corporate environments |
| instrospect policy | Runs from /opt/instrospect (outside project dir); OpenCode shows policy warning students must accept |
| Lab content | Public-only references (no proprietary HPE content); warning against pasting proprietary data into public models |

---

## 12. File Inventory

```
HackShack/
  ARCHITECTURE.md          # This document
  TLDR.md                  # Quick-start guide
  README.md                # Project README
  Dockerfile               # Container image definition
  docker-compose.yml       # Local development compose file
  entrypoint.sh            # Container startup script
  build.sh                 # Full build script (clones instrospect)
  Makefile                 # Build, run, video, clean targets
  record-demo.js           # Playwright demo recording script
  config/
    opencode.json          # Global OpenCode config (minimal)
    zscaler-root-ca.crt    # Corporate TLS inspection cert
    INSTRUCTIONS.md        # Lab tutor system prompt
  labs/                    # All lab content (copied into container)
    opencode.json          # Project-level config (+ optional Copilot)
    tutorial.html          # Tutorial wrapper page
    docs-server.py         # HTTP server for tutorial + docs
    README.md              # Welcome page
    INSTRUCTIONS.md        # Lab tutor prompt
    lab-01-getting-started/
    lab-02-skills/
    lab-03-agent-workflow/
    lab-04-ingesting-skills/
  tests/
    validate-env.sh        # 26-check environment validation
  wod-scripts/
    create-appliance.sh    # WoD: start per-student container
    cleanup-appliance.sh   # WoD: remove container on expiry
    reset-appliance.sh     # WoD: destroy + re-create
  WKSHP-OpenWork/
    0-ReadMeFirst.ipynb    # JupyterHub launcher notebook
    wod.conf               # WoD workshop metadata
  recordings/              # Demo video output (gitignored)
  instrospect/             # Cloned at build time (gitignored)
```

---

## 13. Integration Checklist for WoD Team

To deploy this workshop on the WoD infrastructure:

- [ ] **Docker image**: Build with `./build.sh` (VPN) or `make build-quick` (no VPN). Push to the WoD container registry.
- [ ] **wod.conf**: Verify `WKSHP-OpenWork/wod.conf` metadata (name, duration, category) matches WoD catalog requirements.
- [ ] **Appliance scripts**: Place `wod-scripts/create-appliance.sh`, `cleanup-appliance.sh`, and `reset-appliance.sh` where `procmail-action.sh` expects them. Ensure Docker socket access from the WoD backend.
- [ ] **Notebook**: Place `WKSHP-OpenWork/0-ReadMeFirst.ipynb` in the standard WoD notebook directory. Template variables (`{{ BRANDINGLOGO }}`, `{{ YOURWKSHPBE }}`, `{{ YOURWORKSHOPDESC }}`) will be substituted by the WoD framework.
- [ ] **Network**: Ensure outbound HTTPS to `opencode.ai` is allowed from the backend server. No inbound ports beyond the per-student mapping are needed.
- [ ] **Capacity**: Plan for 2 GB RAM + 2 CPUs per concurrent student. A 64 GB / 32 CPU server supports ~16 concurrent students comfortably.
- [ ] **GITHUB_TOKEN** (optional): If Copilot access is desired for faster responses, set `GITHUB_TOKEN` in the environment or pass it through create-appliance.sh.
- [ ] **instrospect** (optional): If Lab 2D full functionality is needed, ensure `github.hpe.com` is reachable during the Docker build.
- [ ] **Firewall**: Only outbound HTTPS (443) to `opencode.ai` is required. No inbound internet access needed.
