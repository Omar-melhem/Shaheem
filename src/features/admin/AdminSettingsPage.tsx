import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Headphones, Info, Languages, LogOut, Map as MapIcon, RadioTower, Store, UserCog, Wallet } from 'lucide-react';
import { version } from '../../../package.json';
import { useAppStore, DEMO_ADMIN } from '@/application/store';
import { MERCHANT_CATEGORIES } from '@/domain/types';
import { formatMoney, formatMoneyExact } from '@/domain/money';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { CAPTAIN_COMMISSION_APPROVED_FILS } from '@/domain/commission';
import { Badge, Button, OpenDecision, PageHeader, SettingsRow, SettingsSection, Toggle } from '@/shared/components/ui';
import { CATEGORY_LABEL, UNCATEGORIZED_LABEL } from '@/features/merchants/categories';
import { useSignOut } from '@/features/auth/hooks/useSignOut';
import { BroadcastConfirmDialog } from './BroadcastConfirmDialog';

const linkButton = 'inline-flex h-9 items-center rounded-xl border border-cream-deep bg-white px-3 text-sm font-bold text-ink hover:bg-cream';

/**
 * Admin settings. Only controls backed by real prototype state are interactive;
 * everything else is read-only or links to the page that owns it (no dead Save buttons).
 */
