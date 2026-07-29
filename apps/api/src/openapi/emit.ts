/**
 * Writes the OpenAPI document to disk. `pnpm contracts:check` re-runs this and
 * fails if the working tree changes, which is what stops the published contract
 * from drifting away from the Zod schemas.
 */
import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { buildOpenApiDocument } from "./document";

const OUTPUT = join(__dirname, "..", "..", "..", "..", "contracts", "openapi.json");

mkdirSync(dirname(OUTPUT), { recursive: true });
writeFileSync(OUTPUT, `${JSON.stringify(buildOpenApiDocument(), null, 2)}\n`);
console.log(`OpenAPI written to ${OUTPUT}`);
