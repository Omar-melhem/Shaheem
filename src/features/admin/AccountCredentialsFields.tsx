import { useEffect, useRef } from 'react';
import { ACCOUNT_PASSWORD_REQUIRED, isAccountPasswordAcceptable } from '@/domain/account';
import { Field, Input, PasswordField } from '@/shared/components/ui';

export interface CredentialErrors {
  username?: string;
  password?: string;
}

/** Instant form checks (the store re-checks syntax and the global uniqueness). */
export function credentialFieldErrors(creds: { username: string; password: string }): CredentialErrors {
  return {
    username: creds.username.trim() ? undefined : 'اسم المستخدم مطلوب',
    password: isAccountPasswordAcceptable(creds.password) ? undefined : ACCOUNT_PASSWORD_REQUIRED,
  };
}

/** Which credentials field a failed create/update belongs to, from its typed code. */
export function credentialFieldOf(code: string | undefined): keyof CredentialErrors | null {
  if (code === 'username_taken' || code === 'username_invalid') return 'username';
  if (code === 'password_required') return 'password';
  return null;
}

/**
 * Login credentials block shared by «إضافة تاجر» and «إضافة كابتن»: username for sign-in (separate from
 * the store/Captain display name) and a masked password with show/hide. `focusAttempt` changes on
 * each failed submit; the first invalid credential field then receives focus.
 */
export function AccountCredentialsFields({
  idPrefix,
  username,
  password,
  errors,
  focusAttempt,
  onChange,
}: {
  idPrefix: string;
  username: string;
  password: string;
  errors: CredentialErrors;
  focusAttempt: number;
  onChange: (patch: { username?: string; password?: string }) => void;
}) {
  const usernameRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (focusAttempt === 0) return;
    if (errors.username) usernameRef.current?.focus();
    else if (errors.password) passwordRef.current?.focus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [focusAttempt]);

  return (
    <div className="rounded-xl border border-dashed border-sand-dark/50 bg-sand-light/20 p-4 md:col-span-2">
      <p className="mb-3 text-sm font-bold text-ink">بيانات الدخول (تجريبية)</p>
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="اسم المستخدم لتسجيل الدخول" required htmlFor={`${idPrefix}-username`} error={errors.username} hint={errors.username ? undefined : 'أحرف إنجليزية أو أرقام، ولا يتكرر بين الحسابات'}>
          <Input ref={usernameRef} id={`${idPrefix}-username`} value={username} onChange={(e) => onChange({ username: e.target.value })} dir="ltr" autoComplete="off" aria-invalid={!!errors.username} className="rtl:text-right" />
        </Field>
        <Field label="كلمة المرور" required htmlFor={`${idPrefix}-password`} error={errors.password}>
          <PasswordField ref={passwordRef} id={`${idPrefix}-password`} value={password} onChange={(e) => onChange({ password: e.target.value })} autoComplete="new-password" aria-invalid={!!errors.password} />
        </Field>
      </div>
    </div>
  );
}
