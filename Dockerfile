FROM ubuntu:24.04

# Build argument for username (can be overridden via docker-compose)
ARG USERNAME=nanobot

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

# Browser automation environment variables
ENV DISPLAY=:99
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers
ENV CHROME_PATH=/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome
# NODE_PATH includes both global npm modules AND our custom stagehand-config
ENV NODE_PATH=/usr/lib/node_modules:/usr/local/share

# Install Essential Packages and set timezone
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y software-properties-common curl wget gnupg2 tzdata && \
    ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Update packages and install dependencies (Ubuntu 24.04 has Python 3.12 by default)
RUN apt-get update && \
    apt-get install -y sudo git python3 python3-dev python3-venv python3-pip gcc build-essential && \
    apt-get install -y zsh unzip vim ffmpeg net-tools iputils-ping bind9-host traceroute && \
    apt-get install -y language-pack-en autojump

# Install latest Node.js (using official NodeSource repository for latest LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    echo "Node.js version: $(node --version)" && \
    echo "npm version: $(npm --version)"

# Install additional dependencies for Playwright browsers
RUN apt-get install -y \
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libasound2t64 \
    libatspi2.0-0 \
    libgtk-3-0 \
    xvfb \
    x11vnc \
    websockify \
    novnc \
    fluxbox \
    netcat-openbsd \
    socat && \
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Create shared Playwright browsers directory (before user creation)
RUN mkdir -p /usr/local/share/playwright-browsers && \
    chmod 777 /usr/local/share/playwright-browsers

# Create user with zsh as default shell
RUN groupadd -r ${USERNAME} && \
    useradd -r -g ${USERNAME} -d /home/${USERNAME} -s /bin/zsh -c "Container User" ${USERNAME} && \
    mkdir -p /home/${USERNAME} && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# Add user to sudo group with passwordless sudo
RUN usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to user for user-specific installations
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Install Oh My Zsh and plugins for user
RUN export CHSH='no' && \
    export RUNZSH='no' && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && \
    ~/.fzf/install --all

# Download and configure custom .zshrc
RUN curl -s -o /home/${USERNAME}/.zshrc https://gist.githubusercontent.com/ehc-io/52a3549eb17dda934925149b9048f566/raw/c92738028c1a481956fea8e21483109a35c9f6a3/zshrc

# Install Python packages including Playwright
RUN python3 -m pip install --user --break-system-packages playwright stagehand

# Install Playwright browsers (chromium only)
RUN python3 -m playwright install chromium

# Add Python user bin to PATH permanently
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.zshrc

# Switch back to root for global installations
USER root

# Install Node.js packages globally (stagehand, playwright, zod, claude-code)
RUN npm install -g playwright @browserbasehq/stagehand zod @anthropic-ai/claude-code

# Install Playwright browsers to shared location and fix permissions
RUN npx playwright install chromium && \
    chmod -R 777 /usr/local/share/playwright-browsers

# Create browser-env helper script
RUN echo '#!/bin/bash\n\
# Browser automation environment setup\n\
export DISPLAY=:99\n\
export PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers\n\
export CHROME_PATH=/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome\n\
\n\
# Stagehand-specific browser args for containers\n\
export STAGEHAND_BROWSER_ARGS="--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu"\n\
\n\
echo "Browser environment configured"\n\
echo "  DISPLAY=$DISPLAY"\n\
echo "  CHROME_PATH=$CHROME_PATH"\n\
echo "  STAGEHAND_BROWSER_ARGS=$STAGEHAND_BROWSER_ARGS"\n\
' > /usr/local/bin/browser-env && chmod +x /usr/local/bin/browser-env

