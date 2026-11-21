import { Logo } from '@/shared/components/Logo';
import { LOGIN_SLOGAN, LOGIN_TITLE } from './LoginBrand';

/** Form heading. The logo, title and tagline show here only on mobile, where the brand panel is hidden. */
export function LoginHeader() {
  return (
    <header className="mb-5 md:mb-8">
      <div className="mb-4 md:hidden">
        <Logo className="h-[3.375rem]" />
        <p className="mt-3 text-2xl font-bold leading-snug text-secondary">{LOGIN_TITLE}</p>
        <p className="mt-1 text-balance text-base font-medium leading-relaxed text-primary">{LOGIN_SLOGAN}</p>
      </div>
      <h1 className="text-[1.75rem] font-extrabold leading-tight text-ink">تسجيل الدخول</h1>
      <p className="mt-2 text-[15px] leading-relaxed text-ink-soft">أدخل بيانات حسابك للمتابعة.</p>
    </header>
  );
}
