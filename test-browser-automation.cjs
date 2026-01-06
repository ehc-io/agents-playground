#!/usr/bin/env node
/**
 * Browser Automation Test Script (CommonJS version)
 * Tests Stagehand v3 (primary) and Playwright CDP (fallback)
 *
 * Usage: node test-browser-automation.cjs
 */

const { Stagehand } = require("@browserbasehq/stagehand");
const { chromium } = require("playwright");
const { z } = require("zod");
const fs = require("fs");
const path = require("path");

const TEST_URL = "https://news.ycombinator.com";
const SCREENSHOT_DIR = process.cwd();

// Container-optimized browser args
const containerBrowserArgs = [
  "--no-sandbox",
  "--disable-setuid-sandbox",
  "--disable-dev-shm-usage",
  "--disable-gpu",
  "--disable-software-rasterizer"
];

// ============================================================
// TEST 1: Stagehand v3 Primary Mode
// ============================================================
async function testStagehandPrimary() {
  console.log("\n" + "=".repeat(60));
  console.log("TEST 1: Stagehand v3 Primary Mode");
  console.log("=".repeat(60));

  let stagehand = null;

  try {
    console.log("Initializing Stagehand v3...");

    stagehand = new Stagehand({
      env: "LOCAL",
      headless: true,
      localBrowserLaunchOptions: {
        chromiumSandbox: false,
        args: containerBrowserArgs,
        executablePath: process.env.CHROME_PATH || "/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome",
      },
    });

    await stagehand.init();
    console.log("✓ Stagehand initialized");

    // Get page from context (Stagehand v3 API)
    // v3 uses context.pages() instead of direct .page property
    const page = stagehand.context.pages()[0] || await stagehand.context.newPage();

    // Navigate
    console.log(`Navigating to ${TEST_URL}...`);
    await page.goto(TEST_URL, { waitUntil: "domcontentloaded", timeout: 30000 });
    console.log("✓ Navigation complete");

    // Take screenshot
    const screenshotPath = path.join(SCREENSHOT_DIR, "test1-stagehand-primary.png");
    await page.screenshot({ path: screenshotPath });
    console.log(`✓ Screenshot saved: ${screenshotPath}`);

    // Extract data - try Stagehand's AI extract if API key available, otherwise use DOM
    console.log("Extracting top stories...");
    let extractedTitles = [];

    try {
      // Try Stagehand AI extraction (requires ANTHROPIC_API_KEY or OPENAI_API_KEY)
      const stories = await stagehand.extract({
        instruction: "Extract the titles of the top 5 stories on Hacker News",
        schema: z.object({
          stories: z.array(z.string()).describe("List of story titles")
        })
      });

      if (stories.stories && stories.stories.length > 0) {
        extractedTitles = stories.stories;
        console.log("✓ Used Stagehand AI extraction");
      } else {
        throw new Error("No stories extracted via AI");
      }
    } catch (aiError) {
      // Fallback to DOM extraction (works without API key)
      console.log("ℹ AI extraction unavailable, using DOM extraction...");
      extractedTitles = await page.evaluate(() => {
        return Array.from(document.querySelectorAll(".titleline > a"))
          .slice(0, 5)
          .map(a => a.textContent);
      });
    }

    console.log("✓ Extracted stories:");
    extractedTitles.slice(0, 5).forEach((title, i) => {
      console.log(`  ${i + 1}. ${title.substring(0, 60)}...`);
    });

    console.log("\n✅ TEST 1 PASSED: Stagehand v3 Primary Mode works!");
    return true;

  } catch (error) {
    console.error(`\n❌ TEST 1 FAILED: ${error.message}`);
    return false;
  } finally {
    if (stagehand) {
      console.log("Closing Stagehand...");
      await stagehand.close();
    }
  }
}

