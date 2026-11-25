import { useMemo, useState } from 'react';
import { Coins } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { REVENUE_PERIOD_LABEL, commissionRevenue, type RevenuePeriod } from '@/application/dashboard';
import { formatMoney } from '@/domain/money';
import { Card, SimTag } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';

const PERIODS: RevenuePeriod[] = ['today', 'month', 'all'];

/**
 * «أرباح شهم»: commission finalised on delivered orders (`commissionRevenue`), by Amman day or month.
 * Read-only — the debits themselves are listed in «محافظ الكباتن» › سجل الحركات.
 */
export function RevenueCard({ now }: { now: number }) {
  const walletTx = useAppStore((s) => s.walletTx);
  const [period, setPeriod] = useState<RevenuePeriod>('today');
  const revenue = useMemo(() => commissionRevenue(walletTx, now, period), [walletTx, now, period]);

  return (
    <section aria-labelledby="revenue-title">
      <Card className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex min-w-0 items-center gap-4">
          <div className="shrink-0 rounded-xl bg-secondary-50 p-2.5 text-secondary"><Coins className="h-6 w-6" aria-hidden /></div>
          <div className="min-w-0">
            <h2 id="revenue-title" className="text-sm font-extrabold text-ink">أرباح شهم</h2>
            <p className="text-3xl font-extrabold leading-tight text-ink" aria-live="polite">{formatMoney(revenue.amount)}</p>
            <p className="text-xs text-ink-muted">
              العمولات المحصلة من الطلبات المسلّمة · {REVENUE_PERIOD_LABEL[period]} · {revenue.orders} طلب
            </p>
          </div>
        </div>
        <div className="flex flex-col items-start gap-2 sm:items-end">
          <div role="group" aria-label="فترة الأرباح" className="inline-flex rounded-xl bg-cream p-1">
            {PERIODS.map((p) => (
              <button
                key={p}
                type="button"
                aria-pressed={period === p}
                onClick={() => setPeriod(p)}
                className={cn(
                  'h-9 rounded-lg px-3 text-xs font-bold focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300',
                  period === p ? 'bg-white text-ink shadow-card' : 'text-ink-soft hover:text-ink',
                )}
              >
                {REVENUE_PERIOD_LABEL[p]}
              </button>
            ))}
          </div>
          <SimTag>دفتر قيود تجريبي — الخصم الفعلي يحتاج الخادم</SimTag>
        </div>
      </Card>
    </section>
  );
}
