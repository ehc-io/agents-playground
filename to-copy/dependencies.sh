#!/bin/bash
set -e

echo "Installing Python dependencies..."

# Install pip if not already installed
if ! command -v pip3.11 &> /dev/null; then
    echo "Installing pip for Python 3.11..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
fi

# Install Python packages
echo "Installing Python Playwright and Stagehand..."
python3.11 -m pip install --user playwright stagehand

# Install Playwright browsers (chromium only)
echo "Installing Playwright Chromium browser..."
python3.11 -m playwright install chromium

# Install Node.js Playwright
echo "Installing Node.js Playwright..."
npm install -g playwright

# Install Playwright browsers for Node.js (chromium only)
echo "Installing Node.js Playwright Chromium browser..."
npx playwright install chromium

# Verify installations
echo "Verifying installations..."
echo "Python Playwright version:"
python3.11 -c "import playwright; print(playwright.__version__)" || echo "Python Playwright not found"

echo "Node.js Playwright version:"
npx playwright --version || echo "Node.js Playwright not found"

echo "Dependencies installed successfully!"