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

const exactFormatter = new Intl.NumberFormat('ar-JO-u-nu-latn', { minimumFractionDigits: 3, maximumFractionDigits: 3 });

/** Always three decimals (fils), for rates such as the commission: "0.200 د.أ". */
export function formatMoneyExact(fils: Money): string {
  return `${exactFormatter.format(filsToJod(fils))} د.أ`;
}

/** Editable text for an amount: at least two decimals, the third only when it is used ("50.00", "12.125"). */
export function formatJodInput(fils: Money): string {
  const whole = Math.floor(fils / FILS_PER_JOD);
  const fraction = String(fils % FILS_PER_JOD).padStart(3, '0');
  return `${whole}.${fraction.endsWith('0') ? fraction.slice(0, 2) : fraction}`;
}

export type JodParse = { ok: true; fils: Money } | { ok: false; reason: 'empty' | 'malformed' | 'ambiguous' | 'precision' };

const ARABIC_INDIC_DIGITS = '٠١٢٣٤٥٦٧٨٩';
const PERSIAN_DIGITS = '۰۱۲۳۴۵۶۷۸۹';
const MAX_FRACTION_DIGITS = 3;

/** Invisible direction marks that come along when an amount is copied from RTL text. */
const stripMarks = (raw: string) => raw.replace(/[؜​-‏‪-‮⁦-⁩﻿]/g, '').trim();

/**
 * Removes thousands separators and turns a decimal comma into a point. JOD has three
 * decimals, so "1,500" could mean 1.5 or 1500: it is reported, never guessed.
 */
function resolveSeparators(text: string): string | Extract<JodParse, { ok: false }> {
  if (text.includes('٬')) {
    return /^\d{1,3}(٬\d{3})+(\.\d*)?$/.test(text) ? text.replace(/٬/g, '') : { ok: false, reason: 'malformed' };
  }
  if (!text.includes(',')) return text;
  if (/^\d+,\d{1,2}$/.test(text)) return text.replace(',', '.');
  if (/^\d{1,3},\d{3}$/.test(text)) return { ok: false, reason: 'ambiguous' };
  if (/^\d{1,3}(,\d{3})+\.\d*$/.test(text) || /^\d{1,3}(,\d{3}){2,}$/.test(text)) return text.replace(/,/g, '');
  return { ok: false, reason: 'malformed' };
}

/**
 * Parses typed or pasted JOD text into integer fils without going through a float, accepting
 * Western, Arabic-Indic and Persian digits and the normal in-progress forms "50." and ".5".
 */
export function parseJodAmount(raw: string): JodParse {
  const text = stripMarks(raw)
    .replace(/[٠-٩]/g, (d) => String(ARABIC_INDIC_DIGITS.indexOf(d)))
    .replace(/[۰-۹]/g, (d) => String(PERSIAN_DIGITS.indexOf(d)))
    .replace(/٫/g, '.')
    .replace(/،/g, ',');
  if (!text) return { ok: false, reason: 'empty' };

  const plain = resolveSeparators(text);
  if (typeof plain !== 'string') return plain;

  const match = /^(\d*)(?:\.(\d*))?$/.exec(plain);
  if (!match || (!match[1] && !match[2])) return { ok: false, reason: 'malformed' };
  const [, whole, fraction = ''] = match;
  if (fraction.length > MAX_FRACTION_DIGITS) return { ok: false, reason: 'precision' };

  const fils = Number(whole || '0') * FILS_PER_JOD + Number(fraction.padEnd(MAX_FRACTION_DIGITS, '0'));
  return Number.isSafeInteger(fils) ? { ok: true, fils } : { ok: false, reason: 'malformed' };
}

/** `parseJodAmount` for callers that only need the amount or null ("2", "1.5", "١٫٥"). */
export function parseJodInput(raw: string): Money | null {
  const parsed = parseJodAmount(raw);
  return parsed.ok ? parsed.fils : null;
}
