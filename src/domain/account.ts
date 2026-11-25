// Account identity rules shared by the Admin forms and the store (one rule, one message).

/** Login username syntax (unchanged): 3–30 English letters, digits, «.», «_» or «-». */
export const USERNAME_PATTERN = /^[a-zA-Z0-9._-]{3,30}$/;
export const USERNAME_INVALID = 'اسم المستخدم: 3 أحرف إنجليزية أو أرقام على الأقل';
export const USERNAME_TAKEN = 'اسم المستخدم مستخدم مسبقاً. اختر اسم مستخدم آخر.';

/** Usernames are stored without outer spaces; that trimmed value is what users see. */
export const normalizeUsername = (username: string) => username.trim();
/**
 * The one comparison key for login and uniqueness: outer spaces removed, case-insensitive. Every
 * Merchant, Captain and the Admin share one namespace.
 */
export const canonicalUsername = (username: string) => username.trim().toLowerCase();
export const isValidUsername = (username: string) => USERNAME_PATTERN.test(normalizeUsername(username));

/**
 * Password reset temporary passwords: 6+ characters. Account creation no longer uses it.
 */
export const PASSWORD_MIN_LENGTH = 6;
export const PASSWORD_TOO_SHORT = `كلمة المرور ${PASSWORD_MIN_LENGTH} أحرف على الأقل`;
export const isPasswordLongEnough = (password: string): boolean => password.length >= PASSWORD_MIN_LENGTH;

/**
 * Merchant and Captain account passwords (owner, 2026-11-25): one rule for both — any non-empty
 * value, any characters, kept exactly as typed (never trimmed). A whitespace-only password is
 * non-empty and therefore accepted, identically in both flows. Prototype only: a production
 * identity provider keeps its own policy.
 */
export const ACCOUNT_PASSWORD_REQUIRED = 'كلمة المرور مطلوبة';
export const isAccountPasswordAcceptable = (password: string): boolean => password.length > 0;
