import type { DeliveryOrder } from '@/domain/types';
import { orderStatusGroup, type OrderStatusGroup } from '@/domain/orderStatus';

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
 * Distribution Center queues (FU-1.2 §5, CR v1.4 §6). Membership is the shared `orderStatusGroup`,
 * so every list matches the counts on the dashboard and the dispatch summary. Every order lands in
 * at most one list. The page renders these lists; it never classifies orders itself.
 */
export function dispatchQueues(orders: DeliveryOrder[]): DispatchQueues {
  const inGroup = (group: OrderStatusGroup) => orders.filter((o) => orderStatusGroup(o) === group);
  return {
    scheduled: inGroup('scheduled_pending').sort((a, b) => (a.scheduledPickupAt ?? 0) - (b.scheduledPickupAt ?? 0)),
    intervention: inGroup('needs_admin').sort(byAge),
    waiting: inGroup('pending_dispatch').sort(byAge),
    offering: inGroup('offered').sort(byAge),
  };
}
