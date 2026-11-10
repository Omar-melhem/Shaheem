import { History } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Card, CardHeader } from '@/shared/components/ui';
import { formatDateTime } from '@/shared/lib/format';

/** Audit trail of price copies into this Merchant. Hidden until one exists. */
export function PricingCopyHistory({ merchantId }: { merchantId: string }) {
  const audit = useAppStore((s) => s.pricingAudit);
  const merchants = useAppStore((s) => s.merchants);
  const entries = audit.filter((a) => a.targetMerchantId === merchantId);
  if (entries.length === 0) return null;
  const name = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  return (
    <Card className="mt-4">
      <CardHeader title="سجل نسخ التسعيرة" icon={<History className="h-5 w-5" />} />
      <ul className="divide-y divide-cream-dark">
        {entries.map((a) => (
          <li key={a.id} className="px-5 py-3 text-sm">
            <p>
              من <b>{name(a.sourceMerchantId)}</b> · {a.changes.length} سعر · {a.mode === 'overwrite' ? 'استبدال' : 'إكمال الناقص'}
            </p>
            <p className="text-xs text-ink-muted">{a.actor} · {formatDateTime(a.at)}</p>
          </li>
        ))}
      </ul>
    </Card>
  );
}
