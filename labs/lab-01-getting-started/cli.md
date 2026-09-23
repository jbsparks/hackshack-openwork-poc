# Lab 01: Getting Started with OpenCode (CLI)

## Objective
Get comfortable with OpenCode's terminal interface, verify your model, and have your first AI-assisted conversation from the command line.

## Prerequisites

You need terminal access to the container. If you are using the Workshops-on-Demand environment, open a terminal from JupyterHub or SSH into the student container.

## Steps

### 1. Launch OpenCode

```bash
cd /root/labs
opencode
```

OpenCode starts in TUI (Terminal UI) mode. You will see a full-screen text interface with a prompt at the bottom.

The default model is already configured (`opencode/mimo-v2.5-free`). You can check the current model in the status bar.

### 2. Your First Prompt

Type this at the prompt and press Enter:

```
What files are in this directory?
```

OpenCode will use its built-in tools (Read, Glob, Bash) to explore the filesystem and answer.

> **Note**: Free models can be slow (15-30s). If a response seems stuck, wait a moment -- it is working.

### 3. Try a Code Task

```
Create a Python script that prints "Hello from the HackShack!", save it as hello.py and run it.
```

Watch how OpenCode:
- Writes the file using the Write tool
- Can run it if you approve the Bash tool call

### 4. Explore Tools

Ask OpenCode:
```
What tools do you have available?
```

### 5. Exit and Switch Models

Press `Ctrl+C` or type `/quit` to exit. Re-launch with a different model:

```bash
opencode --model opencode/ling-3.0-flash-fin-free
```

Ask the same question to compare responses.

### 6. Non-Interactive Mode

You can also run single prompts without entering the TUI:

```bash
opencode run "List the Python files in this directory" --model opencode/mimo-v2.5-free
```

This is useful for scripting and CI/CD pipelines.

## Key Concepts

- **`opencode`** launches the TUI (full-screen terminal interface)
- **`opencode run "prompt"`** runs a single prompt non-interactively
- **`opencode web`** starts the web UI server (what you see in the left panel)
- **Zen Free models** are free cloud models -- no API keys, no cost
- All three modes (TUI, web, `run`) share the same project config and tools

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Enter` | Send prompt |
| `Ctrl+C` | Cancel current operation / exit |
| `/quit` | Exit OpenCode |
| `/clear` | Clear conversation |
| Tab | Autocomplete |

## Next Lab
-> Switch to the **Lab 2** tab to learn about Skills
