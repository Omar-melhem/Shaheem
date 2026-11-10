import { Link } from 'react-router-dom';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';
import type { OperationalAlert } from '@/application/dashboard';
import { useAppStore } from '@/application/store';
import { Card, CardHeader } from '@/shared/components/ui';
import { formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

const EVENTS_SHOWN = 5;

/** Actionable alerts first (what, why, where to fix), then the latest operational events. */
export function OperationalAlerts({ alerts, now }: { alerts: OperationalAlert[]; now: number }) {
  const events = useAppStore((s) => s.alerts);
  return (
    <Card className="min-w-0">
      <CardHeader title="التنبيهات التشغيلية" icon={<AlertTriangle className="h-5 w-5" />} />
      <div className="space-y-3 px-5 pb-5">
        {alerts.length === 0 ? (
          <p className="flex items-center gap-2 rounded-xl bg-secondary-50 px-3 py-2.5 text-sm text-secondary">
            <CheckCircle2 className="h-4 w-4 shrink-0" aria-hidden /> لا توجد مشكلات تحتاج تدخلاً الآن.
          </p>
        ) : (
          <ul className="space-y-2">
            {alerts.map((a) => (
              <li key={a.id} className={cn('rounded-xl border p-3', a.tone === 'danger' ? 'border-red-200 bg-red-50' : 'border-amber-200 bg-amber-50')}>
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <p className={cn('text-sm font-extrabold', a.tone === 'danger' ? 'text-red-800' : 'text-amber-900')}>{a.title}</p>
                  <Link to={a.to} className="text-sm font-bold text-primary hover:underline">{a.actionLabel}</Link>
                </div>
                <p className="mt-1 text-xs text-ink-soft">{a.detail}</p>
              </li>
            ))}
          </ul>
        )}
        {events.length > 0 && (
          <div>
            <p className="mb-1 text-xs font-bold text-ink-muted">آخر الأحداث</p>
            <ul className="divide-y divide-cream-dark">
              {events.slice(0, EVENTS_SHOWN).map((e) => (
                <li key={e.id} className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-0.5 py-2">
                  <p className="min-w-0 text-sm text-ink">{e.message}</p>
                  <p className="text-xs text-ink-muted">{formatRelative(e.at, now)}</p>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </Card>
  );
}
