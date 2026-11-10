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
