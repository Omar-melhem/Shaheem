import type { OrderStatus } from '@/domain/types';
import { ORDER_STATUS_LABEL, ORDER_STATUS_TONE, SCHEDULED_STATUS_LABEL } from '@/domain/orderStatus';
import { FRESHNESS_LABEL, type LocationFreshness } from '@/domain/location';
import { OP_STATUS_LABEL, type CaptainView } from '@/application/hooks';
import { Badge } from './ui';

/** `scheduled` swaps in the scheduled-order wording while it waits for Admin coordination. */
export function OrderStatusBadge({ status, scheduled }: { status: OrderStatus; scheduled?: boolean }) {
  return (
    <Badge tone={ORDER_STATUS_TONE[status]} dot>
      {(scheduled && SCHEDULED_STATUS_LABEL[status]) || ORDER_STATUS_LABEL[status]}
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
