import { BarChart3 } from 'lucide-react';
import type { ActivityDay } from '@/application/dashboard';
import { Card, CardHeader, EmptyState } from '@/shared/components/ui';

const DAY_LABEL = new Intl.DateTimeFormat('ar-JO-u-nu-latn', { weekday: 'short', timeZone: 'Asia/Amman' });
const DATE_LABEL = new Intl.DateTimeFormat('ar-JO-u-nu-latn', { day: 'numeric', month: 'numeric', timeZone: 'Asia/Amman' });
const BAR_AREA_PX = 120;

/** Orders created vs delivered per Amman day, drawn from real order timestamps (no chart library). */
export function OrderActivityChart({ days }: { days: ActivityDay[] }) {
  const max = Math.max(1, ...days.map((d) => Math.max(d.created, d.delivered)));
  const total = days.reduce((n, d) => n + d.created, 0);
  const summary = days.map((d) => `${DAY_LABEL.format(d.at)}: ${d.created} طلب، ${d.delivered} تسليم`).join('؛ ');

  return (
    <Card className="min-w-0">
      <CardHeader
        title={`نشاط الطلبات — آخر ${days.length} أيام`}
        icon={<BarChart3 className="h-5 w-5" />}
        actions={
          <div className="flex items-center gap-3 text-xs text-ink-soft">
            <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm bg-primary" aria-hidden /> طلبات جديدة</span>
            <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm bg-secondary" aria-hidden /> تم التسليم</span>
          </div>
        }
      />
      {total === 0 ? (
        <EmptyState title="لا توجد طلبات في هذه الفترة" description="سيظهر النشاط هنا عند إنشاء الطلبات." />
      ) : (
        <div className="px-5 pb-5">
          <div role="img" aria-label={`نشاط الطلبات: ${summary}`} className="grid grid-cols-7 items-end gap-2 sm:gap-4" style={{ height: BAR_AREA_PX + 24 }}>
            {days.map((d) => (
              <div key={d.dayKey} className="flex h-full min-w-0 items-end justify-center gap-1" aria-hidden>
                <Bar value={d.created} max={max} className="bg-primary" />
                <Bar value={d.delivered} max={max} className="bg-secondary" />
              </div>
            ))}
          </div>
          <div className="mt-2 grid grid-cols-7 gap-2 border-t border-cream-dark pt-2 text-center sm:gap-4" aria-hidden>
            {days.map((d) => (
              <div key={d.dayKey} className="min-w-0">
                <p className="hidden truncate text-xs font-bold text-ink-soft sm:block">{DAY_LABEL.format(d.at)}</p>
                <p className="text-[11px] text-ink-muted">{DATE_LABEL.format(d.at)}</p>
              </div>
            ))}
          </div>
        </div>
      )}
    </Card>
  );
}

function Bar({ value, max, className }: { value: number; max: number; className: string }) {
  return (
    <div className="flex w-full max-w-[22px] flex-col items-center justify-end">
      <span className="mb-1 text-[11px] font-bold text-ink-soft">{value}</span>
      <div className={`w-full rounded-t-md ${className}`} style={{ height: Math.max(value ? 4 : 0, Math.round((value / max) * BAR_AREA_PX)) }} />
    </div>
  );
}
