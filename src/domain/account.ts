// Demo account rules shared by the Admin forms and the store (one rule, one message).

export const PASSWORD_MIN_LENGTH = 6;
export const PASSWORD_TOO_SHORT = `كلمة المرور ${PASSWORD_MIN_LENGTH} أحرف على الأقل`;

export const isPasswordLongEnough = (password: string): boolean => password.length >= PASSWORD_MIN_LENGTH;

/**
 * Merchant accounts (owner, 2026-11-25): any non-empty password — no length or composition rule,
 * any characters, kept exactly as typed (never trimmed). Captains and password resets keep
 * `isPasswordLongEnough`. Prototype only: a production identity provider keeps its own policy.
 */
export const MERCHANT_PASSWORD_REQUIRED = 'كلمة المرور مطلوبة';
export const isMerchantPasswordAcceptable = (password: string): boolean => password.length > 0;
