import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

// Unit tests: Node by default (domain/application); component tests opt into jsdom with
// `// @vitest-environment jsdom` at the top of the file.
export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      include: ['tests/**/*.test.{ts,tsx}'],
      environment: 'node',
      setupFiles: ['tests/setup.ts'],
      restoreMocks: true,
      coverage: {
        provider: 'v8',
        include: ['src/domain/**', 'src/application/**', 'src/shared/**', 'src/infrastructure/**'],
        exclude: ['src/**/*.d.ts', 'src/domain/types.ts', 'src/infrastructure/seed.ts'],
        reporter: ['text-summary', 'text', 'html'],
        reportsDirectory: 'coverage',
        // Floors just under the measured level (2026-11-15: 95% lines, 90% branches); raise, never lower.
        thresholds: { lines: 90, statements: 90, functions: 90, branches: 85 },
      },
    },
  }),
);
