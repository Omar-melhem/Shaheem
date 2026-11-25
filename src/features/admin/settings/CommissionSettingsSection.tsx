import { useEffect, useId, useState } from 'react';
import { Wallet } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { COMMISSION_RATE_ERROR, formatPercentBp, formatPercentInput, parsePercentToBp } from '@/domain/commission';
import { formatMoney } from '@/domain/money';
import { ConfirmDialog, Button, Input, OpenDecision, SettingsRow, SettingsSection } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';
import { CommissionPreview } from '../CommissionPreview';

const AUDIT_PREVIEW = 5;

/**
 * «إعدادات العمولة»: the one global rate (`settings.commissionBp`). Saving goes through a confirmation
 * showing the old and new rates, then `setCommissionRate`, which audits the change. Orders keep the
 * rate locked when their Captain accepted, so history is never recalculated.
 */
export function CommissionSettingsSection() {
  const bp = useAppStore((s) => s.settings.commissionBp);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const audit = useAppStore((s) => s.adminAudit);
  const setCommissionRate = useAppStore((s) => s.setCommissionRate);
  const inputId = useId();
  const [draft, setDraft] = useState(() => formatPercentInput(bp));
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState<number | null>(null);

  useEffect(() => setDraft(formatPercentInput(bp)), [bp]);

  const changes = audit.filter((a) => a.kind === 'commission_rate').slice(0, AUDIT_PREVIEW);
  const review = () => {
    const next = parsePercentToBp(draft);
    if (next === null) return setError(COMMISSION_RATE_ERROR);
    if (next === bp) return setError('النسبة الجديدة مطابقة للنسبة الحالية');
    setError(null);
    setPending(next);
  };

  return (
    <SettingsSection title="إعدادات العمولة" icon={<Wallet className="h-5 w-5" />}>
      <SettingsRow label="نسبة عمولة شهم من رسوم التوصيل" description="تُطبّق النسبة الجديدة على الطلبات الجديدة فقط: تُثبَّت على الطلب عند قبول الكابتن، وتُخصم مرة واحدة عند التسليم.">
        <div className="space-y-1 sm:text-end">
          <div className="flex items-center gap-2 sm:justify-end">
            <label htmlFor={inputId} className="sr-only">نسبة العمولة (%)</label>
            <div className="relative w-28">
              <Input id={inputId} dir="ltr" inputMode="decimal" value={draft} onChange={(e) => { setDraft(e.target.value); setError(null); }} onKeyDown={(e) => e.key === 'Enter' && review()} aria-invalid={!!error} aria-describedby={error ? `${inputId}-err` : undefined} className="pl-8 rtl:text-right" />
              <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-sm font-bold text-ink-muted" aria-hidden>%</span>
            </div>
            <Button variant="outline" onClick={review}>حفظ</Button>
          </div>
          {error && <p id={`${inputId}-err`} role="alert" className="text-[13px] font-medium text-red-700">{error}</p>}
          <p className="text-xs text-ink-muted">الحالية: <b dir="ltr" className="text-ink">{formatPercentBp(bp)}</b></p>
        </div>
      </SettingsRow>
      <div className="border-b border-cream-dark px-5 py-4">
        <p className="mb-2 text-sm font-bold">معاينة الحساب</p>
        <CommissionPreview bp={bp} />
      </div>
      {changes.length > 0 && (
        <div className="border-b border-cream-dark px-5 py-4">
          <p className="mb-2 text-sm font-bold">آخر التغييرات</p>
          <ul className="space-y-1 text-xs text-ink-soft">
            {changes.map((c) => c.kind === 'commission_rate' && (
              <li key={c.id} className="flex flex-wrap gap-x-2">
                <span className="whitespace-nowrap">{formatDateTime(c.at)}</span>
                <span dir="ltr">{formatPercentBp(c.previousBp)} → {formatPercentBp(c.nextBp)}</span>
                <span className="text-ink-muted">{c.actor.name}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
      <SettingsRow label="الحد الأدنى لرصيد المحفظة" readOnly>
        {formatMoney(threshold)}
      </SettingsRow>
      <div className="px-5 py-3">
        <OpenDecision id="بانتظار الاعتماد">النطاق المسموح الحالي 0–100%، والتقريب لأقرب فلس (النصف للأعلى) مقترح. الحد الأدنى للرصيد (O-020) قيمة تجريبية. الحفظ هنا في المتصفح؛ في الإنتاج يحفظه الخادم مع صلاحيات المدير.</OpenDecision>
      </div>

      <ConfirmDialog
        open={pending !== null}
        onClose={() => setPending(null)}
        onConfirm={() => pending !== null && reportResult(setCommissionRate(pending), `أصبحت نسبة العمولة ${formatPercentBp(pending)}`)}
        title="تغيير نسبة العمولة؟"
        confirmLabel="تأكيد التغيير"
      >
        {pending !== null && (
          <div className="mt-3 space-y-2 rounded-xl bg-cream p-4 text-sm">
            <p>النسبة الحالية: <b dir="ltr">{formatPercentBp(bp)}</b></p>
            <p>النسبة الجديدة: <b dir="ltr" className="text-primary">{formatPercentBp(pending)}</b></p>
            <p className="text-xs text-ink-muted">تسري من لحظة التأكيد على الطلبات التي يقبلها الكباتن بعدها. الطلبات المقبولة سابقاً تبقى بنسبتها، ولا يتغير أي خصم سابق.</p>
          </div>
        )}
      </ConfirmDialog>
    </SettingsSection>
  );
}
