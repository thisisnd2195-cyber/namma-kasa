/**
 * Enumerates every route the API actually serves, by reading the same Nest
 * decorator metadata the router itself uses.
 *
 * This exists because `contracts:check` used to re-emit the OpenAPI document and
 * diff it against the generator that produces it — a check that could never
 * notice an endpoint nobody had documented. It stayed green while 45 of 50
 * routes were missing from the published contract. A guard has to observe the
 * system, not itself.
 *
 * Reflection over the source rather than a booted app: this needs to run in CI
 * without a database, a broker or Redis.
 */
import { readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import "reflect-metadata";

const SRC = join(__dirname, "..", "src");
const GLOBAL_PREFIX = "v1";

/** Mirrors @nestjs/common's RequestMethod enum ordering. */
const METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "ALL", "OPTIONS", "HEAD", "SEARCH"];

/**
 * Only files that can declare a controller. Importing main.ts would boot the
 * application, which is exactly what this script exists to avoid — some
 * controllers are declared inline in their module file, so both are scanned.
 */
function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) return sourceFiles(full);
    // app.module.ts declares no controllers and calls ConfigModule.forRoot(),
    // which validates the environment on import — this script must run in CI
    // without one.
    if (full.endsWith("app.module.ts")) return [];
    return full.endsWith(".controller.ts") || full.endsWith(".module.ts") ? [full] : [];
  });
}

function joinPath(...parts: string[]): string {
  const path = parts
    .map((part) => part.replace(/^\/+|\/+$/g, ""))
    .filter(Boolean)
    .join("/");
  return `/${path}`;
}

export async function listRoutes(): Promise<string[]> {
  const routes = new Set<string>();

  for (const file of sourceFiles(SRC)) {
    let module: Record<string, unknown>;
    try {
      module = (await import(file)) as Record<string, unknown>;
    } catch {
      continue; // not importable in isolation; it cannot be a controller either
    }

    for (const exported of Object.values(module)) {
      if (typeof exported !== "function") continue;

      const controllerPath: string | undefined = Reflect.getMetadata("path", exported);
      // Every class carries a `path`; only controllers carry one plus routed
      // methods, which is what distinguishes them here.
      if (controllerPath === undefined) continue;

      const proto = (exported as { prototype?: object }).prototype;
      if (!proto) continue;

      for (const name of Object.getOwnPropertyNames(proto)) {
        if (name === "constructor") continue;
        const handler = (proto as Record<string, unknown>)[name];
        if (typeof handler !== "function") continue;

        const methodPath: string | undefined = Reflect.getMetadata("path", handler);
        const methodIndex: number | undefined = Reflect.getMetadata("method", handler);
        if (methodPath === undefined || methodIndex === undefined) continue;

        routes.add(
          `${METHODS[methodIndex] ?? "GET"} ${joinPath(GLOBAL_PREFIX, controllerPath, methodPath)}`,
        );
      }
    }
  }

  return [...routes].sort();
}

if (require.main === module) {
  void listRoutes().then((routes) => {
    for (const route of routes) console.log(route);
  });
}
