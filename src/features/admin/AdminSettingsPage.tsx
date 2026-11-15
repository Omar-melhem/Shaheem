import { useState } from 'react';
import { LogOut, RadioTower, UserCog, Wallet } from 'lucide-react';
import { useAppStore, DEMO_ADMIN } from '@/app/state';
import { formatMoney } from '@/domain/money';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { COMMISSION_BP_PROPOSED, formatPercentBp } from '@/domain/commission';
import { CommissionPreview } from './CommissionPreview';
import { Badge, OpenDecision, PageHeader, SettingsRow, SettingsSection, Toggle } from '@/shared/components/ui';
import { SignOutSection } from '@/features/auth/SignOutSection';
import { BroadcastConfirmDialog } from './BroadcastConfirmDialog';

/**
 * Admin settings: only settings that exist and affect the platform. The broadcast switch is the
 * same single setting as the header pill (through BroadcastConfirmDialog); dispatch values and the
 * commission rate are shown read-only because changing them is not an approved feature yet.
 * Areas, support channels, merchants and wallets are managed on their own pages.
 */
export function AdminSettingsPage() {
  const broadcast = useAppStore((s) => s.settings.publicBroadcast);
  const demo = useAppStore((s) => s.demo);
  const [pendingBroadcast, setPendingBroadcast] = useState<boolean | null>(null);

  return (
    <div className="mx-auto max-w-4xl">
      <PageHeader title="الإعدادات" description="إعدادات التشغيل وحساب الإدارة." />
      <div className="space-y-6">
        <SettingsSection title="إعدادات التشغيل" icon={<RadioTower className="h-5 w-5" />}>
          <SettingsRow label="البث العام للطلبات" description="المفتاح نفسه الموجود في الشريط العلوي.">
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

        <SettingsSection title="العمولة" icon={<Wallet className="h-5 w-5" />}>
          <SettingsRow
            label="نسبة عمولة شهم من رسوم التوصيل"
            description="تُحسب من رسوم توصيل الطلب عند قبوله، وتُخصم مرة واحدة بعد التسليم. حفظها وتعديلها والخصم تحتاج خادماً، فهي معروضة فقط."
            readOnly
          >
            <span className="flex flex-wrap items-center gap-2 sm:justify-end">
              <span dir="ltr" className="font-bold">{formatPercentBp(COMMISSION_BP_PROPOSED)}</span>
              <Badge tone="warning">مقترحة — غير مفعّلة</Badge>
            </span>
          </SettingsRow>
          <div className="border-b border-cream-dark px-5 py-4">
            <p className="mb-2 text-sm font-bold">معاينة الحساب</p>
            <CommissionPreview />
          </div>
          <SettingsRow label="الحد الأدنى لرصيد المحفظة" readOnly>
            {formatMoney(demo.walletThreshold)}
          </SettingsRow>
          <div className="px-5 py-3">
            <OpenDecision id="CR-1.4 §9.4">التقريب المقترح: لأقرب فلس (النصف يُقرَّب للأعلى) — بانتظار الاعتماد. الحد الأدنى للرصيد (O-020) قيمة تجريبية. لا تُخصم أي عمولة في هذا النموذج.</OpenDecision>
          </div>
        </SettingsSection>

        <SettingsSection title="الحساب والأمان" icon={<UserCog className="h-5 w-5" />}>
          <SettingsRow label="اسم المستخدم" readOnly>
            <span dir="ltr">{DEMO_ADMIN.username}</span>
          </SettingsRow>
          <SettingsRow label="الدور" readOnly>
            مدير النظام
          </SettingsRow>
        </SettingsSection>

        <SignOutSection icon={<LogOut className="h-5 w-5" />} />
      </div>

      <BroadcastConfirmDialog next={pendingBroadcast} onClose={() => setPendingBroadcast(null)} />
    </div>
  );
}
