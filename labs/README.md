# HPE HackShack -- OpenCode & AI Skills Tutorial

Welcome to the OpenCode workshop!

## Your Screen Layout

You are looking at a split view:

- **Left panel** -- OpenCode web UI (your AI workspace)
- **Right panel** -- Lab instructions (you are reading them now)

Use the tabs above (Welcome, Lab 1, Lab 2, Lab 3, Lab 4, Lab 5) to navigate between labs.

---

## Step 1: Set Up Your Project

Look at the **left panel**. You should see a project folder picker icon at the top of the screen, saying **"Add project"**.

1. Click on it and select **`~/labs/`**.

2. You should now see a new screen. Go ahead and select **"New session"**.

3. You should see a text input at the bottom of the left panel. That is the **session composer** -- where you type messages to the AI agent.

4. If you see a model name in the lower bar (like "mimo-v2.5-free"), you are ready to go. If not, click the model picker and select any Zen free model.

5. Type your first message in the composer and press **Enter**:

```
What files are in this workspace? List the labs available.
```

The AI will use its built-in tools (Glob, Read, Bash) to explore the filesystem and answer you.

> **Note**: Free models can take 15-30 seconds to respond. Be patient on the first message.

## Step 2: Explore the Environment

Try a few more prompts to get comfortable:

```
Create a Python script that prints "Hello from the HackShack!", save it as hello.py and run it.
```

```
What tools do you have available?
```

```
Read lab-01-getting-started/README.md and summarize it for me
```

Watch how OpenCode reads files, writes code, and runs commands -- asking for your approval before anything destructive.

## Step 3: Work Through the Labs

Scroll to the **top of this panel** -- you will see tabs labeled **Welcome**, **Lab 1**, **Lab 2**, **Lab 3**, **Lab 4**, and **Lab 5**. Click **Lab 1** to begin.

Each lab builds on the previous one -- do them in order.

| Lab | Topic | Duration |
|-----|-------|----------|
| Lab 1 | First prompts, exploring the environment | 20 min |
| Lab 2 | Building skills (hand-craft, creator, docs, audit) | 45 min |
| Lab 3 | Multi-step automated code review | 40 min |
| Lab 4 | Ingesting community skills + SkillSpector audit | 20 min |
| Lab 5 | Discovering and using a community skill | 20 min |

---

## Tips

- The AI can read any file in your workspace -- just ask
- If you get stuck, ask the AI: "I'm stuck on step 3 of lab 2"
- To start a fresh conversation, click the **+** button in the top bar
- You can switch models anytime using the model picker
- Free models work best with clear, specific prompts
- After creating a new skill file, start a new session so OpenCode discovers it
