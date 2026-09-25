/**
 * HackShack Tutorial Screen Capture (Web UI)
 *
 * Records the Web variant of the tutorial. Opens the tutorial page
 * (localhost:8080) which embeds OpenCode (localhost:5178) in an iframe.
 * Chromium is launched with --disable-web-security so Playwright can
 * reach into the cross-origin iframe to type prompts and read responses.
 *
 * For CLI recording, use record-cli.sh (asciinema + expect).
 *
 * Usage:
 *   node record-demo.js                    # record all labs
 *   node record-demo.js --lab 1            # record only Lab 1
 *   node record-demo.js --headed           # watch live (default)
 *   node record-demo.js --headless         # no visible browser
 *   node record-demo.js --slow 500         # slow down actions by ms
 *
 * Output: recordings/hackshack-web-<timestamp>.mp4
 */

const { chromium } = require('playwright');
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// ---- Config ----

const TUTORIAL_URL = 'http://localhost:8080';
const OPENCODE_URL = 'http://localhost:5178';
const RECORDINGS_DIR = path.join(__dirname, 'recordings');

// Timing (ms)
const PAUSE_SHORT = 1500;
const PAUSE_READ = 4000;
const PAUSE_RESPONSE = 120000;
const PAUSE_AFTER_RESP = 3000;
const PAUSE_TYPING_DELAY = 25;

// ---- Parse args ----

const args = process.argv.slice(2);
const labOnly = args.includes('--lab') ? parseInt(args[args.indexOf('--lab') + 1]) : null;
const headed = !args.includes('--headless');
const slowMo = args.includes('--slow') ? parseInt(args[args.indexOf('--slow') + 1]) : 150;

// ---- Helpers ----

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function screenshot(page, name) {
  const p = path.join(RECORDINGS_DIR, `debug-${name}.png`);
  await page.screenshot({ path: p });
  console.log(`    [debug] Screenshot: ${p}`);
}

/**
 * Wait for AI response by polling the iframe content until stable.
 */
async function waitForResponse(frame, timeoutMs = PAUSE_RESPONSE) {
  console.log('    [wait] Waiting for AI response...');
  const start = Date.now();
  await sleep(3000);

  let lastText = '';
  let stableCount = 0;
  while (Date.now() - start < timeoutMs) {
    try {
      const currentText = await frame.evaluate(() => document.body.innerText.slice(-2000));
      if (currentText === lastText) {
        stableCount++;
        if (stableCount >= 4) {
          console.log(`    [wait] Response complete (${((Date.now() - start) / 1000).toFixed(1)}s)`);
          return;
        }
      } else {
        stableCount = 0;
        lastText = currentText;
      }
    } catch (e) { /* frame might be updating */ }
    await sleep(2000);
  }
  console.log('    [wait] Timeout waiting for response');
}

/**
 * Find the composer element inside the OpenCode iframe.
 */
async function findComposer(frame, timeoutMs = 10000) {
  const selectors = [
    'textarea[placeholder*="Ask"]',
    'textarea[placeholder*="ask"]',
    'textarea[placeholder*="anything"]',
    'textarea',
    '[contenteditable="true"]',
    '[role="textbox"]',
  ];

  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    for (const sel of selectors) {
      try {
        const el = await frame.$(sel);
        if (el) {
          const visible = await el.isVisible().catch(() => false);
          if (visible) return el;
        }
      } catch (e) { /* try next */ }
    }
    await sleep(500);
  }
  return null;
}

/**
 * Get the OpenCode iframe frame handle.
 */
async function getOpenCodeFrame(page, timeoutMs = 15000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const frames = page.frames();
    for (const f of frames) {
      const url = f.url();
      if (url.includes('5178') || url.includes('localhost:5178')) {
        return f;
      }
    }
    await sleep(500);
  }
  return null;
}

/**
 * Type a prompt into the OpenCode composer and send it.
 * Multi-line prompts are pasted via fill() to avoid Enter triggering send.
 * Single-line prompts are typed character-by-character for visual effect.
 */
