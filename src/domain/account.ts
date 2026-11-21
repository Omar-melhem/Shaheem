// Demo account rules shared by the Admin forms and the store (one rule, one message).

export const PASSWORD_MIN_LENGTH = 6;
export const PASSWORD_TOO_SHORT = `كلمة المرور ${PASSWORD_MIN_LENGTH} أحرف على الأقل`;

export const isPasswordLongEnough = (password: string): boolean => password.length >= PASSWORD_MIN_LENGTH;
