import { describe, expect, it } from 'vitest';
import { formatCountdown, formatDate, formatDateTime, formatRelative, formatTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

describe('formatRelative', () => {
  const now = Date.UTC(2026, 10, 9, 12);
  it.each([
    [5_000, 'الآن'],
    [-60_000, 'الآن'], // future timestamps never go negative
    [30_000, 'منذ 30 ث'],
    [5 * 60_000, 'منذ 5 د'],
    [3 * 3_600_000, 'منذ 3 س'],
  ])('%i ms ago → %s', (ago, text) => {
    expect(formatRelative(now - ago, now)).toBe(text);
  });

  it('falls back to a date after a day', () => {
    expect(formatRelative(now - 2 * 86_400_000, now)).toBe(formatDateTime(now - 2 * 86_400_000));
  });
});

describe('formatCountdown', () => {
  it.each([
    [60_000, '1:00'],
    [59_001, '1:00'],
    [9_000, '0:09'],
    [-5, '0:00'],
  ])('%i ms → %s', (ms, text) => {
    expect(formatCountdown(ms)).toBe(text);
  });
});

describe('date formatters use Latin digits', () => {
  it('formats without Arabic-Indic digits', () => {
    const ts = Date.UTC(2026, 10, 9, 12, 5);
    for (const s of [formatDateTime(ts), formatTime(ts), formatDate(ts)]) expect(s).not.toMatch(/[٠-٩]/);
    expect(formatDate(ts)).toContain('2026');
  });
});

describe('cn', () => {
  it('joins truthy class names', () => {
    expect(cn('a', false, null, undefined, 'b', { c: true, d: false })).toBe('a b c');
  });
});