export function AdminSettingsPage() {
  const broadcast = useAppStore((s) => s.settings.publicBroadcast);
  const demo = useAppStore((s) => s.demo);
  const contacts = useAppStore((s) => s.supportContacts);
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);
  const routes = useAppStore((s) => s.routes);
  const signOut = useSignOut();
  const [pendingBroadcast, setPendingBroadcast] = useState<boolean | null>(null);

  const categoryCounts = useMemo(() => {
    const counts = new Map<string, number>();
    for (const m of merchants) counts.set(m.category ?? 'none', (counts.get(m.category ?? 'none') ?? 0) + 1);
    return counts;
  }, [merchants]);
  const visibleContacts = contacts.filter((c) => c.enabled).length;

  return (
    <div className="mx-auto max-w-4xl">
      <PageHeader title="الإعدادات" description="إعدادات المنصة وحساب الإدارة." />
      <div className="space-y-6">
        <SettingsSection title="إعدادات التوزيع" icon={<RadioTower className="h-5 w-5" />}>
          <SettingsRow label="البث العام للطلبات" description="المفتاح نفسه الموجود في لوحة التحكم.">
            <div className="flex items-center gap-3 sm:justify-end">
              <Badge tone={broadcast ? 'success' : 'warning'} dot>
                {broadcast ? 'مفعّل' : 'متوقف'}
              </Badge>
              <Toggle checked={broadcast} tone="primary" onChange={setPendingBroadcast} aria-label="البث العام للطلبات" />
            </div>
          </SettingsRow>
          <SettingsRow label="سياسة إرسال العروض" readOnly>
            {demo.offerPolicy === 'group' ? `أقرب ${demo.groupSize} كباتن معاً` : 'كابتن واحد في كل مرة'}
          </SettingsRow>
          <SettingsRow label="جولات العرض العام" readOnly>
            {MAX_DISPATCH_ROUNDS} جولات × {DISPATCH_ROUND_SEC} ثانية
          </SettingsRow>
          <SettingsRow label="مهلة العرض الخاص" readOnly>
            {demo.offerTimeoutSec} ثانية
          </SettingsRow>
          <div className="px-5 py-3">
            <OpenDecision id="O-005 · O-006">قيم افتراضية للعرض وغير معتمدة. يغيّرها مقدّم العرض من «أدوات العرض» فقط.</OpenDecision>
          </div>
        </SettingsSection>

        <SettingsSection
          title="المحفظة والعمولات"
          icon={<Wallet className="h-5 w-5" />}
          actions={
            <Link to="/admin/wallets" className={linkButton}>
              محافظ الكباتن
            </Link>
          }
        >
          <SettingsRow label="عمولة شهم على الكابتن" description="تعديلها غير متاح: يحتاج خادماً يحفظ القيمة ويطبّقها على الطلبات الجديدة فقط." readOnly>
            <span className="flex flex-wrap items-center gap-2 sm:justify-end">
              <span dir="ltr">{formatMoneyExact(CAPTAIN_COMMISSION_APPROVED_FILS)}</span> / طلب مكتمل
              <Badge tone="warning">مخطط — غير مفعّل</Badge>
            </span>
          </SettingsRow>
          <SettingsRow label="الحد الأدنى لرصيد المحفظة" readOnly>
            {formatMoney(demo.walletThreshold)}
          </SettingsRow>
          <div className="px-5 py-3">
            <OpenDecision id="O-020">الحد الأدنى قيمة تجريبية يغيّرها مقدّم العرض. لا تُخصم أي عمولة في هذا النموذج.</OpenDecision>
          </div>
        </SettingsSection>

        <SettingsSection
          title="الخرائط والمناطق"
          icon={<MapIcon className="h-5 w-5" />}
          actions={
            <Link to="/admin/areas" className={linkButton}>
              إدارة المناطق
            </Link>
          }
        >
          <SettingsRow label="مناطق التوصيل النشطة" readOnly>
            {areas.filter((a) => a.status === 'active').length} من {areas.length}
          </SettingsRow>
          <SettingsRow label="مسارات التوصيل" readOnly>
            {routes.length}
          </SettingsRow>
        </SettingsSection>

        <SettingsSection
          title="الدعم والتواصل"
          icon={<Headphones className="h-5 w-5" />}
          actions={
            <Link to="/admin/support" className={linkButton}>
              إدارة القنوات
            </Link>
          }
        >
          <SettingsRow label="القنوات الظاهرة للتجار والكباتن">
            {contacts.length === 0 ? <span className="text-ink-muted">لم تُضف قنوات رسمية بعد</span> : `${visibleContacts} من ${contacts.length}`}
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="فئات النشاط التجاري" icon={<Store className="h-5 w-5" />} description="تُختار عند إضافة التاجر أو تعديله.">
          <SettingsRow label="الفئات المتاحة" readOnly>
            <ul className="flex flex-wrap gap-1.5 sm:justify-end">
              {MERCHANT_CATEGORIES.map((c) => (
                <li key={c}>
                  <Badge tone="sand">
                    {CATEGORY_LABEL[c]} · {categoryCounts.get(c) ?? 0}
                  </Badge>
                </li>
              ))}
            </ul>
          </SettingsRow>
          {(categoryCounts.get('none') ?? 0) > 0 && (
            <SettingsRow label={UNCATEGORIZED_LABEL} description="تجار بلا فئة بعد — حدّد فئتهم من صفحة التجار.">
              <Link to="/admin/merchants" className="font-bold text-primary hover:underline">
                {categoryCounts.get('none')} تاجر
              </Link>
            </SettingsRow>
          )}
          <div className="px-5 py-3">
            <OpenDecision id="OPEN-FE-07">قائمة فئات مقترحة بانتظار اعتماد مالك المنتج. الفئة للتصنيف فقط ولا تؤثر على الأسعار أو التوزيع.</OpenDecision>
          </div>
        </SettingsSection>

        <SettingsSection title="الحساب والأمان" icon={<UserCog className="h-5 w-5" />}>
          <SettingsRow label="اسم المستخدم" readOnly>
            <span dir="ltr">{DEMO_ADMIN.username}</span>
          </SettingsRow>
          <SettingsRow label="الدور" readOnly>
            مدير النظام
          </SettingsRow>
          <SettingsRow label="كلمة المرور" description="تغيير كلمة المرور غير متاح في النموذج الأولي." readOnly />
          <SettingsRow label="تسجيل الخروج" description="من هذه النافذة فقط.">
            <Button variant="outline" icon={<LogOut className="h-4 w-4" />} onClick={signOut}>
              خروج
            </Button>
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="الإعدادات العامة" icon={<Languages className="h-5 w-5" />}>
          <SettingsRow label="لغة الواجهة" readOnly>
            العربية (من اليمين إلى اليسار)
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="حول النظام" icon={<Info className="h-5 w-5" />}>
          <SettingsRow label="الإصدار" readOnly>
            <span dir="ltr">{version}</span>
          </SettingsRow>
          <SettingsRow label="حفظ البيانات" readOnly>
            نموذج أولي — البيانات محفوظة في هذا المتصفح فقط
          </SettingsRow>
        </SettingsSection>
      </div>

      <BroadcastConfirmDialog next={pendingBroadcast} onClose={() => setPendingBroadcast(null)} />
    </div>
  );
}
