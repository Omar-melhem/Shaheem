import type { ActorRef, AlertKind, DeliveryOrder, ID, OrderStatus } from '@/domain/types';
import type { AppData } from '@/application/data';

// Small mutation helpers used inside store use cases (immer drafts).

export const uid = (prefix: string) => `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;

export function transition(order: DeliveryOrder, to: OrderStatus, actor: ActorRef, now: number, note?: string) {
  order.history.push({ from: order.status, to, actor, at: now, note });
  order.status = to;
  order.updatedAt = now;
}

/** Records an event in the order history without changing its status. */
export function note(order: DeliveryOrder, actor: ActorRef, now: number, text: string) {
  order.history.push({ from: order.status, to: order.status, actor, at: now, note: text });
}

export function pushAlert(data: AppData, kind: AlertKind, message: string, now: number, orderId?: ID) {
  data.alerts.unshift({ id: uid('al'), kind, message, at: now, orderId, read: false });
  if (data.alerts.length > 60) data.alerts.length = 60;
}

export function withdrawPendingOffers(data: AppData, orderId: ID, now: number, exceptOfferId?: ID) {
  for (const offer of data.offers) {
    if (offer.orderId === orderId && offer.status === 'pending' && offer.id !== exceptOfferId) {
      offer.status = 'withdrawn';
      offer.respondedAt = now;
    }
  }
}
