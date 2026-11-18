import { Logo } from '@/shared/components/Logo';
import { InfoTooltip } from '@/shared/components/ui';
import { LOGIN_SLOGAN, LOGIN_TITLE, LoginCar } from './LoginBrand';

/**
 * Form heading. On phones (no brand panel) a compact brand row comes first: logo, then the car
 * beside «شهم درايف» and the slogan, kept short so the fields stay on the first screen.
 */
export function LoginHeader() {
  return (
    <header className="mb-6 md:mb-8">
      <div className="mb-6 flex items-center gap-3 md:hidden">
        <div className="min-w-0 flex-1">
          <Logo className="mb-2 h-10" />
          <p className="text-2xl font-extrabold leading-tight text-primary">{LOGIN_TITLE}</p>
          <p className="mt-1 text-sm font-bold leading-snug text-secondary">{LOGIN_SLOGAN}</p>
        </div>
        <LoginCar compact />
      </div>
      <h1 className="text-[1.75rem] font-extrabold leading-tight text-ink">تسجيل الدخول</h1>
      <p className="mt-2 flex items-center gap-1.5 text-[15px] leading-relaxed text-ink-soft">
        أدخل بيانات حسابك للمتابعة.
        <InfoTooltip label="معلومات الحساب" text="للحصول على معلومات الحساب، يُرجى التواصل مع إدارة شهم." />
      </p>
    </header>
  );
}
