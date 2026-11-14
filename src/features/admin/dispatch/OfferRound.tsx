import { useAppStore } from '@/app/state';
import type { DeliveryOrder, DispatchOffer } from '@/domain/types';
import { MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { formatDistance } from '@/domain/geo';
import { Badge } from '@/shared/components/ui';
import { formatCountdown } from '@/shared/lib/format';

const OFFER_STATUS_LABEL: Record<DispatchOffer['status'], string> = {
  pending: 'بانتظار الرد',
  accepted: 'قَبِل',
  rejected: 'رفض',
  expired: 'انتهت المهلة',
  withdrawn: 'سُحب',
};
const OFFER_TONE = { pending: 'warning', accepted: 'success', rejected: 'danger', expired: 'neutral', withdrawn: 'neutral' } as const;

/** Current round of an order being offered: "الجولة 2 من 3", time left, and each Captain's response. */
export function OfferRound({ order, now }: { order: DeliveryOrder; now: number }) {
  const offers = useAppStore((s) => s.offers);
  const captains = useAppStore((s) => s.captains);
  const isPublic = order.status === 'awaiting_captain';
  const cycle = offers
    .filter((x) => x.orderId === order.id && x.round === order.dispatchRound)
    .sort((a, b) => (a.attempt ?? 0) - (b.attempt ?? 0) || (a.rank ?? 0) - (b.rank ?? 0));
  const pending = cycle.filter((x) => x.status === 'pending');
  const endsAt = pending.length ? Math.max(...pending.map((x) => x.expiresAt)) : undefined;
  const captainName = (id: string) => captains.find((c) => c.id === id)?.fullName ?? '—';

  return (
    <div className="space-y-2 rounded-xl bg-cream p-3">
      <div className="flex flex-wrap items-center gap-2 text-sm">
        {isPublic ? (
          <Badge tone="warning">الجولة {order.dispatchAttempt ?? 1} من {MAX_DISPATCH_ROUNDS}</Badge>
        ) : (
          <Badge tone="info">عرض خاص</Badge>
        )}
        {endsAt !== undefined && (
          <span className="text-xs text-ink-soft">
            تنتهي خلال <span className="font-mono font-bold text-amber-800" dir="ltr">{formatCountdown(endsAt - now)}</span>
          </span>
        )}
      </div>
      <ul className="space-y-1.5">
        {cycle.map((x) => (
          <li key={x.id} className="flex flex-wrap items-center gap-2 text-sm">
            {x.attempt && <span className="w-14 text-xs text-ink-muted">جولة {x.attempt}</span>}
            <span className="flex-1 font-medium">{captainName(x.captainId)}</span>
            {x.distanceMeters !== undefined && <span className="text-xs text-ink-muted">{formatDistance(x.distanceMeters)}</span>}
            <Badge tone={OFFER_TONE[x.status]}>{OFFER_STATUS_LABEL[x.status]}</Badge>
          </li>
        ))}
      </ul>
    </div>
  );
}