async function sendPrompt(frame, prompt) {
  const short = prompt.length > 60 ? prompt.substring(0, 60) + '...' : prompt;
  console.log(`    [type] "${short}"`);

  const composer = await findComposer(frame);
  if (!composer) {
    console.log('    [WARN] Could not find composer, skipping prompt');
    return false;
  }

  await composer.click();
  await sleep(300);

  const isMultiLine = prompt.includes('\n');

  if (isMultiLine) {
    // Paste the entire prompt at once to avoid newlines triggering send
    await composer.fill(prompt);
    await sleep(800);
  } else {
    // Single line: type character by character for visual effect
    await composer.fill('');
    await frame.page().keyboard.type(prompt, { delay: PAUSE_TYPING_DELAY });
    await sleep(500);
  }

  // Send the message
  if (isMultiLine) {
    const sendBtn = await frame.$('button[type="submit"], button[aria-label*="Send"], button[aria-label*="send"]');
    if (sendBtn) {
      await sendBtn.click();
    } else {
      await frame.page().keyboard.press('Control+Enter');
    }
  } else {
    await frame.page().keyboard.press('Enter');
  }

  await sleep(1000);
  return true;
}

/**
 * Set up OpenCode inside the iframe: add project + create session.
 */
async function setupOpenCodeInFrame(page, frame) {
  console.log('[*] Setting up OpenCode in iframe...');

  // Check if already in a session (composer visible)
  let composer = await findComposer(frame, 3000);
  if (composer) {
    console.log('  [setup] Already in an active session');
    return true;
  }

  // Step 1: Click "Add project"
  console.log('  [setup] Looking for "Add project"...');
  try {
    const addProject = await frame.waitForSelector('text=Add project', { timeout: 5000 });
    await addProject.click();
    await sleep(2000);
    console.log('  [setup] Clicked "Add project"');
  } catch (e) {
    console.log('  [setup] "Add project" not found, maybe project exists...');
  }

  // Step 2: Select ~/labs/ folder
  console.log('  [setup] Selecting project folder...');
  try {
    const labsEntry = await frame.waitForSelector('text=~/labs/', { timeout: 5000 });
    await labsEntry.click();
    await sleep(3000);
    console.log('  [setup] Selected ~/labs/');
  } catch (e) {
    console.log('  [setup] ~/labs/ not in picker, checking if project already added...');
  }

  // Step 3: Click "New session"
  console.log('  [setup] Creating new session...');
  try {
    const newSession = await frame.waitForSelector('text=New session', { timeout: 5000 });
    await newSession.click();
    await sleep(3000);
    console.log('  [setup] Clicked "New session"');
  } catch (e) {
    try {
      const plus = await frame.$('button:has-text("+")');
      if (plus) { await plus.click(); await sleep(3000); }
    } catch (e2) { /* continue */ }
  }

  // Verify
  composer = await findComposer(frame, 10000);
  if (composer) {
    console.log('  [setup] [OK] Composer ready');
    return true;
  } else {
    console.log('  [setup] [FAIL] Composer not found after setup');
    await screenshot(page, 'setup-failed');
    return false;
  }
}

/**
 * Start a new session in the OpenCode iframe.
 */
async function startNewSession(frame) {
  console.log('  [step] New session (skill rescan)');
  try {
    let newBtn = await frame.$('button:has-text("+")');
    if (!newBtn) newBtn = await frame.$('button[aria-label*="New"]');
    if (!newBtn) newBtn = await frame.$('text=New session');
    if (newBtn) {
      await newBtn.click();
      await sleep(5000);
      const composer = await findComposer(frame, 10000);
      if (composer) {
        console.log('    [OK] New session created');
      } else {
        console.log('    [WARN] New session created but composer not found');
      }
    } else {
      console.log('    [WARN] Could not find new-session button, continuing in same session');
    }
  } catch (e) {
    console.log(`    [WARN] New session failed: ${e.message}`);
  }
}

// ---- Tutorial page helpers ----

async function clickPrimaryTab(page, label) {
  console.log(`  [tab] Clicking "${label}"`);
  await page.click(`#tabs-primary button:has-text("${label}")`);
  await sleep(PAUSE_SHORT);
}