# Create Stagehand v3 helper module for container environments
RUN mkdir -p /usr/local/share/stagehand-config && \
    echo 'import { Stagehand } from "@browserbasehq/stagehand";\n\
\n\
// Container-optimized browser arguments\n\
export const containerBrowserArgs = [\n\
  "--no-sandbox",\n\
  "--disable-setuid-sandbox",\n\
  "--disable-dev-shm-usage",\n\
  "--disable-gpu",\n\
  "--disable-software-rasterizer"\n\
];\n\
\n\
// Primary: Stagehand v3 with local browser launch\n\
export async function createStagehand(options = {}) {\n\
  const stagehand = new Stagehand({\n\
    env: "LOCAL",\n\
    headless: options.headless !== false,\n\
    localBrowserLaunchOptions: {\n\
      chromiumSandbox: false,\n\
      args: containerBrowserArgs,\n\
      executablePath: process.env.CHROME_PATH || "/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome",\n\
      ...options.localBrowserLaunchOptions\n\
    },\n\
    ...options\n\
  });\n\
  return stagehand;\n\
}\n\
\n\
// Fallback: Connect to existing browser via CDP\n\
export async function createStagehandCDP(cdpUrl, options = {}) {\n\
  const stagehand = new Stagehand({\n\
    env: "LOCAL",\n\
    localBrowserLaunchOptions: {\n\
      cdpUrl: cdpUrl,\n\
      ...options.localBrowserLaunchOptions\n\
    },\n\
    ...options\n\
  });\n\
  return stagehand;\n\
}\n\
\n\
export default createStagehand;\n\
' > /usr/local/share/stagehand-config/index.mjs && \
    chmod 644 /usr/local/share/stagehand-config/index.mjs

# Create comprehensive entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
export DISPLAY=:99\n\
\n\
# ===== Lock Cleanup =====\n\
clean_chrome_locks() {\n\
    local profile_dir="${CHROME_USER_DATA_DIR:-/home/${USER}/.chrome-profile}"\n\
    local locks=("SingletonLock" "SingletonSocket" "SingletonCookie" "DevToolsActivePort" "LOCK" ".lock")\n\
    for lock in "${locks[@]}"; do\n\
        rm -f "$profile_dir/$lock" 2>/dev/null || true\n\
    done\n\
    echo "Chrome locks cleaned"\n\
}\n\
\n\
# ===== Start Xvfb =====\n\
start_xvfb() {\n\
    if ! pgrep -x "Xvfb" > /dev/null; then\n\
        echo "Starting Xvfb on display :99..."\n\
        Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset &\n\
        sleep 2\n\
    fi\n\
}\n\
\n\
# ===== Start VNC =====\n\
start_vnc() {\n\
    if ! pgrep -x "x11vnc" > /dev/null; then\n\
        echo "Starting VNC server on port 5900..."\n\
        x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -xkb &\n\
        sleep 1\n\
    fi\n\
}\n\
\n\
# ===== Start noVNC =====\n\
start_novnc() {\n\
    if ! pgrep -f "websockify" > /dev/null; then\n\
        echo "Starting noVNC on port 6080..."\n\
        websockify --web=/usr/share/novnc 6080 localhost:5900 &\n\
        sleep 1\n\
    fi\n\
}\n\
\n\
# ===== Start Window Manager =====\n\
start_wm() {\n\
    if command -v fluxbox &> /dev/null && ! pgrep -x "fluxbox" > /dev/null; then\n\
        fluxbox &\n\
        sleep 1\n\
    fi\n\
}\n\
\n\
# ===== Main =====\n\
echo "Starting Browser Automation Environment..."\n\
clean_chrome_locks\n\
start_xvfb\n\
start_wm\n\
start_vnc\n\
start_novnc\n\
\n\
echo "========================================="\n\
echo "Environment Ready!"\n\
echo "  Display: :99"\n\
echo "  VNC: localhost:5900"\n\
echo "  noVNC: http://localhost:6080"\n\
echo ""\n\
echo "Browser: ON-DEMAND (launches when scripts run)"\n\
echo "========================================="\n\
\n\
exec "$@"\n\
' > /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

# Switch back to user
USER ${USERNAME}

# Copy application files to workdir
COPY --chown=${USERNAME}:${USERNAME} to-copy /workdir

# Set working directory
WORKDIR /workdir

# Add custom aliases and paths to .zshrc
RUN echo "source /mnt/storage/toolbox/containers/aliases 2>/dev/null || true" >> /home/${USERNAME}/.zshrc && \
    echo 'export PATH=/mnt/storage/toolbox/common/:/mnt/storage/toolbox/containers:$HOME/.local/bin:$PATH' >> /home/${USERNAME}/.zshrc && \
    echo 'export NODE_PATH=/usr/lib/node_modules:/usr/local/share' >> /home/${USERNAME}/.zshrc

# Expose ports
EXPOSE 3001 3002 5900 6080 9222 9223

# Set entrypoint to start Xvfb, then run command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command is zsh
CMD ["/bin/zsh"]