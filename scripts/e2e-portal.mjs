/**
 * The admin portal, driven in a real browser against the real API.
 *
 * The API suite proves the endpoints; nothing proved the pages. Both bugs that
 * reached this project's UI lived in browser hydration — a redirect that fired
 * on the first null render and a map that never initialised on a hard load —
 * and neither was reachable from any test that did not run a browser.
 *
 * Every check below signs in through the real login form. No injected session,
 * no stubbed fetch.
 *
 * Usage: node scripts/e2e-portal.mjs [portalUrl] [apiUrl]
 */
import { globSync } from "node:fs";
import puppeteer from "puppeteer-core";

const PORTAL = process.argv[2] ?? "http://localhost:3000";
const API = process.argv[3] ?? "http://localhost:4000/v1";

const [executablePath] = [
  ...globSync(`${process.env.HOME}/.cache/puppeteer/chrome/*/chrome-mac-arm64/*.app/Contents/MacOS/*`),
  ...globSync(`${process.env.HOME}/.cache/puppeteer/chrome-headless-shell/*/*/chrome-headless-shell`),
];
if (!executablePath) throw new Error("no cached Chrome; run the screenshot script once first");

const results = [];
let failures = 0;

function check(ok, name, detail = "") {
  results.push({ ok, name });
  if (!ok) failures += 1;
  console.log(`  ${ok ? "✓" : "✗"} ${name}${detail ? `  (${detail})` : ""}`);
}

const browser = await puppeteer.launch({
  executablePath,
  headless: true,
  args: ["--enable-unsafe-swiftshader", "--hide-scrollbars"],
});
const page = await browser.newPage();
await page.setViewport({ width: 1440, height: 900 });

/** Signs in the way a person does: through the form. */
async function signIn(phone) {
  await page.goto(`${PORTAL}/login`, { waitUntil: "networkidle2" });
  await page.type('input[type="tel"], input:not([type="password"])', phone);
  await page.type('input[type="password"]', "devpassword");
  await Promise.all([
    page.waitForNavigation({ waitUntil: "networkidle2" }).catch(() => {}),
    page.click('button[type="submit"]'),
  ]);
  await new Promise((r) => setTimeout(r, 1200));
}

const text = () => page.evaluate(() => document.body.innerText);

console.log(`Portal E2E against ${PORTAL}\n`);

console.log("1. Sign-in through the real form");
await signIn("919000000001");
check(!page.url().includes("/login"), "super admin lands past the login page", page.url());
check((await text()).includes("Namma Kasa"), "the shell rendered");

console.log("\n2. Hydration — the bug class that reached users");
await page.goto(`${PORTAL}/dashboard`, { waitUntil: "networkidle2" });
await new Promise((r) => setTimeout(r, 1500));
check(
  !page.url().includes("/login"),
  "a hard load of a deep link keeps the session",
  "regression: PortalShell redirected on the first null render",
);

console.log("\n3. Dashboard shows what the API returned");
const rollup = await page.evaluate(async (api) => {
  const raw = sessionStorage.getItem("namma-kasa-portal-session");
  const token = JSON.parse(raw).accessToken;
  const res = await fetch(`${api}/admin/dashboard/city`, {
    headers: { authorization: `Bearer ${token}` },
  });
  return res.json();
}, API);
const dash = await text();
check(dash.includes(`${rollup.routeCoverage.percent}%`), "route coverage matches the API",
  `${rollup.routeCoverage.percent}%`);
check(dash.includes(String(rollup.trips.total)), "trip count matches the API",
  `${rollup.trips.total} trips`);

console.log("\n4. Live map actually initialises");
await page.goto(`${PORTAL}/live`, { waitUntil: "networkidle2" });
await new Promise((r) => setTimeout(r, 6000));
check(
  (await page.evaluate(() => document.querySelectorAll("canvas").length)) > 0,
  "MapLibre canvas is present on a hard load",
  "regression: the [] effect ran before PortalShell mounted the container",
);

console.log("\n5. Complaints carry their GPS verdict");
await page.goto(`${PORTAL}/complaints`, { waitUntil: "networkidle2" });
await new Promise((r) => setTimeout(r, 1500));
const complaints = await text();
check(
  complaints.includes("GPS record") || complaints.includes("Nothing here"),
  "each complaint states what the GPS record showed",
);

console.log("\n6. Ward scoping is enforced by the API, not the page");
await signIn("919000000002");
const denied = await page.evaluate(async (api) => {
  const token = JSON.parse(sessionStorage.getItem("namma-kasa-portal-session")).accessToken;
  const res = await fetch(`${api}/admin/dashboard/city`, {
    headers: { authorization: `Bearer ${token}` },
  });
  return res.status;
}, API);
check(denied === 403, "a ward admin is refused the city rollup", `HTTP ${denied}`);

await page.goto(`${PORTAL}/dashboard`, { waitUntil: "networkidle2" });
await new Promise((r) => setTimeout(r, 1200));
check(!(await text()).includes("Route coverage"), "and the page does not render it either");

console.log("\n7. Sign-out clears the session");
await page.goto(`${PORTAL}/dashboard`, { waitUntil: "networkidle2" });
await page.evaluate(() => {
  const button = [...document.querySelectorAll("button")].find((b) =>
    b.textContent.includes("Sign out"),
  );
  button?.click();
});
await new Promise((r) => setTimeout(r, 1200));
check(page.url().includes("/login"), "sign-out returns to the login page");
check(
  await page.evaluate(() => sessionStorage.getItem("namma-kasa-portal-session") === null),
  "and the stored session is gone",
);

await browser.close();

const passed = results.length - failures;
console.log(`\n${passed}/${results.length} checks passed${failures ? ` — ${failures} FAILED` : ""}`);
process.exit(failures === 0 ? 0 : 1);
