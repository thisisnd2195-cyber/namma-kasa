/**
 * Renders every Mermaid block in docs/ to prove it parses.
 *
 * A diagram that looks right in a code fence is exactly as verified as a route
 * that typechecks. One of these shipped broken once — a semicolon inside a
 * `Note` ends the statement — and nothing caught it until someone looked at the
 * rendered page.
 *
 * Usage: node scripts/check-diagrams.mjs [--write]
 *   --write also emits SVGs to docs/diagrams/ for viewing outside GitHub.
 */
import { globSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFileSync } from "node:child_process";

const write = process.argv.includes("--write");
const root = new URL("..", import.meta.url).pathname;
const outDir = join(root, "docs/diagrams");
if (write) mkdirSync(outDir, { recursive: true });

const scratch = mkdtempSync(join(tmpdir(), "mermaid-"));
let checked = 0;
const failures = [];

for (const file of globSync(join(root, "docs/**/*.md"))) {
  const markdown = readFileSync(file, "utf8");
  const blocks = [...markdown.matchAll(/```mermaid\n([\s\S]*?)```/g)].map((m) => m[1]);

  // Name each diagram after the heading above it, so a failure is findable.
  const headings = [];
  for (const line of markdown.split("\n")) {
    if (/^#{2,3} /.test(line)) headings.push(line.replace(/^#+ /, ""));
    else if (line.startsWith("```mermaid")) headings.push(headings.at(-1) ?? "diagram");
  }

  blocks.forEach((source, index) => {
    checked += 1;
    const slug = `${index + 1}`.padStart(2, "0");
    const input = join(scratch, `${slug}.mmd`);
    const output = write ? join(outDir, `${slug}.svg`) : join(scratch, `${slug}.svg`);
    writeFileSync(input, source);
    try {
      execFileSync("npx", ["-y", "@mermaid-js/mermaid-cli", "-i", input, "-o", output], {
        stdio: "pipe",
      });
      process.stdout.write(`  ✓ ${slug}\n`);
    } catch (error) {
      const detail = String(error.stderr ?? error).split("\n").slice(0, 3).join(" ");
      failures.push(`${slug}: ${detail}`);
      process.stdout.write(`  ✗ ${slug}\n`);
    }
  });
}

rmSync(scratch, { recursive: true, force: true });

if (failures.length > 0) {
  console.error(`\n${failures.length} diagram(s) failed to render:\n${failures.join("\n")}`);
  process.exit(1);
}
console.log(`\nAll ${checked} diagrams render.`);
