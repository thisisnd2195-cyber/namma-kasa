/**
 * Fails when a route the API serves is absent from the published OpenAPI
 * document, or when the document describes a route that no longer exists.
 *
 * The previous drift check only re-emitted the document and diffed it against
 * the generator that produces it, so an endpoint nobody had documented was
 * invisible to it. This compares the contract against the router.
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { listRoutes } from "./list-routes";

const SPEC = join(__dirname, "..", "..", "..", "contracts", "openapi.json");
const GLOBAL_PREFIX = "/v1";

/**
 * Endpoints deliberately outside the client contract. Each needs a reason: the
 * Dart and TypeScript clients are generated from this document, so anything
 * excluded here is something no client may call.
 */
const EXCLUDED = new Map<string, string>([
  ["GET /v1/metrics", "Prometheus scrape target, not a client API"],
]);

interface OpenApiDocument {
  paths: Record<string, Record<string, unknown>>;
}

/** OpenAPI writes `{id}`; Nest writes `:id`. */
const normalise = (path: string): string => path.replace(/:([A-Za-z0-9_]+)/g, "{$1}");

function documented(doc: OpenApiDocument): Set<string> {
  const entries = new Set<string>();
  for (const [path, operations] of Object.entries(doc.paths)) {
    for (const method of Object.keys(operations)) {
      entries.add(`${method.toUpperCase()} ${GLOBAL_PREFIX}${path}`);
    }
  }
  return entries;
}

async function main(): Promise<void> {
  const doc = JSON.parse(readFileSync(SPEC, "utf8")) as OpenApiDocument;
  const inDocument = documented(doc);
  const served = (await listRoutes()).map(normalise);

  const undocumented = served.filter((r) => !inDocument.has(r) && !EXCLUDED.has(r));
  const orphaned = [...inDocument].filter((r) => !served.includes(r));

  if (undocumented.length === 0 && orphaned.length === 0) {
    const skipped = served.length - (served.length - EXCLUDED.size);
    console.log(
      `Contract covers all ${served.length - skipped} client routes ` +
        `(${EXCLUDED.size} deliberately excluded).`,
    );
    return;
  }

  if (undocumented.length > 0) {
    console.error(`\n${undocumented.length} route(s) served but absent from the contract:`);
    for (const route of undocumented) console.error(`  ${route}`);
    console.error("\nAdd them to apps/api/src/openapi/document.ts, or list them in");
    console.error("EXCLUDED in scripts/check-coverage.ts with a reason.");
  }

  if (orphaned.length > 0) {
    console.error(`\n${orphaned.length} route(s) documented but no longer served:`);
    for (const route of orphaned) console.error(`  ${route}`);
  }

  process.exit(1);
}

void main();
