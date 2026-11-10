import { Logo } from '@/shared/components/Logo';
import { InfoTooltip } from '@/shared/components/ui';

/** Form heading. The logo shows here only on mobile, where the brand panel is hidden. */
export function LoginHeader() {
  return (
    <header className="mb-8">
      <Logo className="mb-8 h-16 md:hidden" />
      <h1 className="text-[1.75rem] font-extrabold leading-tight text-ink">تسجيل الدخول</h1>
      <p className="mt-2 flex items-center gap-1.5 text-[15px] leading-relaxed text-ink-soft">
        أدخل بيانات حسابك للمتابعة.
        <InfoTooltip label="معلومات الحساب" text="للحصول على معلومات الحساب، يُرجى التواصل مع إدارة شهم." />
      </p>
    </header>
  );
}
