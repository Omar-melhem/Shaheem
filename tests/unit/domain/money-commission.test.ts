import { describe, expect, it } from 'vitest';
import { filsToJod, formatJodInput, formatMoney, formatMoneyExact, jodToFils, parseJodAmount, parseJodInput } from '@/domain/money';
import { DEFAULT_COMMISSION_BP, commissionFils, formatPercentBp, isValidCommissionBp } from '@/domain/commission';

describe('money (integer fils)', () => {
  it('converts JOD to fils without float drift', () => {
    expect(jodToFils(1.5)).toBe(1_500);
    expect(jodToFils(0.1 + 0.2)).toBe(300);
    expect(filsToJod(1_250)).toBe(1.25);
  });

  it('formats with two to three decimals and the JOD sign', () => {
    expect(formatMoney(1_500)).toBe('1.50 د.أ');
    expect(formatMoney(12_125)).toBe('12.125 د.أ');
  });

  it('formatMoneyExact always shows three decimals', () => {
    expect(formatMoneyExact(200)).toBe('0.200 د.أ');
  });

  it('formatJodInput keeps two decimals and the third only when used', () => {
    expect(formatJodInput(50_000)).toBe('50.00');
    expect(formatJodInput(12_125)).toBe('12.125');
    expect(formatJodInput(5)).toBe('0.005');
  });
});

describe('parseJodAmount', () => {
  it.each([
    ['2', 2_000],
    ['1.5', 1_500],
    ['50.', 50_000],
    ['.5', 500],
    ['١٫٥', 1_500],
    ['۲.۲۵', 2_250],
    ['1,25', 1_250],
    ['1,500.5', 1_500_500],
    ['1,000,000', 1_000_000_000],
    ['١٬٥٠٠', 1_500_000],
    ['‏3.000‎', 3_000],
  ])('parses %j as %i fils', (raw, fils) => {
    expect(parseJodAmount(raw)).toEqual({ ok: true, fils });
  });

  it.each([
    ['', 'empty'],
    ['   ', 'empty'],
    ['1,500', 'ambiguous'],
    ['1.2345', 'precision'],
    ['abc', 'malformed'],
    ['.', 'malformed'],
    ['1,2,3', 'malformed'],
    ['12٬34', 'malformed'],
    ['-1', 'malformed'],
  ])('rejects %j as %s', (raw, reason) => {
    expect(parseJodAmount(raw)).toEqual({ ok: false, reason });
  });

  it('rejects amounts beyond safe integer fils', () => {
    expect(parseJodAmount('99999999999999999')).toEqual({ ok: false, reason: 'malformed' });
  });

  it('parseJodInput returns fils or null', () => {
    expect(parseJodInput('2.5')).toBe(2_500);
    expect(parseJodInput('1,500')).toBeNull();
  });
});

describe('commission (percentage of the delivery-fee snapshot)', () => {
  it('proposed rate is 20% in basis points', () => {
    expect(DEFAULT_COMMISSION_BP).toBe(2_000);
    expect(formatPercentBp(DEFAULT_COMMISSION_BP)).toBe('20%');
    expect(formatPercentBp(1_250)).toBe('12.5%');
  });

  it('validates the rate range', () => {
    expect(isValidCommissionBp(0)).toBe(true);
    expect(isValidCommissionBp(10_000)).toBe(true);
    expect(isValidCommissionBp(10_001)).toBe(false);
    expect(isValidCommissionBp(-1)).toBe(false);
    expect(isValidCommissionBp(12.5)).toBe(false);
  });

  it('rounds half up to the nearest fils', () => {
    expect(commissionFils(1_500, 2_000)).toBe(300);
    expect(commissionFils(1_250, 1_250)).toBe(156); // 156.25 → 156
    expect(commissionFils(1_004, 1_250)).toBe(126); // 125.5 → 126
  });

  it('throws on an invalid fee or rate', () => {
    expect(() => commissionFils(-1, 2_000)).toThrow(RangeError);
    expect(() => commissionFils(1.5, 2_000)).toThrow(RangeError);
    expect(() => commissionFils(1_000, 20_000)).toThrow(RangeError);
  });
});
