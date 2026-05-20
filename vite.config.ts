import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/family-memories/",
  plugins: [react()],
  test: {
    exclude: ["**/.worktrees/**", "**/node_modules/**", "**/dist/**"],
    environment: "jsdom",
    setupFiles: "./src/test/setup.ts"
  }
});
