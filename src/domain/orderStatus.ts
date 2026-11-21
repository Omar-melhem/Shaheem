import type { OrderStatus } from './types';

// Proposed state identifiers from SRS §9.2. Final transitions/actors are open (O-029, O-030, O-034).

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  pending_dispatch: 'بانتظار التوزيع',
  awaiting_captain: 'معروض على الكباتن',
  offered_privately: 'معروض بشكل خاص',
  accepted: 'تم القبول',
  heading_to_pickup: 'في الطريق إلى التاجر',
  picked_up: 'تم الاستلام من التاجر',
  on_the_way: 'في الطريق إلى العميل',
  delivered: 'تم التسليم',
  cancelled: 'ملغي',
  dispatch_expired: 'انتهى التوزيع دون إسناد',
};

export type StatusTone = 'neutral' | 'sand' | 'warning' | 'primary' | 'info' | 'success' | 'danger';

export const ORDER_STATUS_TONE: Record<OrderStatus, StatusTone> = {
  pending_dispatch: 'sand',
  awaiting_captain: 'warning',
  offered_privately: 'warning',
  accepted: 'info',
  heading_to_pickup: 'primary',
  picked_up: 'primary',
  on_the_way: 'primary',
  delivered: 'success',
  cancelled: 'neutral',
  dispatch_expired: 'danger',
};

/** Orders sitting in the Admin-controlled queue. */
export const QUEUE_STATUSES: OrderStatus[] = ['pending_dispatch', 'dispatch_expired'];

/** Orders currently being offered to one or more Captains. */
export const OFFERING_STATUSES: OrderStatus[] = ['awaiting_captain', 'offered_privately'];

/** Orders assigned to a Captain and not yet finished. */
export const ACTIVE_DELIVERY_STATUSES: OrderStatus[] = ['accepted', 'heading_to_pickup', 'picked_up', 'on_the_way'];

export const FINAL_STATUSES: OrderStatus[] = ['delivered', 'cancelled'];

/** Pre-acceptance states where the demo lets Admin cancel. Real policy is open (O-029). */
export const CANCELLABLE_STATUSES: OrderStatus[] = [...QUEUE_STATUSES, ...OFFERING_STATUSES];

/** Captain-driven delivery stages, all mandatory in the prototype (O-034 open). */
export const CAPTAIN_NEXT_STATUS: Partial<Record<OrderStatus, OrderStatus>> = {
  accepted: 'heading_to_pickup',
  heading_to_pickup: 'picked_up',
  picked_up: 'on_the_way',
  on_the_way: 'delivered',
};

export const CAPTAIN_NEXT_ACTION_LABEL: Partial<Record<OrderStatus, string>> = {
  accepted: 'بدء التوجه إلى التاجر',
  heading_to_pickup: 'تأكيد الاستلام من التاجر',
  picked_up: 'بدء التوجه إلى العميل',
  on_the_way: 'تأكيد التسليم',
};

export const DELIVERY_STAGES: OrderStatus[] = ['accepted', 'heading_to_pickup', 'picked_up', 'on_the_way', 'delivered'];

/** Wording for scheduled orders before a Captain is assigned (CR v1.4 §6.3). */
export const SCHEDULED_STATUS_LABEL: Partial<Record<OrderStatus, string>> = {
  pending_dispatch: 'بانتظار تنسيق الإدارة',
  dispatch_expired: 'بانتظار تنسيق الإدارة',
  offered_privately: 'بانتظار قبول الكابتن',
};

export const isActiveDelivery = (s: OrderStatus) => ACTIVE_DELIVERY_STATUSES.includes(s);
export const isInQueue = (s: OrderStatus) => QUEUE_STATUSES.includes(s);
export const isOffering = (s: OrderStatus) => OFFERING_STATUSES.includes(s);

/**
 * One grouping of order statuses for every count and group heading (dashboard, distribution
 * center, orders, merchant). Scheduled orders awaiting manual coordination form their own group
 * (CR v1.4 §6.2), so the immediate-order groups never silently include them. Each order belongs
 * to exactly one group.
 */
export type OrderStatusGroup = 'pending_dispatch' | 'scheduled_pending' | 'offered' | 'needs_admin' | 'active' | 'delivered' | 'cancelled';

export const ORDER_GROUP_LABEL: Record<OrderStatusGroup, string> = {
  pending_dispatch: 'بانتظار التوزيع',
  scheduled_pending: 'طلبات مؤجلة',
  offered: 'معروضة على الكباتن',
  needs_admin: 'بحاجة لتدخل الإدارة',
  active: 'توصيلات نشطة',
  delivered: 'تم التسليم',
  cancelled: 'ملغاة',
};

export function orderStatusGroup(order: { status: OrderStatus; requestType?: 'immediate' | 'scheduled' }): OrderStatusGroup {
  const { status } = order;
  if (order.requestType === 'scheduled' && (isInQueue(status) || isOffering(status))) return 'scheduled_pending';
  if (status === 'pending_dispatch') return 'pending_dispatch';
  if (status === 'dispatch_expired') return 'needs_admin';
  if (isOffering(status)) return 'offered';
  if (isActiveDelivery(status)) return 'active';
  return status === 'delivered' ? 'delivered' : 'cancelled';
}

export type OrderGroupCounts = Record<OrderStatusGroup, number>;

export function countByGroup(orders: ReadonlyArray<{ status: OrderStatus; requestType?: 'immediate' | 'scheduled' }>): OrderGroupCounts {
  const counts: OrderGroupCounts = { pending_dispatch: 0, scheduled_pending: 0, offered: 0, needs_admin: 0, active: 0, delivered: 0, cancelled: 0 };
  for (const o of orders) counts[orderStatusGroup(o)] += 1;
  return counts;
}

/**
 * Demo assumption (no approved SLA): an active delivery whose status has not changed for this long
 * is flagged as late on the live map, even when its simulated GPS is still updating.
 */
export const LATE_DELIVERY_AFTER_MIN = 60;

export const isDeliveryLate = (order: { status: OrderStatus; updatedAt: number }, now: number) =>
  isActiveDelivery(order.status) && now - order.updatedAt > LATE_DELIVERY_AFTER_MIN * 60_000;
