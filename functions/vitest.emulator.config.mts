import {defineConfig} from "vitest/config";

// The emulator holds shared state: run files one at a time.
export default defineConfig({
  test: {
    include: ["test/rules/**/*.test.ts", "test/integration/**/*.test.ts"],
    fileParallelism: false,
    testTimeout: 20_000,
    hookTimeout: 20_000,
  },
});
