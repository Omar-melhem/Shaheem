import { Link } from 'react-router-dom';
import { LayoutDashboard, Smartphone, Store, ArrowLeft } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Logo } from '@/shared/components/Logo';
import { Card, SimTag } from '@/shared/components/ui';

export function LandingPage() {
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);

  return (
    <div className="mx-auto max-w-5xl px-4 py-10">
      <div className="flex flex-col items-center text-center">
        <Logo className="h-32" />
        <h1 className="mt-4 text-3xl font-extrabold text-ink">منصة إدارة عمليات التوصيل للأعمال</h1>
        <p className="mt-2 max-w-2xl text-ink-muted">
          شهم تربط المطاعم والمقاهي والمتاجر بكباتن التوصيل: تسعير حسب المنطقة لكل تاجر، توزيع يُفضّل الكابتن الأقرب إلى التاجر، وتتبع أثناء التوصيل.
        </p>
        <div className="mt-3">
          <SimTag>نموذج تجريبي تفاعلي — جميع البيانات والمواقع محاكاة</SimTag>
        </div>
      </div>

      <div className="mt-10 grid gap-5 md:grid-cols-3">
        <Card className="flex flex-col p-6">
          <div className="mb-3 w-fit rounded-xl bg-primary-50 p-3 text-primary">
            <LayoutDashboard className="h-6 w-6" />
          </div>
          <h2 className="text-lg font-bold">لوحة الإدارة</h2>
          <p className="mt-1 flex-1 text-sm text-ink-muted">التجار والكباتن، المناطق والأسعار، مركز التوزيع، الخريطة الحية، والمحافظ.</p>
          <Link to="/admin" className="mt-4 inline-flex h-10 items-center justify-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-white hover:bg-primary-600">
            الدخول كمدير (تجريبي) <ArrowLeft className="h-4 w-4" />
          </Link>
        </Card>

        <Card className="flex flex-col p-6">
          <div className="mb-3 w-fit rounded-xl bg-secondary-50 p-3 text-secondary">
            <Store className="h-6 w-6" />
          </div>
          <h2 className="text-lg font-bold">بوابة التاجر</h2>
          <p className="mt-1 text-sm text-ink-muted">شاشة واحدة: طلب كابتن، الطلب النشط، وسجل الطلبات.</p>
          <ul className="mt-3 flex-1 space-y-1.5">
            {merchants.map((m) => (
              <li key={m.id}>
                <Link to={`/merchant/${m.id}`} className="flex items-center justify-between rounded-lg px-3 py-2 text-sm hover:bg-cream">
                  <span className="font-medium">{m.businessName}</span>
                  {m.status !== 'active' && <span className="text-xs text-red-700">غير مفعّل</span>}
                </Link>
              </li>
            ))}
          </ul>
        </Card>

        <Card className="flex flex-col p-6">
          <div className="mb-3 w-fit rounded-xl bg-sand-light/60 p-3 text-sand-dark">
            <Smartphone className="h-6 w-6" />
          </div>
          <h2 className="text-lg font-bold">تطبيق الكابتن</h2>
          <p className="mt-1 text-sm text-ink-muted">معاينة محاكاة لتطبيق Android و iOS: العروض، التوصيل النشط، السجل، والمحفظة.</p>
          <ul className="mt-3 flex-1 space-y-1.5">
            {captains.map((c) => (
              <li key={c.id}>
                <Link to={`/captain/${c.id}`} className="flex items-center justify-between rounded-lg px-3 py-2 text-sm hover:bg-cream">
                  <span className="font-medium">{c.fullName}</span>
                  {c.status !== 'active' && <span className="text-xs text-red-700">موقوف</span>}
                </Link>
              </li>
            ))}
          </ul>
        </Card>
      </div>

      <p className="mt-8 text-center text-xs text-ink-muted">
        نصيحة للعرض: افتح الإدارة والتاجر والكابتن في تبويبات منفصلة في نفس المتصفح — تتزامن الحالة بينها تلقائياً.
      </p>
    </div>
  );
}
