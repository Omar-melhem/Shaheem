import type { DeliveryOrder } from '@/domain/types';
import { isAutoDispatchEligible } from '@/domain/dispatch';
import { isInQueue, isOffering } from '@/domain/orderStatus';

export interface DispatchQueues {
  /** Scheduled orders awaiting manual coordination (queue or a private offer), by pickup time. */
  scheduled: DeliveryOrder[];
  /** Immediate orders whose automatic rounds ended without acceptance, oldest first. */
  intervention: DeliveryOrder[];
  /** Immediate orders not offered yet, oldest first. */
  waiting: DeliveryOrder[];
  /** Immediate orders currently offered to Captains (public round or private offer). */
  offering: DeliveryOrder[];
}

const byAge = (a: DeliveryOrder, b: DeliveryOrder) => a.createdAt - b.createdAt;

/**
 * Distribution Center queues (FU-1.2 §5, CR v1.4 §6). Every order lands in at most one list:
 * scheduled orders always stay in their own queue until accepted, and immediate orders are split
 * by status. The page renders these lists; it never classifies orders itself.
 */
export function dispatchQueues(orders: DeliveryOrder[]): DispatchQueues {
  const isScheduledPending = (o: DeliveryOrder) => o.requestType === 'scheduled' && (isInQueue(o.status) || o.status === 'offered_privately');
  const immediate = orders.filter(isAutoDispatchEligible);
  return {
    scheduled: orders.filter(isScheduledPending).sort((a, b) => (a.scheduledPickupAt ?? 0) - (b.scheduledPickupAt ?? 0)),
    intervention: immediate.filter((o) => o.status === 'dispatch_expired').sort(byAge),
    waiting: immediate.filter((o) => o.status === 'pending_dispatch').sort(byAge),
    offering: orders.filter((o) => isOffering(o.status) && !isScheduledPending(o)).sort(byAge),
  };
}
