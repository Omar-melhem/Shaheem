import type { PricingCopyAction, PricingCopyPreview } from '@/application/pricingCopy';
import { formatMoney } from '@/domain/money';
import { Badge, DataTable } from '@/shared/components/ui';

const ACTION: Record<PricingCopyAction, { label: string; tone: 'success' | 'warning' | 'neutral' }> = {
  add: { label: 'إضافة', tone: 'success' },
  update: { label: 'استبدال', tone: 'warning' },
  unchanged: { label: 'بدون تغيير', tone: 'neutral' },
  kept: { label: 'يبقى السعر الحالي', tone: 'neutral' },
  skipped: { label: 'تخطّي', tone: 'neutral' },
};
const HEADERS = ['منطقة الوصول', 'سعر المصدر', 'السعر الحالي', 'النتيجة'];

/** Exactly what a copy will do, row by row, before anything is written. */
export function PricingCopyPreviewTable({ preview }: { preview: PricingCopyPreview }) {
  const { counts } = preview;
  return (
    <div className="space-y-2">
      <p className="text-sm font-bold" aria-live="polite">
        إضافة {counts.add} · استبدال {counts.update} · يبقى {counts.kept + counts.unchanged} · تخطّي {counts.skipped}
      </p>
      <div className="max-h-64 overflow-y-auto rounded-xl border border-cream-deep">
        <DataTable headers={HEADERS} minWidth={560}>
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
        </DataTable>
      </div>
    </div>
  );
}
