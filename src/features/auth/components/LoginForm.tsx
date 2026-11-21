import { useEffect, useRef, useState, type FormEvent } from 'react';
import { AlertCircle, LockKeyhole, UserRound } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { Button, Field, INPUT_ICON_PAD, Input, InputIcon, PasswordField, fieldMessageId } from '@/shared/components/ui';
import { useDemoSignIn } from '../hooks/useDemoSignIn';
import { ForgotPasswordHelp } from './ForgotPasswordHelp';

type Errors = { username?: string; password?: string; form?: string };

export const USERNAME_REQUIRED = 'اسم المستخدم مطلوب';
export const PASSWORD_REQUIRED = 'كلمة المرور مطلوبة';

/**
 * Username + password sign-in. Labels stay visible; placeholders are hints only. Role routing comes
 * from the authenticated account, never a UI choice. After an empty submit focus goes to the first
 * invalid field; after a failed sign-in the password is cleared and focused. The error slot keeps
 * its height so the form never jumps.
 */
export function LoginForm() {
  const signInWith = useDemoSignIn();
  // A genuine configured demo account only; never an invented one (CR v1.3 §2.2).
  const demoUsername = useAppStore((s) => s.merchants[0]?.username);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<Errors>({});
  const [submitting, setSubmitting] = useState(false);
  /** Bumped on every rejected attempt so focus moves after the errors have rendered. */
  const [attempt, setAttempt] = useState(0);
  const usernameRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (attempt === 0) return;
    if (errors.username) usernameRef.current?.focus();
    else passwordRef.current?.focus();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [attempt]);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (submitting) return;
    const next: Errors = {};
    if (!username.trim()) next.username = USERNAME_REQUIRED;
    if (!password) next.password = PASSWORD_REQUIRED;
    setErrors(next);
    if (next.username || next.password) return setAttempt((n) => n + 1);

    setSubmitting(true);
    // Short pause stands in for the network round-trip so the loading state is visible (demo).
    window.setTimeout(() => {
      const result = signInWith(username, password);
      if (!result.ok) {
        setSubmitting(false);
        setPassword('');
        setErrors({ form: result.error });
        setAttempt((n) => n + 1);
      }
    }, 350);
  };

  const describedBy = (field: 'username' | 'password') => (errors[field] ? fieldMessageId(`login-${field}`) : undefined);

  return (
    <form onSubmit={submit} noValidate className="space-y-5" aria-describedby={errors.form ? 'login-form-error' : undefined}>
      <Field label="اسم المستخدم" htmlFor="login-username" error={errors.username}>
        <InputIcon icon={<UserRound />}>
          <Input
            ref={usernameRef}
            id="login-username"
            name="username"
            className={`h-12 rtl:text-right ${INPUT_ICON_PAD}`}
            dir="ltr"
            placeholder={demoUsername ?? ''}
            autoComplete="username"
            autoCapitalize="none"
            spellCheck={false}
            autoFocus
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            aria-invalid={!!errors.username || !!errors.form}
            aria-describedby={describedBy('username')}
            disabled={submitting}
          />
        </InputIcon>
      </Field>
      <Field label="كلمة المرور" htmlFor="login-password" error={errors.password}>
        <PasswordField
          ref={passwordRef}
          id="login-password"
          name="password"
          className="h-12"
          icon={<LockKeyhole />}
          placeholder="أدخل كلمة المرور"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          aria-invalid={!!errors.password || !!errors.form}
          aria-describedby={describedBy('password')}
          disabled={submitting}
        />
      </Field>
      <div className="-mt-2">
        <ForgotPasswordHelp />
        {/* Reserved slot: the sign-in error appears here without pushing the form down. */}
        <div className="mt-1 min-h-[2.5rem]" aria-live="polite">
          {errors.form && (
            <p id="login-form-error" role="alert" className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2 text-sm font-medium text-red-800">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
              {errors.form}
            </p>
          )}
        </div>
      </div>
      <Button type="submit" size="lg" className="!mt-3 w-full" loading={submitting}>
        {submitting ? 'جارٍ الدخول…' : 'دخول'}
      </Button>
    </form>
  );
}
