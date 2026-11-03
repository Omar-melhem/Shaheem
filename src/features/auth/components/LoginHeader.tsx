import { Logo } from '@/shared/components/Logo';

/** Form heading. The logo shows here only on mobile, where the brand panel is hidden. */
export function LoginHeader() {
  return (
    <header className="mb-8">
      <Logo className="mb-8 h-16 md:hidden" />
      <h1 className="text-3xl font-extrabold text-ink">تسجيل الدخول</h1>
      <p className="mt-2 text-sm text-ink-muted">أدخل بيانات حسابك للمتابعة</p>
    </header>
  );
}
