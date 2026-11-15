// Scenario harness for tests/logic.test.ts: the scenario runs top to bottom against one store,
// and every check() becomes its own named Vitest test (the condition is captured when reached).
import { expect, test } from 'vitest';

let current = '';

export function section(title: string) {
  current = title;
}

export function check(condition: unknown, message: string) {
  const ok = !!condition;
  test(current ? `${current} › ${message}` : message, () => {
    expect(ok, message).toBe(true);
  });
}

/** Kept for the scenario file's last line; Vitest reports the totals. */
export function finish() {}
