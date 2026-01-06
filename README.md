# agents-playground

Docker-based development environment for AI agents with browser automation capabilities.

## Features

- **Ubuntu 24.04** base with Python 3.12 and Node.js LTS
- **Browser Automation**: Pre-configured Playwright and Stagehand for headless browser operations
- **Claude Code CLI**: Anthropic's official CLI tool installed globally
- **Developer Experience**: Oh My Zsh with syntax highlighting, autosuggestions, and fzf
- **Container-Optimized**: Xvfb virtual framebuffer and optimized Chrome settings for containerized environments

## Quick Start

```bash
# Build and run with docker-compose
TIMESTAMP=$(date +%s) docker-compose up -d

# Or build manually
docker build -t agents-playground .
docker run -it --shm-size=2gb agents-playground
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `USERNAME` | Container user name | `nanobot` |
| `DISPLAY` | X display for browser | `:99` |
| `PLAYWRIGHT_BROWSERS_PATH` | Shared browser location | `/usr/local/share/playwright-browsers` |

## Included Tools

### Browser Automation
- **Playwright** (Python & Node.js) - Browser automation framework
- **Stagehand** - AI-powered browser automation
- **Chromium** - Pre-installed browser with container-optimized settings

### Development Tools
- Python 3.12 with pip
- Node.js LTS with npm
- Git, vim, zsh
- Network utilities (curl, wget, net-tools, bind9-host)

### Helper Scripts
- `browser-env` - Configure browser environment variables
- `/usr/local/share/stagehand-config/index.mjs` - Container-optimized Stagehand configuration

## Usage Examples

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
    browser.close()
```

### Node.js Stagehand
```javascript
import { createStagehand } from '/usr/local/share/stagehand-config/index.mjs';

const stagehand = await createStagehand();
await stagehand.init();
await stagehand.page.goto('https://example.com');
```

## Ports

- `3001` / `3011` (mapped) - Application port 1
- `3002` / `3012` (mapped) - Application port 2

## Volume Mounts

The default docker-compose mounts `/Volumes/EXTERNAL_STORAGE` to `/mnt/storage`. Adjust this path in `docker-compose.yml` for your setup.

## License

MIT
