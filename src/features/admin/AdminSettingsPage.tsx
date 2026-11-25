import { useState } from 'react';
import { LogOut, RadioTower, UserCog } from 'lucide-react';
import { useAppStore, DEMO_ADMIN } from '@/app/state';
import { DISPATCH_ROUNDS, DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS, describeRound } from '@/domain/dispatch';
import { ACTIVE_REPORT_INTERVAL_SEC, IDLE_REPORT_INTERVAL_SEC, IDLE_STALE_AFTER_SEC } from '@/domain/location';
import { CommissionSettingsSection } from './settings/CommissionSettingsSection';
import { PasswordResetSection } from './settings/PasswordResetSection';
import { Badge, OpenDecision, PageHeader, SettingsRow, SettingsSection, Toggle } from '@/shared/components/ui';
import { SignOutSection } from '@/features/auth/SignOutSection';
import { BroadcastConfirmDialog } from './BroadcastConfirmDialog';

/**
 * Admin settings: only settings that exist and affect the platform. The broadcast switch is the
 * same single setting as the header pill (through BroadcastConfirmDialog); dispatch values are
 * read-only; the commission rate is editable with confirmation and audit (owner, 2026-11-25);
 * Merchant/Captain password resets live here. Areas, merchants and wallets have their own pages.
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
            {DISPATCH_ROUNDS.map((policy, i) => `${i + 1}) ${describeRound(policy)}`).join(' ← ')}
          </SettingsRow>
          <SettingsRow label="جولات العرض العام" readOnly>
            {MAX_DISPATCH_ROUNDS} جولات × {DISPATCH_ROUND_SEC} ثانية
          </SettingsRow>
          <SettingsRow label="مهلة العرض الخاص" readOnly>
            {demo.offerTimeoutSec} ثانية
          </SettingsRow>
          <SettingsRow label="تحديث موقع الكابتن" description={`يُعتبر الموقع متأخراً بعد ${IDLE_STALE_AFTER_SEC} ثانية دون تحديث.`} readOnly>
            متاح بلا طلب: كل {IDLE_REPORT_INTERVAL_SEC} ث · أثناء التوصيل: كل {ACTIVE_REPORT_INTERVAL_SEC} ث
          </SettingsRow>
          <div className="px-5 py-3">
            <OpenDecision id="بانتظار التأكيد">تفسير الجولات (3 كباتن ضمن 5 كم أولاً) ومدة الجولتين الثانية والثالثة مقترحة، ومهلة العرض الخاص (O-006) تجريبية. إرسال الموقع يتم من تطبيق الكابتن والخادم، وهنا محاكاة.</OpenDecision>
          </div>
        </SettingsSection>

        <CommissionSettingsSection />

        <SettingsSection title="الحساب والأمان" icon={<UserCog className="h-5 w-5" />}>
          <SettingsRow label="اسم المستخدم" readOnly>
            <span dir="ltr">{DEMO_ADMIN.username}</span>
          </SettingsRow>
          <SettingsRow label="الدور" readOnly>
            مدير النظام
          </SettingsRow>
        </SettingsSection>

        <PasswordResetSection />

        <SignOutSection icon={<LogOut className="h-5 w-5" />} />
      </div>

      <BroadcastConfirmDialog next={pendingBroadcast} onClose={() => setPendingBroadcast(null)} />
    </div>
  );
}
