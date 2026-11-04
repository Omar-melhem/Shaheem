import { AlertTriangle } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Card, CardHeader, EmptyState } from '@/shared/components/ui';
import { formatRelative } from '@/shared/lib/format';

const ALERTS_SHOWN = 12;

/** «التنبيهات التشغيلية» — shown below the latest orders on the dashboard. */
export function OperationalAlerts({ now }: { now: number }) {
  const alerts = useAppStore((s) => s.alerts);
  return (
    <Card>
      <CardHeader title="التنبيهات التشغيلية" icon={<AlertTriangle className="h-5 w-5" />} />
      {alerts.length === 0 ? (
        <EmptyState title="لا توجد تنبيهات" />
      ) : (
        <ul className="max-h-[420px] divide-y divide-cream-dark overflow-y-auto">
          {alerts.slice(0, ALERTS_SHOWN).map((a) => (
            <li key={a.id} className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 px-5 py-3">
              <p className="text-sm text-ink">{a.message}</p>
              <p className="text-xs text-ink-muted">{formatRelative(a.at, now)}</p>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
