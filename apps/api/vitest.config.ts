import { defineConfig } from "vitest/config";

export default defineConfig({
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
