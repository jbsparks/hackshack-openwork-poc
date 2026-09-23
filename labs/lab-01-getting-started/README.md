# Lab 01: Getting Started with OpenCode

## Objective
Get comfortable with OpenCode's interface, connect to a free cloud model, and have your first AI-assisted conversation.

## Steps

### 1. Verify Your Setup

You should already have OpenCode running in the left panel from the Welcome page. If you do not see a chat composer at the bottom of the left panel, reload the tutorial page.

The default model (Hy3 Free) is already selected. You can switch models with the model picker in the lower bar.

### 2. Your First Prompt

Type this into the composer on the left and press Enter:

```
What files are in this directory?
```

OpenCode will use its built-in tools (Read, Glob, Bash) to explore the filesystem and answer.

> **Note**: Free models can be slow (15-30s). If a response seems stuck, wait a moment -- it is working.

### 3. Try a Code Task

```
Create a Python script that prints "Hello from the HackShack!" and saves it as hello.py
```

Watch how OpenCode:
- Writes the file
- Can run it if you approve

### 4. Explore Tools

Ask OpenCode:
```
What tools do you have available?
```

### 5. Try Another Model

Switch to a different free model using the model picker (e.g., ling-3.0-flash-fin-free, mimo-v2.5-free).
Ask the same question to compare responses.

### 6. (Optional) Try the CLI

If you have terminal access to the container, you can also use OpenCode as a CLI:

```bash
cd /root/labs
opencode
```

The CLI and web UI share the same project and configuration.

## Key Concepts

- **OpenCode** is the CLI/TUI interface to OpenWork's agentic engine
- **Zen Free models** are free cloud models -- no API keys, no cost
- **Tools** are capabilities the AI can invoke (file read/write, bash, grep, etc.)
- The AI always asks for approval before executing potentially destructive actions

## Next Lab
-> Click the **Lab 2** tab above, or ask the AI: "Walk me through Lab 2"