// ============================================================
// TEST 2: Playwright Direct (Fallback)
// ============================================================
async function testPlaywrightDirect() {
  console.log("\n" + "=".repeat(60));
  console.log("TEST 2: Playwright Direct (Fallback Mode)");
  console.log("=".repeat(60));

  let browser = null;

  try {
    console.log("Launching Playwright browser...");

    browser = await chromium.launch({
      headless: true,
      executablePath: process.env.CHROME_PATH || "/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome",
      args: containerBrowserArgs,
    });
    console.log("✓ Browser launched");

    const context = await browser.newContext({
      userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    });
    const page = await context.newPage();

    // Navigate
    console.log(`Navigating to ${TEST_URL}...`);
    await page.goto(TEST_URL, { waitUntil: "domcontentloaded", timeout: 30000 });
    console.log("✓ Navigation complete");

    // Take screenshot
    const screenshotPath = path.join(SCREENSHOT_DIR, "test2-playwright-fallback.png");
    await page.screenshot({ path: screenshotPath });
    console.log(`✓ Screenshot saved: ${screenshotPath}`);

    // Extract data using DOM evaluation
    console.log("Extracting page data...");
    const pageData = await page.evaluate(() => {
      const title = document.title;
      const stories = Array.from(document.querySelectorAll(".titleline > a"))
        .slice(0, 5)
        .map(a => a.textContent);
      return { title, stories };
    });

    console.log(`✓ Page title: ${pageData.title}`);
    console.log("✓ Extracted stories:");
    pageData.stories.forEach((title, i) => {
      console.log(`  ${i + 1}. ${title.substring(0, 60)}...`);
    });

    console.log("\n✅ TEST 2 PASSED: Playwright Direct (Fallback) works!");
    return true;

  } catch (error) {
    console.error(`\n❌ TEST 2 FAILED: ${error.message}`);
    return false;
  } finally {
    if (browser) {
      console.log("Closing browser...");
      await browser.close();
    }
  }
}

// ============================================================
// TEST 3: VNC Display Check
// ============================================================
async function testVNCDisplay() {
  console.log("\n" + "=".repeat(60));
  console.log("TEST 3: VNC Display (Headed Mode)");
  console.log("=".repeat(60));

  let browser = null;

  try {
    console.log("Launching browser in headed mode (visible on VNC)...");
    console.log("Connect to VNC at localhost:5900 or noVNC at http://localhost:6080 to see the browser");

    browser = await chromium.launch({
      headless: false,  // Visible on VNC!
      executablePath: process.env.CHROME_PATH || "/usr/local/share/playwright-browsers/chromium-1200/chrome-linux/chrome",
      args: containerBrowserArgs,
    });
    console.log("✓ Browser launched in headed mode");

    const context = await browser.newContext();
    const page = await context.newPage();

    // Navigate to a visual page
    console.log("Navigating to example.com...");
    await page.goto("https://example.com", { waitUntil: "domcontentloaded" });
    console.log("✓ Page loaded - check VNC to see the browser window");

    // Wait a moment for visual confirmation
    await page.waitForTimeout(3000);

    // Take screenshot
    const screenshotPath = path.join(SCREENSHOT_DIR, "test3-vnc-headed.png");
    await page.screenshot({ path: screenshotPath });
    console.log(`✓ Screenshot saved: ${screenshotPath}`);

    console.log("\n✅ TEST 3 PASSED: VNC headed mode works!");
    return true;

  } catch (error) {
    console.error(`\n❌ TEST 3 FAILED: ${error.message}`);
    return false;
  } finally {
    if (browser) {
      console.log("Closing browser...");
      await browser.close();
    }
  }
}

// ============================================================
// MAIN
// ============================================================
async function main() {
  console.log("╔════════════════════════════════════════════════════════════╗");
  console.log("║       Browser Automation Capability Test Suite             ║");
  console.log("╚════════════════════════════════════════════════════════════╝");
  console.log(`\nEnvironment:`);
  console.log(`  DISPLAY: ${process.env.DISPLAY || "not set"}`);
  console.log(`  CHROME_PATH: ${process.env.CHROME_PATH || "not set (using default)"}`);
  console.log(`  NODE_PATH: ${process.env.NODE_PATH || "not set"}`);
  console.log(`  Working dir: ${process.cwd()}`);

  const results = {
    stagehandPrimary: false,
    playwrightFallback: false,
    vncDisplay: false,
  };

  // Run tests
  results.stagehandPrimary = await testStagehandPrimary();
  results.playwrightFallback = await testPlaywrightDirect();
  results.vncDisplay = await testVNCDisplay();

  // Summary
  console.log("\n" + "=".repeat(60));
  console.log("TEST SUMMARY");
  console.log("=".repeat(60));
  console.log(`  Stagehand v3 Primary:    ${results.stagehandPrimary ? "✅ PASS" : "❌ FAIL"}`);
  console.log(`  Playwright Fallback:     ${results.playwrightFallback ? "✅ PASS" : "❌ FAIL"}`);
  console.log(`  VNC Headed Mode:         ${results.vncDisplay ? "✅ PASS" : "❌ FAIL"}`);
  console.log("=".repeat(60));

  const allPassed = Object.values(results).every(r => r);
  if (allPassed) {
    console.log("\n🎉 All tests passed! Browser automation is ready.");
  } else {
    console.log("\n⚠️  Some tests failed. Check the output above for details.");
  }

  // List screenshots
  console.log("\nScreenshots saved:");
  const screenshots = fs.readdirSync(SCREENSHOT_DIR).filter(f => f.startsWith("test") && f.endsWith(".png"));
  screenshots.forEach(f => console.log(`  - ${f}`));
}

main().catch(console.error);