async function clickSubTab(page, label) {
  console.log(`  [sub] Clicking "${label}"`);
  await page.click(`#tabs-sub button:has-text("${label}")`);
  await sleep(PAUSE_SHORT);
}

async function scrollDocPanel(page, pixels = 300) {
  await page.evaluate((px) => {
    const el = document.getElementById('doc-content');
    if (el) el.scrollBy({ top: px, behavior: 'smooth' });
  }, pixels);
  await sleep(1000);
}

// ---- Lab scripts ----

async function recordWelcome(page) {
  console.log('\n=== Welcome ===');
  await clickPrimaryTab(page, 'Welcome');
  await sleep(PAUSE_READ);
  for (let i = 0; i < 3; i++) {
    await scrollDocPanel(page, 400);
    await sleep(PAUSE_READ);
  }
}

async function recordLab1(page, frame) {
  console.log('\n=== Lab 1 (Web) ===');
  await clickPrimaryTab(page, 'Lab 1');
  await sleep(PAUSE_SHORT);
  await clickSubTab(page, 'WEB');

  // Step 2: First prompt (identical in web + cli)
  console.log('  [step] First prompt');
  await sendPrompt(frame, 'What files are in this directory?');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 300);

  // Step 3: Code task (identical in web + cli)
  console.log('  [step] Code task');
  await sendPrompt(frame, 'Create a Python script that prints "Hello from the HackShack!", save it as hello.py and run it.');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 300);

  // Step 4: Explore tools
  console.log('  [step] Explore tools');
  await sendPrompt(frame, 'What tools do you have available?');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Show CLI tab briefly
  console.log('  [step] Show CLI tab');
  await clickSubTab(page, 'CLI');
  await sleep(PAUSE_READ);
  await scrollDocPanel(page, 300);
  await sleep(PAUSE_READ);
}

async function recordLab2(page, frame) {
  console.log('\n=== Lab 2 (Web) ===');
  await clickPrimaryTab(page, 'Lab 2');
  await sleep(PAUSE_SHORT);
  await clickSubTab(page, 'WEB');

  // Part A - Create greeter directory
  console.log('  [step] Part A - Create greeter directory');
  await sendPrompt(frame, 'Create a directory at /root/labs/.opencode/skills/greeter/');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Part A - Create greeter skill
  console.log('  [step] Part A - Create greeter skill');
  await sendPrompt(frame, `Create the file /root/labs/.opencode/skills/greeter/SKILL.md with this content:

---
name: greeter
description: "Generates personalized welcome messages for workshop participants"
---

# Greeter Skill

You are now in Greeter mode. When activated, you:

1. Ask the user for their name and role
2. Generate a personalized welcome message for the workshop
3. Create a welcome.md file with:
   - A greeting header
   - Today's date
   - A fun tech fact related to their role
   - Three suggested labs based on their interests

Always be enthusiastic and encouraging!`);
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 500);
  await sleep(PAUSE_READ);

  // Part A - Test the skill (new session + load)
  console.log('  [step] Part A - New session for testing');
  await startNewSession(frame);

  console.log('  [step] Part A - Load all local skills');
  await sendPrompt(frame, 'Load all local skills');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  console.log('  [step] Part A - Test greeter');
  await sendPrompt(frame, 'Use the greeter skill to welcome me');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Part B - Skill creator
  console.log('  [step] Part B - Skill creator');
  await scrollDocPanel(page, 600);
  await sleep(PAUSE_READ);

  await sendPrompt(frame, `Use the skill-creator to create a skill that reviews Python files for security issues.
It should check for: hardcoded credentials, use of eval/exec,
SQL injection patterns, and insecure HTTP calls.
Output a security-report.md with findings sorted by severity.`);
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Part B - Show generated skill
  console.log('  [step] Part B - Show generated skill');
  await sendPrompt(frame, 'Show me the SKILL.md file that was just generated');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
}

