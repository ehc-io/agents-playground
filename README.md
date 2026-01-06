# agents-playground

Docker-based development environment for AI agents with browser automation capabilities.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     agents-playground                            │
├─────────────────────────────────────────────────────────────────┤
│  /workspace (WORKDIR)                                           │
│  ├── package.json          # ESM module config                  │
│  └── node_modules/         # Local dependencies                 │
│      ├── @browserbasehq/stagehand                               │
│      ├── playwright                                             │
│      └── zod                                                    │
├─────────────────────────────────────────────────────────────────┤
│  Global Tools                                                   │
│  ├── claude (CLI)          # @anthropic-ai/claude-code          │
│  ├── python3 + playwright  # Python browser automation          │
│  └── chromium              # Shared browser instance            │
├─────────────────────────────────────────────────────────────────┤
│  Display Stack                                                  │
│  ├── Xvfb :99              # Virtual framebuffer                │
│  ├── Fluxbox               # Window manager                     │
│  ├── x11vnc :5900          # VNC server                         │
│  └── noVNC :6080           # Web-based VNC client               │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Base OS** | Ubuntu 24.04 | Stable LTS with modern packages |
| **Runtime** | Node.js LTS, Python 3.12 | JavaScript and Python execution |
| **Browser** | Chromium (Playwright) | Headless/headed browser automation |
| **AI Automation** | Stagehand v3 | AI-powered browser control with self-healing selectors |
| **Fallback** | Playwright | Direct browser control via CDP |
| **Display** | Xvfb + x11vnc + noVNC | Virtual display with remote viewing |
| **Shell** | Zsh + Oh My Zsh | Developer-friendly shell experience |
| **AI Assistant** | Claude Code CLI | Anthropic's coding assistant |

## Features

- **Stagehand v3 Primary**: AI-powered browser automation with natural language commands
- **Playwright Fallback**: Direct CDP control for stealth/manual operations
- **VNC Debugging**: Visual browser inspection via VNC or web browser
- **ESM Compatible**: Modern JavaScript modules work out of the box
- **Container-Optimized**: Pre-configured Chrome flags for containerized environments
- **On-Demand Browser**: Browser launches only when scripts run (no idle processes)

## Quick Start

```bash
# Build and run
TIMESTAMP=$(date +%s) docker-compose up -d

# Attach to container
docker exec -it agent-playground-<timestamp> zsh

# Run browser automation test
node test-browser-automation.mjs
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| `5900` (→8900) | VNC | Connect with VNC client |
| `6080` | noVNC | Web browser at http://localhost:6080 |
| `9222` | CDP | Chrome DevTools Protocol direct |
| `9223` | CDP Proxy | CDP via socat proxy |

## Usage Examples

### Stagehand v3 (Primary)

```javascript
// /workspace/scraper.mjs
import { Stagehand } from "@browserbasehq/stagehand";
import { z } from "zod";

const stagehand = new Stagehand({
  env: "LOCAL",
  headless: true,
  localBrowserLaunchOptions: {
    chromiumSandbox: false,
    args: ["--no-sandbox", "--disable-dev-shm-usage"],
    executablePath: process.env.CHROME_PATH,
  },
});

await stagehand.init();
const page = stagehand.context.pages()[0];

await page.goto("https://example.com");
await page.screenshot({ path: "screenshot.png" });

// AI extraction (requires ANTHROPIC_API_KEY)
const data = await stagehand.extract({
  instruction: "Extract the main heading",
  schema: z.object({ heading: z.string() })
});

await stagehand.close();
```

### Playwright (Fallback)

```javascript
// /workspace/fallback.mjs
import { chromium } from "playwright";

const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROME_PATH,
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});

const page = await browser.newPage();
await page.goto("https://example.com");

// DOM extraction (no API key needed)
const title = await page.evaluate(() => document.title);
console.log(title);

await browser.close();
```

### Python Playwright

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=True,
        args=['--no-sandbox', '--disable-dev-shm-usage']
    )
    page = browser.new_page()
    page.goto('https://example.com')
    page.screenshot(path='screenshot.png')
    browser.close()
```

### Headed Mode (VNC)

```javascript
// Launch visible browser - view at http://localhost:6080
import { chromium } from "playwright";

const browser = await chromium.launch({
  headless: false,  // Visible on VNC!
  executablePath: process.env.CHROME_PATH,
  args: ["--no-sandbox", "--disable-dev-shm-usage"],
});
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `USERNAME` | Container user | `user` |
| `DISPLAY` | X display | `:99` |
| `CHROME_PATH` | Chromium executable | `/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome` |
| `PLAYWRIGHT_BROWSERS_PATH` | Browser install location | `/usr/local/share/playwright-browsers` |
| `CHROME_USER_DATA_DIR` | Persistent profile | `/home/${USERNAME}/.chrome-profile` |

## Volume Mounts

| Host | Container | Purpose |
|------|-----------|---------|
| `/Volumes/EXTERNAL_STORAGE` | `/mnt/storage` | Shared storage |
| `./browser_data/chrome_profiles` | `/home/${USERNAME}/.chrome-profile` | Persistent browser profile |
| `./browser_data/downloads` | `/home/${USERNAME}/Downloads` | Browser downloads |

## Directory Structure

```
/workspace/              # WORKDIR - run scripts from here
├── package.json         # Dependencies (stagehand, playwright, zod)
└── node_modules/        # Local packages (ESM compatible)

/workdir/                # Utility scripts from to-copy/
├── package.json
└── *.sh                 # Helper scripts

/home/${USERNAME}/       # User home
├── .chrome-profile/     # Persistent Chrome data (mounted)
└── Downloads/           # Browser downloads (mounted)
```

## Stagehand v3 Notes

Stagehand v3 API changes from v2:
- Use `stagehand.context.pages()[0]` instead of `stagehand.page`
- Use `localBrowserLaunchOptions` instead of `browserLaunchOptions`
- Use `chromiumSandbox: false` instead of `--no-sandbox` arg for sandbox control
- AI features (`extract`, `act`) require `ANTHROPIC_API_KEY` or `OPENAI_API_KEY`

## License

MIT
