# Lab 01: Getting Started with OpenCode (Web UI)

## Objective
Get comfortable with OpenCode's web interface, verify your model, and have your first AI-assisted conversation.

## Steps

### 1. Verify Your Setup

You should already have OpenCode running in the left panel from the Welcome page. If you do not see a chat composer at the bottom of the left panel, reload the tutorial page.

The default model (`opencode/mimo-v2.5-free`) is already selected. You can switch models with the model picker in the lower-left bar.

### 2. Your First Prompt

Type this into the composer on the left and press Enter:

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

It will list all built-in tools -- Read, Write, Glob, Grep, Bash, Edit, and more.

### 5. Try Another Model

Switch to a different free model using the model picker in the lower-left bar (e.g., ling-3.0-flash-fin-free, mimo-v2.5-free). Ask the same question to compare responses.

### 6. Multi-Turn Conversations

Continue the conversation -- ask follow-up questions:
```
Now modify hello.py to accept a name argument and greet the user by name, and run it.
```

The AI remembers the context of your conversation and builds on previous work.

## Key Concepts

- **OpenCode** is the CLI/TUI interface to OpenWork's agentic engine
- **Zen Free models** are free cloud models -- no API keys, no cost
- **Tools** are capabilities the AI can invoke (file read/write, bash, grep, etc.)
- The AI always asks for approval before executing potentially destructive actions
- The **model picker** in the lower-left bar lets you switch models mid-session

## Next Lab
-> Click the **Lab 2** tab above to learn about Skills