async function recordLab3(page, frame) {
  console.log('\n=== Lab 3 (Web) ===');
  await clickPrimaryTab(page, 'Lab 3');
  await sleep(PAUSE_SHORT);
  await clickSubTab(page, 'WEB');

  // Step 1: Examine sample project
  console.log('  [step] Examine sample project');
  await sendPrompt(frame, 'List the files in lab-03-agent-workflow/sample-project/ and show me the first few lines of each');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Step 2: Create code-reviewer skill
  console.log('  [step] Create code-reviewer skill');
  await sendPrompt(frame, `Create the directory /root/labs/.opencode/skills/code-reviewer/ and then create a SKILL.md file inside it with this content:

---
name: code-reviewer
description: Review Python code for quality issues including missing docstrings, long functions, bare excepts, and missing type hints. Use when asked to review or audit Python code.
---

# Code Reviewer Skill

You are a senior Python code reviewer. When activated:

## Workflow

1. **Discovery**: Use Glob to find all .py files in the target directory
2. **Analysis**: For each file, Read it and check for:
   - Missing module/function docstrings
   - Functions longer than 20 lines
   - Missing type hints on function parameters
   - Bare except clauses
   - TODO/FIXME comments
3. **Report**: Generate review-report.md with:
   - Summary (total files, total issues)
   - Per-file findings table
   - Top 3 priority fixes
   - Overall code health score (A-F)

## Rules
- Be constructive, not critical
- Suggest fixes, don't just flag problems
- Score generously for tutorial/learning code`);
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Step 3: New session + load skills + run review
  await startNewSession(frame);

  console.log('  [step] Load all local skills');
  await sendPrompt(frame, 'Load all local skills');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  console.log('  [step] Run code review');
  await sendPrompt(frame, 'Use the code-reviewer skill to review the lab-03-agent-workflow/sample-project/ directory');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Step 4: Show report
  console.log('  [step] Show report');
  await sendPrompt(frame, 'Show me the formatted review-report.md that was just generated');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  await scrollDocPanel(page, 800);
  await sleep(PAUSE_READ);
}

async function recordLab4(page, frame) {
  console.log('\n=== Lab 4 (Web) ===');
  await clickPrimaryTab(page, 'Lab 4');
  await sleep(PAUSE_SHORT);
  await clickSubTab(page, 'WEB');

  // Step 1: Browse ecosystem
  console.log('  [step] Browse ecosystem');
  await sendPrompt(frame, 'What is the Vercel Labs Skills Registry and how do community skills work with OpenCode?');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 300);

  // Step 2: Install find-skills
  console.log('  [step] Install find-skills');
  await sendPrompt(frame, 'Run this command: npx skills add https://github.com/vercel-labs/skills --skill find-skills --agent opencode -y');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Copy to .opencode/skills so OpenCode can find it
  console.log('  [step] Copy skill to .opencode/skills');
  await sendPrompt(frame, 'Run this command: cp -r .agents/skills/find-skills .opencode/skills/find-skills');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  // Step 3: Verify installation
  console.log('  [step] Verify installation');
  await sendPrompt(frame, 'Show me the contents of .opencode/skills/find-skills/SKILL.md');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 400);

  // Step 4: Static scan
  console.log('  [step] Static scan with SkillSpector');
  await sendPrompt(frame, 'Run this command: skillspector scan skill .opencode/skills/find-skills/ --json');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);
  await scrollDocPanel(page, 400);

  // Step 7: Use the skill (new session + load)
  console.log('  [step] New session to use find-skills');
  await startNewSession(frame);

  console.log('  [step] Load all local skills');
  await sendPrompt(frame, 'Load all local skills');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  console.log('  [step] Use find-skills');
  await sendPrompt(frame, 'Find me a skill for writing unit tests');
  await waitForResponse(frame);
  await sleep(PAUSE_AFTER_RESP);

  await scrollDocPanel(page, 800);
  await sleep(PAUSE_READ);
}

// ---- Main ----

