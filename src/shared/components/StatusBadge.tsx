import type { OrderStatus } from '@/domain/types';
import { orderStatusLabel, orderStatusTone, type StatusAudience } from '@/domain/orderStatus';
import { FRESHNESS_LABEL, type LocationFreshness } from '@/domain/location';
import { OP_STATUS_LABEL, type CaptainView } from '@/shared/hooks/application';
import { Badge } from './ui';

/** `scheduled` swaps in the scheduled-order wording while it waits for Admin coordination. */
export function OrderStatusBadge({ status, scheduled, audience = 'admin' }: { status: OrderStatus; scheduled?: boolean; audience?: StatusAudience }) {
  return (
    <Badge tone={orderStatusTone(status, audience)} dot>
      {orderStatusLabel(status, { scheduled, audience })}
    </Badge>
  );
}

const FRESHNESS_TONE = { live: 'success', stale: 'warning', last_known: 'neutral', demo: 'sand', none: 'neutral' } as const;

export function FreshnessBadge({ freshness }: { freshness: LocationFreshness }) {
  return <Badge tone={FRESHNESS_TONE[freshness]}>{FRESHNESS_LABEL[freshness]}</Badge>;
}

const OP_TONE = { available: 'success', busy: 'primary', offline: 'neutral', inactive: 'danger' } as const;

export function CaptainStatusBadge({ status }: { status: CaptainView['opStatus'] }) {
  return (
    <Badge tone={OP_TONE[status]} dot>
      {OP_STATUS_LABEL[status]}
    </Badge>
  );
}
