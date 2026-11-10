// Minimal check-style harness (no test framework, per CLAUDE.md).
let failures = 0;
let total = 0;

export function section(title: string) {
  console.log(`\n— ${title}`);
}

export function check(condition: unknown, message: string) {
  total++;
  if (!condition) failures++;
  console.log(`${condition ? 'PASS' : 'FAIL'}  ${message}`);
}

/** Prints the summary; throws so Node exits non-zero when anything failed. */
export function finish() {
  if (failures) throw new Error(`${failures} of ${total} check(s) failed`);
  console.log(`\nALL ${total} CHECKS PASSED`);
}