(async () => {
  fs.mkdirSync(RECORDINGS_DIR, { recursive: true });

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const videoDir = path.join(RECORDINGS_DIR, `session-web-${timestamp}`);

  console.log(`\n[*] HackShack Demo Recording`);
  console.log(`    Display: ${headed ? 'headed' : 'headless'}, slowMo: ${slowMo}ms`);
  console.log(`    Lab: ${labOnly || 'all'}`);
  console.log(`    Output: ${videoDir}/\n`);

  // Restart the container so the lab environment is clean (no leftover files)
  console.log('[*] Restarting container for a clean environment...');
  try {
    execSync('docker compose restart', { cwd: __dirname, stdio: 'inherit', timeout: 60000 });
    console.log('[OK] Container restarted');
    // Wait for services to come back up
    console.log('[*] Waiting for services to be ready...');
    const startWait = Date.now();
    const MAX_WAIT = 60000;
    while (Date.now() - startWait < MAX_WAIT) {
      try {
        execSync(`curl -sf ${TUTORIAL_URL} > /dev/null 2>&1`);
        execSync(`curl -sf ${OPENCODE_URL} > /dev/null 2>&1`);
        break;
      } catch {
        await sleep(2000);
      }
    }
    console.log('[OK] Services ready\n');
  } catch (err) {
    console.log(`[WARN] Container restart failed: ${err.message}`);
    console.log('       Continuing with existing container...\n');
  }

  // Launch with --disable-web-security so we can access the cross-origin iframe
  const browser = await chromium.launch({
    headless: !headed,
    slowMo: slowMo,
    args: [
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process',
    ],
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    recordVideo: {
      dir: videoDir,
      size: { width: 1920, height: 1080 },
    },
  });

  const page = await context.newPage();

  try {
    // Open tutorial page
    console.log('[*] Opening tutorial page...');
    await page.goto(TUTORIAL_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
    await sleep(5000);

    // Find the OpenCode iframe
    console.log('[*] Looking for OpenCode iframe...');
    const frame = await getOpenCodeFrame(page);
    if (!frame) {
      console.log('[FAIL] Could not find OpenCode iframe');
      await screenshot(page, 'no-iframe');
      throw new Error('OpenCode iframe not found');
    }
    console.log('[OK] Found OpenCode iframe:', frame.url());

    // Set up project + session inside the iframe
    const ready = await setupOpenCodeInFrame(page, frame);
    if (!ready) throw new Error('Could not set up OpenCode session');

    // Run selected labs
    if (!labOnly || labOnly === 0) await recordWelcome(page);
    if (!labOnly || labOnly === 1) await recordLab1(page, frame);
    if (!labOnly || labOnly === 2) await recordLab2(page, frame);
    if (!labOnly || labOnly === 3) await recordLab3(page, frame);
    if (!labOnly || labOnly === 4) await recordLab4(page, frame);

    console.log('\n[*] Recording complete!');
    await sleep(5000);  // Final pause before closing
  } catch (err) {
    console.error('\n[FAIL]', err.message);
    try { await screenshot(page, 'fail'); } catch (e) { /* ignore */ }
  } finally {
    await page.close();
    await context.close();
    await browser.close();
  }

  // Convert video
  const videos = fs.readdirSync(videoDir)
    .filter(f => f.endsWith('.webm'))
    .map(f => ({ name: f, size: fs.statSync(path.join(videoDir, f)).size }))
    .sort((a, b) => b.size - a.size);

  if (videos.length > 0) {
    const videoPath = path.join(videoDir, videos[0].name);
    const mp4Path = path.join(RECORDINGS_DIR, `hackshack-web-${timestamp}.mp4`);

    console.log(`\n[*] Raw video: ${videoPath} (${(videos[0].size / 1024 / 1024).toFixed(1)} MB)`);
    console.log(`[*] Converting to MP4...`);

    try {
      execSync(`ffmpeg -i "${videoPath}" -c:v libx264 -preset fast -crf 23 "${mp4Path}" -y 2>/dev/null`);
      console.log(`[OK] MP4 saved: ${mp4Path}`);
    } catch {
      console.log(`[WARN] ffmpeg conversion failed. Raw webm at: ${videoPath}`);
    }
  }
})();
