import { ACCOUNT_PASSWORD_REQUIRED, isAccountPasswordAcceptable } from '@/domain/account';
import { Field, FormRow, FormSection, Input, PasswordField } from '@/shared/components/ui';

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
 * Login credentials section shared by «إضافة تاجر» and «إضافة كابتن»: «اسم المستخدم» for sign-in (separate
 * from the store/Captain display name; its rule sits in the hint below the field) and a masked password with show/hide.
 */
export function AccountCredentialsFields({
  idPrefix,
  username,
  password,
  errors,
  onChange,
}: {
  idPrefix: string;
  username: string;
  password: string;
  errors: CredentialErrors;
  onChange: (patch: { username?: string; password?: string }) => void;
}) {
  return (
    <FormSection title="بيانات الدخول (تجريبية)">
      <FormRow>
        <Field label="اسم المستخدم" required htmlFor={`${idPrefix}-username`} error={errors.username} hint={errors.username ? undefined : 'لتسجيل الدخول: أحرف إنجليزية أو أرقام، ولا يتكرر بين الحسابات'}>
          <Input id={`${idPrefix}-username`} value={username} onChange={(e) => onChange({ username: e.target.value })} dir="ltr" autoComplete="off" aria-invalid={!!errors.username} aria-describedby={`${idPrefix}-username-msg`} className="rtl:text-right" />
        </Field>
        <Field label="كلمة المرور" required htmlFor={`${idPrefix}-password`} error={errors.password}>
          <PasswordField id={`${idPrefix}-password`} value={password} onChange={(e) => onChange({ password: e.target.value })} autoComplete="new-password" aria-invalid={!!errors.password} aria-describedby={errors.password ? `${idPrefix}-password-msg` : undefined} />
        </Field>
      </FormRow>
    </FormSection>
  );
}
