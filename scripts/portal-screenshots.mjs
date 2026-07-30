/**
 * Captures the admin portal's pages as PNGs against a running stack.
 *
 * Signs in through the real API and injects the session the same way the login
 * page stores it, then visits each page as the role that owns it. Maps need a
 * few seconds for tiles, so map pages get a longer settle.
 *
 * Usage: node scripts/portal-screenshots.mjs
 * Needs: API on :4000, portal (next start) on :3000, seeded + staged data.
 */
import { globSync } from "node:fs";
import { mkdirSync } from "node:fs";
import puppeteer from "puppeteer-core";

const WEB = "http://localhost:3000";
const API = "http://localhost:4000/v1";
const OUT = new URL("../docs/screenshots/", import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });

// Prefer full Chrome: the headless shell has no WebGL, and MapLibre needs it —
// without it every map pane photographs as a white rectangle.
const [executablePath] = [
  ...globSync(
    `${process.env.HOME}/.cache/puppeteer/chrome/*/chrome-mac-arm64/*.app/Contents/MacOS/*`,
  ),
  ...globSync(
    `${process.env.HOME}/.cache/puppeteer/chrome-headless-shell/*/chrome-headless-shell-mac-arm64/chrome-headless-shell`,
  ),
];
if (!executablePath) throw new Error("no cached Chrome found");

async function login(phone) {
  const response = await fetch(`${API}/auth/login`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ phone, password: "devpassword", deviceId: "screenshots" }),
  });
  const body = await response.json();
  if (!body.accessToken) throw new Error(`login failed for ${phone}`);
  // Exactly what the login page writes (apps/web/src/app/login/page.tsx).
  return {
    accessToken: body.accessToken,
    refreshToken: body.refreshToken,
    userId: body.user.id,
    role: body.user.role,
    wardId: body.user.wardId,
  };
}

const browser = await puppeteer.launch({
  executablePath,
  headless: true,
  args: ["--enable-unsafe-swiftshader", "--hide-scrollbars"],
});
const page = await browser.newPage();
await page.setViewport({ width: 1440, height: 900, deviceScaleFactor: 2 });

async function shoot(name, path, session, { settleMs = 1200, fullPage = true } = {}) {
  // Establish the origin, write the session exactly as the login page would,
  // THEN navigate. evaluateOnNewDocument accumulates scripts across shots and
  // raced here — the first capture of this script photographed a redirect.
  await page.goto(`${WEB}/login`, { waitUntil: "domcontentloaded", timeout: 45_000 });
  await page.evaluate((key, value) => {
    if (value) window.sessionStorage.setItem(key, JSON.stringify(value));
    else window.sessionStorage.removeItem(key);
  }, "namma-kasa-portal-session", session);
  await page.goto(`${WEB}${path}`, { waitUntil: "networkidle2", timeout: 45_000 });
  await new Promise((resolve) => setTimeout(resolve, settleMs));
  await page.screenshot({ path: `${OUT}portal-${name}.png`, fullPage });
  console.log(`  ✓ portal-${name}.png  (${path})`);
}

const superAdmin = await login("919000000001");
const wardAdmin = await login("919000000002");

console.log("Capturing as Super Admin:");
await shoot("login", "/login", null);
await shoot("home", "/", superAdmin);
await shoot("dashboard", "/dashboard", superAdmin);
await shoot("wards", "/wards", superAdmin, { settleMs: 5000, fullPage: false });

console.log("Capturing as Ward Admin:");
await shoot("routes", "/routes", wardAdmin, { settleMs: 5000, fullPage: false });
await shoot("fleet", "/fleet", wardAdmin);
await shoot("live", "/live", wardAdmin, { settleMs: 6000, fullPage: false });
await shoot("review-queue", "/review-queue", wardAdmin);
await shoot("complaints", "/complaints", wardAdmin);

await browser.close();
console.log(`\nSaved to docs/screenshots/`);
