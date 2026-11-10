import { Check } from 'lucide-react';
import type { DeliveryOrder } from '@/domain/types';
import { DELIVERY_STAGES, ORDER_STATUS_LABEL } from '@/domain/orderStatus';
import { formatDateTime, formatTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

const ACTOR_LABEL = { admin: 'الإدارة', merchant: 'التاجر', captain: 'الكابتن', system: 'النظام' } as const;

/** Full audit trail: every state change with actor and timestamp (SRS §9.4). */
export function OrderHistoryList({ order }: { order: DeliveryOrder }) {
  return (
    <ol className="relative space-y-3 border-s-2 border-cream-deep ps-4">
      {[...order.history].reverse().map((h, i) => (
        <li key={i} className="relative">
          <span className="absolute -start-[23px] top-1.5 h-3 w-3 rounded-full border-2 border-white bg-primary" aria-hidden />
          <p className="text-sm font-bold text-ink">
            {h.from === h.to ? (h.note ?? ORDER_STATUS_LABEL[h.to]) : ORDER_STATUS_LABEL[h.to]}
          </p>
          <p className="text-xs text-ink-muted">
            {ACTOR_LABEL[h.actor.role]} — {h.actor.name} · {formatDateTime(h.at)}
          </p>
          {h.note && h.from !== h.to && <p className="mt-0.5 text-xs text-ink-soft">{h.note}</p>}
        </li>
      ))}
    </ol>
  );
}

/** Compact progress stepper for the delivery stages. */
export function DeliveryProgress({ order, compact }: { order: DeliveryOrder; compact?: boolean }) {
  const currentIdx = DELIVERY_STAGES.indexOf(order.status);
  const reachedAt = (s: string) => order.history.find((h) => h.to === s && h.from !== h.to)?.at;
  if (currentIdx < 0) return null;
  return (
    <ol className={cn('flex items-start', compact ? 'gap-1' : 'gap-2')}>
      {DELIVERY_STAGES.map((s, i) => {
        const done = i <= currentIdx;
        const at = reachedAt(s);
        return (
          <li key={s} className="flex flex-1 flex-col items-center text-center">
            <div className="flex w-full items-center">
              <span className={cn('h-0.5 flex-1', i === 0 ? 'opacity-0' : done ? 'bg-secondary' : 'bg-cream-deep')} />
              <span
                className={cn(
                  'flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[11px] font-bold',
                  done ? 'bg-secondary text-white' : 'bg-cream-dark text-ink-muted',
                  i === currentIdx && order.status !== 'delivered' && 'ring-4 ring-secondary-100',
                )}
              >
                {done ? <Check className="h-3.5 w-3.5" /> : i + 1}
              </span>
              <span className={cn('h-0.5 flex-1', i === DELIVERY_STAGES.length - 1 ? 'opacity-0' : i < currentIdx ? 'bg-secondary' : 'bg-cream-deep')} />
            </div>
            {!compact && (
              <>
                <span className={cn('mt-1 text-[11px] leading-tight', done ? 'font-bold text-ink' : 'text-ink-muted')}>{ORDER_STATUS_LABEL[s]}</span>
                {at && <span className="text-[10px] text-ink-muted">{formatTime(at)}</span>}
              </>
            )}
          </li>
        );
      })}
    </ol>
  );
}
