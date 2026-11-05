import type { PricingCopyAction, PricingCopyPreview } from '@/application/pricingCopy';
import { formatMoney } from '@/domain/money';
import { Badge } from '@/shared/components/ui';

const ACTION: Record<PricingCopyAction, { label: string; tone: 'success' | 'warning' | 'neutral' }> = {
  add: { label: 'إضافة', tone: 'success' },
  update: { label: 'استبدال', tone: 'warning' },
  unchanged: { label: 'بدون تغيير', tone: 'neutral' },
  kept: { label: 'يبقى السعر الحالي', tone: 'neutral' },
  skipped: { label: 'تخطّي', tone: 'neutral' },
};

/** Exactly what a copy will do, row by row, before anything is written. */
export function PricingCopyPreviewTable({ preview }: { preview: PricingCopyPreview }) {
  const { counts } = preview;
  return (
    <div className="space-y-2">
      <p className="text-sm font-bold" aria-live="polite">
        إضافة {counts.add} · استبدال {counts.update} · يبقى {counts.kept + counts.unchanged} · تخطّي {counts.skipped}
      </p>
      <div className="max-h-64 overflow-auto rounded-xl border border-cream-deep">
        <table className="w-full min-w-[560px] text-sm">
          <thead className="sticky top-0 bg-cream text-xs text-ink-muted">
            <tr>
              {['منطقة الوصول', 'سعر المصدر', 'السعر الحالي', 'النتيجة'].map((h) => (
                <th key={h} scope="col" className="px-4 py-2 text-start font-bold">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-cream-dark">
            {preview.rows.map((r) => (
              <tr key={r.areaId}>
                <th scope="row" className="px-4 py-2 text-start font-bold">{r.areaName}</th>
                <td className="px-4 py-2">{formatMoney(r.sourcePrice)}</td>
                <td className="px-4 py-2">{r.targetPrice !== undefined ? formatMoney(r.targetPrice) : '—'}</td>
                <td className="px-4 py-2">
                  <Badge tone={ACTION[r.action].tone}>{ACTION[r.action].label}</Badge>
                  {r.skipReason && <span className="ms-2 text-xs text-ink-muted">{r.skipReason}</span>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
