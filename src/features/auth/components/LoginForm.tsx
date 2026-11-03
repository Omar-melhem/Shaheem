import { useRef, useState, type FormEvent } from 'react';
import { AlertCircle } from 'lucide-react';
import { Button, Field, Input, PasswordField, fieldMessageId } from '@/shared/components/ui';
import { useDemoSignIn } from '../hooks/useDemoSignIn';

type Errors = { username?: string; password?: string; form?: string };

/** Username + password sign-in. Role routing comes from the authenticated account, never a UI choice. */
export function LoginForm() {
  const signInWith = useDemoSignIn();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<Errors>({});
  const [submitting, setSubmitting] = useState(false);
  const usernameRef = useRef<HTMLInputElement>(null);
  const passwordRef = useRef<HTMLInputElement>(null);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (submitting) return;
    const next: Errors = {};
    if (!username.trim()) next.username = 'أدخل اسم المستخدم';
    if (!password) next.password = 'أدخل كلمة المرور';
    setErrors(next);
    if (next.username) return usernameRef.current?.focus();
    if (next.password) return passwordRef.current?.focus();

    setSubmitting(true);
    // Short pause stands in for the network round-trip so the loading state is visible (demo).
    window.setTimeout(() => {
      const result = signInWith(username, password);
      if (!result.ok) {
        setSubmitting(false);
        setErrors({ form: result.error });
        passwordRef.current?.select();
      }
    }, 350);
  };

  const describedBy = (field: 'username' | 'password') => (errors[field] ? fieldMessageId(`login-${field}`) : undefined);

  return (
    <form onSubmit={submit} noValidate className="space-y-5" aria-describedby={errors.form ? 'login-form-error' : undefined}>
      {errors.form && (
        <p id="login-form-error" role="alert" className="flex items-start gap-2 rounded-xl bg-red-50 px-3 py-2.5 text-sm font-medium text-red-800">
          <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
          {errors.form}
        </p>
      )}
      <Field label="اسم المستخدم" htmlFor="login-username" error={errors.username}>
        <Input
          ref={usernameRef}
          id="login-username"
          name="username"
          className="h-12"
          dir="ltr"
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
      </Field>
      <Field label="كلمة المرور" htmlFor="login-password" error={errors.password}>
        <PasswordField
          ref={passwordRef}
          id="login-password"
          name="password"
          className="h-12"
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          aria-invalid={!!errors.password || !!errors.form}
          aria-describedby={describedBy('password')}
          disabled={submitting}
        />
      </Field>
      <Button type="submit" size="lg" className="w-full" loading={submitting}>
        {submitting ? 'جارٍ الدخول…' : 'دخول'}
      </Button>
    </form>
  );
}
