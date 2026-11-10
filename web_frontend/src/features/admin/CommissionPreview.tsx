import { useState } from 'react';
import { COMMISSION_BP_PROPOSED, commissionFils, formatPercentBp } from '@/domain/commission';
import { formatMoneyExact, parseJodInput } from '@/domain/money';
import { Input } from '@/shared/components/ui';

const EXAMPLES_FILS = [1000, 1500, 2000, 750];

/**
 * Worked preview of the percentage commission (CR v1.4 §3.1) using the same domain function a
 * backend would. A calculator only: it changes no setting and charges nothing.
 */
export function CommissionPreview({ bp = COMMISSION_BP_PROPOSED }: { bp?: number }) {
  const [fee, setFee] = useState('1.500');
  const fils = parseJodInput(fee);
  const line = (feeFils: number) => `${formatMoneyExact(feeFils)} × ${formatPercentBp(bp)} = ${formatMoneyExact(commissionFils(feeFils, bp))}`;

  return (
    <div className="space-y-3">
      <label className="flex flex-wrap items-center gap-2 text-sm">
        <span className="font-bold">رسوم التوصيل (د.أ)</span>
        <Input className="w-28 rtl:text-right" dir="ltr" inputMode="decimal" value={fee} onChange={(e) => setFee(e.target.value)} aria-label="رسوم التوصيل للمعاينة" />
      </label>
      <p className="rounded-xl bg-cream px-3 py-2 text-sm" aria-live="polite">
        {fils !== null ? (
          <>
            رسوم التوصيل {formatMoneyExact(fils)} × {formatPercentBp(bp)} = <b className="text-primary">عمولة شهم {formatMoneyExact(commissionFils(fils, bp))}</b>
          </>
        ) : (
          <span className="text-red-700">أدخل رسوماً صالحة، مثل 1.500</span>
        )}
      </p>
      <ul className="grid gap-1 text-xs text-ink-muted sm:grid-cols-2" dir="ltr">
        {EXAMPLES_FILS.map((f) => (
          <li key={f} className="rtl:text-right">{line(f)}</li>
        ))}
      </ul>
    </div>
  );
}
