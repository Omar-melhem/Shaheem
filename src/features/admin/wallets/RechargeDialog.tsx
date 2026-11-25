import { useEffect, useState } from 'react';
import { useAppStore } from '@/app/state';
import type { CaptainView } from '@/shared/hooks/application';
import { formatMoney, parseJodInput } from '@/domain/money';
import { MAX_TOPUP_FILS, TOPUP_AMOUNT_ERROR, topUpAmountError } from '@/domain/wallet';
import { Button, Dialog, Field, Input } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

const newOperationId = () => crypto.randomUUID();

/**
 * The single wallet top-up flow (Admin only, demo ledger), opened from the Captain Wallets page and
 * from the recharge icon on each Captain row. Amount → review with the receipt confirmation → one
 * `rechargeWallet`. The operation id is created when the dialog opens, so a retried or doubled
 * confirmation can never credit twice. No free-text reason field (owner, 2026-11-25).
 */
export function RechargeDialog({ view, onClose }: { view: CaptainView | null; onClose: () => void }) {
  const rechargeWallet = useAppStore((s) => s.rechargeWallet);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [amount, setAmount] = useState('');
  const [step, setStep] = useState<'form' | 'review'>('form');
  const [error, setError] = useState<string | null>(null);
  const [receiptConfirmed, setReceiptConfirmed] = useState(false);
  const [operationId, setOperationId] = useState(newOperationId);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setAmount('');
    setStep('form');
    setError(null);
    setReceiptConfirmed(false);
    setOperationId(newOperationId());
  }, [view?.captain.id]);

  if (!view) return null;
  const fils = parseJodInput(amount);

  const review = () => {
    const amountError = fils === null ? TOPUP_AMOUNT_ERROR : topUpAmountError(fils);
    if (amountError) return setError(amountError);
    setError(null);
    setStep('review');
  };
  const confirm = () => {
    if (submitting || fils === null || !receiptConfirmed) return;
    setSubmitting(true);
    const ok = reportResult(rechargeWallet(view.captain.id, fils, operationId), `تم شحن محفظة ${view.captain.fullName} بمبلغ ${formatMoney(fils)}`);
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
            <Button variant="secondary" onClick={confirm} loading={submitting} disabled={!receiptConfirmed}>تأكيد الشحن</Button>
          </>
        )
      }
    >
      {step === 'form' ? (
        <Field label="المبلغ (د.أ)" required error={error} hint={`الحد الأقصى ${formatMoney(MAX_TOPUP_FILS)} في العملية الواحدة`}>
          <Input value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" dir="ltr" placeholder="5.000" aria-invalid={!!error} onKeyDown={(e) => e.key === 'Enter' && review()} />
        </Field>
      ) : (
        <div className="space-y-3 text-sm">
          <div className="rounded-xl bg-cream p-4">
            <p>الكابتن: <b>{view.captain.fullName}</b></p>
            <p>مبلغ الشحن: <b className="text-secondary">{formatMoney(fils!)}</b></p>
            <p>الرصيد بعد الشحن: <b>{formatMoney(view.balance + fils!)}</b></p>
            {view.balance + fils! >= threshold && view.balance < threshold && <p className="mt-2 text-secondary">سيصبح رصيد الكابتن كافياً للأهلية التجريبية.</p>}
          </div>
          <label className="flex cursor-pointer items-start gap-3 rounded-xl border border-cream-deep p-3">
            <input type="checkbox" className="mt-0.5 h-4 w-4 shrink-0 accent-[#8C2335]" checked={receiptConfirmed} onChange={(e) => setReceiptConfirmed(e.target.checked)} />
            <span>تحققتُ من استلام المبلغ من الكابتن خارج النظام.</span>
          </label>
          <p className="text-xs text-ink-muted">يُسجَّل قيد شحن واحد باسم المدير الحالي ووقت العملية. الشحن رصيد للكابتن وليس من أرباح شهم، وهذه عملية محاكاة وليست تحويلاً إلكترونياً.</p>
        </div>
      )}
    </Dialog>
  );
}
