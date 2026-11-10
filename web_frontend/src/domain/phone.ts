// Telephone numbers (FU-1.2 §1.3): exactly 10 digits when supplied, leading zero kept.
// Applies to phone fields only — never to prices, amounts, coordinates, counts or IDs.

export const PHONE_DIGITS = 10;
export const PHONE_ERROR = 'رقم الهاتف يجب أن يتكوّن من 10 أرقام.';

const ARABIC_INDIC = /[٠-٩۰-۹]/g;

/**
 * Normalisation rule: Arabic-Indic digits become Latin digits and every other
 * character (spaces, dashes, brackets, "+") is dropped. The value stays a string.
 */
export function normalizePhone(raw: string): string {
  return raw
    .replace(ARABIC_INDIC, (ch) => String(ch.charCodeAt(0) - (ch >= '۰' ? 0x06f0 : 0x0660)))
    .replace(/\D/g, '');
}

export const isValidPhone = (raw: string): boolean => new RegExp(`^\\d{${PHONE_DIGITS}}$`).test(normalizePhone(raw));

/** Optional field: blank is valid, a supplied value must be 10 digits. */
export const isValidOptionalPhone = (raw: string | undefined): boolean => !raw?.trim() || isValidPhone(raw);
