import { useState } from 'react';
import { useAppStore } from '@/app/state';
import type { Merchant, MerchantAreaPrice, ServiceArea } from '@/domain/types';
import { filsToJod, formatMoney, parseJodInput } from '@/domain/money';
import { Button, Dialog, Field, Input } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

export type Editing = { area: ServiceArea; price?: MerchantAreaPrice };

/** Add / change one Merchant's fee for one zone, with a confirmation step. New orders only. */
export function FeeDialog({ merchant, editing, onClose }: { merchant: Merchant; editing: Editing | null; onClose: () => void }) {
  const setPrice = useAppStore((s) => s.setMerchantAreaPrice);
  const [value, setValue] = useState('');
  const [step, setStep] = useState<'form' | 'confirm'>('form');
  const [error, setError] = useState<string | null>(null);
  const [lastKey, setLastKey] = useState<string | null>(null);

  const key = editing ? `${editing.area.id}-${editing.price?.price ?? 'new'}` : null;
  if (key !== lastKey) {
    setLastKey(key);
    setValue(editing?.price ? String(filsToJod(editing.price.price)) : '');
    setStep('form');
    setError(null);
  }
  if (!editing) return null;
  const fils = parseJodInput(value);

  const review = () => {
    if (fils === null || fils <= 0) return setError('أدخل رسوماً صالحة أكبر من صفر، مثل 1.50');
    if (editing.price && fils === editing.price.price) return setError('الرسوم لم تتغير');
    setError(null);
    setStep('confirm');
  };
  const save = () => {
    if (fils === null) return;
    if (reportResult(setPrice(merchant.id, editing.area.id, fils), `تم حفظ رسوم ${editing.area.name}: ${formatMoney(fils)}`)) onClose();
  };

  return (
    <Dialog
      open
      onClose={onClose}
      size="sm"
      title={`${editing.price ? 'تعديل' : 'إضافة'} ${editing.area.name} — ${merchant.businessName}`}
      footer={
        step === 'form' ? (
          <>
            <Button variant="outline" onClick={onClose}>إلغاء</Button>
            <Button onClick={review}>متابعة</Button>
          </>
        ) : (
          <>
            <Button variant="outline" onClick={() => setStep('form')}>رجوع</Button>
            <Button variant="secondary" onClick={save}>تأكيد وحفظ</Button>
          </>
        )
      }
    >
      {step === 'form' ? (
        <Field label="رسوم التوصيل الكاملة (د.أ)" required error={error} hint="رسوم ثابتة لأي عنوان داخل هذه المنطقة لهذا التاجر.">
          <Input value={value} onChange={(e) => setValue(e.target.value)} inputMode="decimal" dir="ltr" placeholder="1.50" autoFocus onKeyDown={(e) => e.key === 'Enter' && review()} aria-invalid={!!error} />
        </Field>
      ) : (
        <div className="space-y-3 text-sm">
          <div className="rounded-xl bg-cream p-4">
            <p>المنطقة: <b>{editing.area.name}</b></p>
            {editing.price && <p>الرسوم الحالية: <b>{formatMoney(editing.price.price)}</b></p>}
            <p>الرسوم الجديدة: <b className="text-secondary">{formatMoney(fils!)}</b></p>
          </div>
          <p className="text-xs text-ink-muted">تنطبق على الطلبات الجديدة فقط. الطلبات السابقة والنشطة تحتفظ برسومها المحفوظة.</p>
        </div>
      )}
    </Dialog>
  );
}
