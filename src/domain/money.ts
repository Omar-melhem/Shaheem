import type { Money } from './types';

export const FILS_PER_JOD = 1000;

export const jodToFils = (jod: number): Money => Math.round(jod * FILS_PER_JOD);
export const filsToJod = (fils: Money): number => fils / FILS_PER_JOD;

const formatter = new Intl.NumberFormat('ar-JO-u-nu-latn', {
  minimumFractionDigits: 2,
  maximumFractionDigits: 3,
});

export function formatMoney(fils: Money): string {
  return `${formatter.format(filsToJod(fils))} د.أ`;
}

const ARABIC_DIGITS = '٠١٢٣٤٥٦٧٨٩';

/** Parses a user-entered JOD amount ("2", "1.5", "١٫٥") into fils, or null. */
export function parseJodInput(raw: string): Money | null {
  const normalized = raw
    .trim()
    .replace(/[٠-٩]/g, (d) => String(ARABIC_DIGITS.indexOf(d)))
    .replace('٫', '.')
    .replace(',', '.');
  if (!/^\d+(\.\d{1,3})?$/.test(normalized)) return null;
  return jodToFils(Number(normalized));
}
