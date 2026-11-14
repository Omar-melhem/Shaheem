import { useMemo, useState } from 'react';
import { useAppStore } from '@/app/state';
import { previewPricingCopy, type PricingCopyMode } from '@/application/pricingCopy';
import type { Merchant } from '@/domain/types';
import { Button, Dialog, EmptyState, SearchField, Toggle } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { cn } from '@/shared/lib/cn';
import { PricingCopyPreviewTable } from './PricingCopyPreviewTable';

const MODES: Array<[PricingCopyMode, string, string]> = [
  ['fill_missing', 'إكمال الناقص فقط', 'تُضاف الأسعار غير الموجودة، وتبقى أسعار هذا المتجر الحالية كما هي.'],
  ['overwrite', 'استبدال الأسعار الحالية', 'تُستبدل الأسعار المختلفة بأسعار المتجر المصدر. يتطلب تأكيداً منفصلاً.'],
];

/**
 * Copy another Merchant's zone prices: choose source → preview → confirm (CR v1.3 §4).
 * Only price rows change; orders keep their locked fee snapshots.
 */
export function CopyMerchantPricingDialog({ target, open, onClose }: { target: Merchant; open: boolean; onClose: () => void }) {
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const copyPricing = useAppStore((s) => s.copyMerchantPricing);
  const [q, setQ] = useState('');
  const [sourceId, setSourceId] = useState('');
  const [mode, setMode] = useState<PricingCopyMode>('fill_missing');
  const [step, setStep] = useState<'preview' | 'confirm'>('preview');
  const [overwriteApproved, setOverwriteApproved] = useState(false);

  const source = merchants.find((m) => m.id === sourceId);
  const needle = q.trim();
  const candidates = merchants.filter((m) => m.id !== target.id && (!needle || m.businessName.includes(needle) || m.address.includes(needle)));
  const preview = useMemo(() => (sourceId ? previewPricingCopy({ areas, prices }, sourceId, target.id, mode) : null), [areas, prices, sourceId, target.id, mode]);

  const close = () => {
    setQ('');
    setSourceId('');
    setMode('fill_missing');
    setStep('preview');
    setOverwriteApproved(false);
    onClose();
  };
  const apply = () => {
    if (!source) return;
    const result = copyPricing(source.id, target.id, mode);
    const changed = result.ok ? result.value.changed : 0;
    if (reportResult(result, `تم نسخ ${changed} سعر من «${source.businessName}» إلى «${target.businessName}»`)) close();
  };

  return (
    <Dialog
      open={open}
      onClose={close}
      size="xl"
      title="نسخ تسعيرة من متجر آخر"
      description={`المتجر الهدف: ${target.businessName}`}
      footer={
        step === 'preview' ? (
          <>
            <Button variant="outline" onClick={close}>إلغاء</Button>
            <Button disabled={!preview || preview.changes === 0} onClick={() => setStep('confirm')}>متابعة للتأكيد</Button>
          </>
        ) : (
          <>
            <Button variant="outline" onClick={() => setStep('preview')}>رجوع</Button>
            <Button variant={mode === 'overwrite' ? 'danger' : 'secondary'} disabled={mode === 'overwrite' && !overwriteApproved} onClick={apply}>
              تأكيد النسخ ({preview?.changes ?? 0})
            </Button>
          </>
        )
      }
    >
      {step === 'preview' ? (
        <div className="space-y-4">
          <div>
            <SearchField label="ابحث عن المتجر المصدر" placeholder="ابحث باسم المتجر أو موقعه" value={q} onChange={(e) => setQ(e.target.value)} />
            <ul className="mt-2 max-h-44 divide-y divide-cream-dark overflow-y-auto rounded-xl border border-cream-deep" role="radiogroup" aria-label="المتجر المصدر">
              {candidates.map((m) => (
                <li key={m.id}>
                  <button
                    type="button"
                    role="radio"
                    aria-checked={sourceId === m.id}
                    onClick={() => setSourceId(m.id)}
                    className={cn('w-full px-4 py-2.5 text-start hover:bg-cream', sourceId === m.id && 'bg-primary-50')}
                  >
                    <span className="block text-sm font-bold">{m.businessName}</span>
                    <span className="block text-xs text-ink-muted">{m.address}</span>
                  </button>
                </li>
              ))}
              {candidates.length === 0 && <li className="p-4 text-center text-sm text-ink-muted">لا توجد متاجر مطابقة</li>}
            </ul>
          </div>

          {source && preview && (
            <>
              <div className="grid gap-2 md:grid-cols-2" role="radiogroup" aria-label="طريقة النسخ">
                {MODES.map(([value, label, description]) => (
                  <button
                    key={value}
                    type="button"
                    role="radio"
                    aria-checked={mode === value}
                    onClick={() => { setMode(value); setOverwriteApproved(false); }}
                    className={cn('rounded-xl border p-3 text-start', mode === value ? 'border-primary bg-primary-50' : 'border-cream-deep hover:bg-cream')}
                  >
                    <span className="block text-sm font-bold">{label}</span>
                    <span className="block text-xs text-ink-muted">{description}</span>
                  </button>
                ))}
              </div>
              {preview.rows.length === 0 ? (
                <EmptyState title="لا توجد أسعار لدى هذا المتجر" />
              ) : (
                <PricingCopyPreviewTable preview={preview} />
              )}
              {preview.rows.length > 0 && preview.changes === 0 && <p className="text-sm font-medium text-ink-soft" role="status">لا يوجد ما يتغير بهذه الطريقة.</p>}
            </>
          )}
        </div>
      ) : (
        source && preview && (
          <div className="space-y-3 text-sm">
            <div className="space-y-1 rounded-xl bg-cream p-4">
              <p>من: <b>{source.businessName}</b></p>
              <p>إلى: <b>{target.businessName}</b></p>
              <p>إضافة <b>{preview.counts.add}</b> سعر · استبدال <b>{preview.counts.update}</b> سعر · بدون تغيير <b>{preview.counts.unchanged + preview.counts.kept + preview.counts.skipped}</b></p>
            </div>
            <p className="text-xs text-ink-muted">تنطبق الأسعار على الطلبات الجديدة فقط؛ الطلبات السابقة تحتفظ برسومها المحفوظة. لا تُنسخ أي بيانات أخرى للمتجر.</p>
            {mode === 'overwrite' && (
              <div className="rounded-xl border border-red-200 bg-red-50 p-3">
                <Toggle checked={overwriteApproved} onChange={setOverwriteApproved} label={`أؤكد استبدال ${preview.counts.update} سعر حالي لهذا المتجر`} />
              </div>
            )}
          </div>
        )
      )}
    </Dialog>
  );
}
