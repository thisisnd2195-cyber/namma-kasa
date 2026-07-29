import { defineConfig } from "vitest/config";
import swc from "unplugin-swc";
import { fileURLToPath } from "node:url";

export default defineConfig({
  // Nest resolves constructor dependencies from `design:paramtypes`, which
  // esbuild does not emit. Without SWC, booting the real AppModule in a test
  // injects undefined for every dependency.
  plugins: [
    swc.vite({
      jsc: { transform: { legacyDecorator: true, decoratorMetadata: true } },
    }),
  ],
  resolve: {
    // Point at the shared package's source rather than its CJS dist. Left as
    // dist it pulls in a second copy of zod, so a ZodError thrown by a shared
    // schema is not an instance of the ZodError ProblemFilter checks — and
    // every validation failure renders 500 instead of 422 under test. The
    // compiled server is all CommonJS and has no such split.
    alias: {
      "@namma-kasa/shared": fileURLToPath(
        new URL("../../packages/shared/src/index.ts", import.meta.url),
      ),
    },
  },
  test: {
    globals: true,
    environment: "node",
    include: ["test/**/*.spec.ts"],
    // Schema tests share one database; run files serially so migrations and
    // transactional fixtures never interleave.
    fileParallelism: false,
    testTimeout: 30_000,

  },
});
