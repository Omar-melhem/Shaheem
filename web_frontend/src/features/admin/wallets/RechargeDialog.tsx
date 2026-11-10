import { useEffect, useState } from 'react';
import { useAppStore } from '@/application/store';
import type { CaptainView } from '@/application/hooks';
import { formatMoney, parseJodInput } from '@/domain/money';
import { Button, Dialog, Field, Input } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/**
 * The single wallet recharge flow (Admin only, simulated credit), opened from the Captain Wallets
 * page and from the recharge icon on each Captain row — one use case, no second implementation.
 */
export function RechargeDialog({ view, onClose }: { view: CaptainView | null; onClose: () => void }) {
  const rechargeWallet = useAppStore((s) => s.rechargeWallet);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [step, setStep] = useState<'form' | 'review'>('form');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setAmount('');
    setReason('');
    setStep('form');
    setError(null);
  }, [view?.captain.id]);

  if (!view) return null;
  const fils = parseJodInput(amount);

  const review = () => {
    if (fils === null || fils <= 0) return setError('أدخل مبلغاً موجباً، مثل 5 أو 2.5');
    setError(null);
    setStep('review');
  };
  const confirm = () => {
    if (submitting || fils === null) return;
    setSubmitting(true);
    const ok = reportResult(rechargeWallet(view.captain.id, fils, reason), `تم شحن محفظة ${view.captain.fullName} بمبلغ ${formatMoney(fils)} (محاكاة)`);
    setSubmitting(false);
    if (ok) onClose();
  };

  return (
    <Dialog
      open
      onClose={onClose}
      size="sm"
      title={`شحن محفظة ${view.captain.fullName}`}
      description={`الرصيد الحالي ${formatMoney(view.balance)}`}
      footer={
        step === 'form' ? (
          <>
            <Button variant="outline" onClick={onClose}>إلغاء</Button>
            <Button onClick={review}>مراجعة</Button>
          </>
        ) : (
          <>
            <Button variant="outline" onClick={() => setStep('form')}>رجوع</Button>
            <Button variant="secondary" onClick={confirm} loading={submitting}>تأكيد الشحن</Button>
          </>
        )
      }
    >
      {step === 'form' ? (
        <div className="space-y-4">
          <Field label="المبلغ (د.أ)" required error={error}>
            <Input value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" dir="ltr" placeholder="5.000" aria-invalid={!!error} onKeyDown={(e) => e.key === 'Enter' && review()} />
          </Field>
          <Field label="المرجع / السبب" optional>
            <Input value={reason} onChange={(e) => setReason(e.target.value)} placeholder="مثال: إيصال نقدي رقم 1024" />
          </Field>
        </div>
      ) : (
        <div className="space-y-3 text-sm">
          <div className="rounded-xl bg-cream p-4">
            <p>الكابتن: <b>{view.captain.fullName}</b></p>
            <p>مبلغ الشحن: <b className="text-secondary">{formatMoney(fils!)}</b></p>
            <p>الرصيد بعد الشحن: <b>{formatMoney(view.balance + fils!)}</b></p>
            {view.balance + fils! >= threshold && view.balance < threshold && <p className="mt-2 text-secondary">سيصبح رصيد الكابتن كافياً للأهلية التجريبية.</p>}
          </div>
          <p className="text-xs text-ink-muted">بالتأكيد أنت تُقرّ باستلام المبلغ من الكابتن خارج النظام. سيُسجَّل قيد شحن باسم المدير الحالي. هذه عملية محاكاة وليست تحويلاً إلكترونياً.</p>
        </div>
      )}
    </Dialog>
  );
}
