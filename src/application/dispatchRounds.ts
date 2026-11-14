import type { ActorRef, DeliveryOrder, ID } from '@/domain/types';
import {
  DISPATCH_ROUND_SEC,
  MAX_DISPATCH_ROUNDS,
  NO_CANDIDATE_REASON,
  ROUNDS_EXHAUSTED_REASON,
  isAutoDispatchEligible,
  rankByProximity,
} from '@/domain/dispatch';
import { SYSTEM_ACTOR, type AppData } from '@/application/data';
import { captainEligibility } from './captainQueries';
import { note, pushAlert, transition, uid } from './orderMutations';

// Public dispatch rounds (FU-1.2 §5). In the prototype the browser simulation clock
// drives expiry; in production rounds, expiry and the 3-round cap belong to a
// persisted backend job with atomic accept/expire handling.

/** Moves the order to the Admin queue with a visible reason. Never cancels or delivers it. */
function returnToQueue(data: AppData, order: DeliveryOrder, now: number, reason: string) {
  order.queueReason = reason;
  transition(order, 'dispatch_expired', SYSTEM_ACTOR, now, `${reason} — أُعيد إلى طابور الإدارة`);
  pushAlert(data, 'no_candidate', `الطلب ${order.reference}: ${reason} — بحاجة إلى إجراء من الإدارة`, now, order.id);
}

/**
 * Starts the next public round: offers the order to the next batch of nearest
 * eligible Captains not yet offered in this cycle (batch size = demo policy O-005),
 * each with a 60-second window. After the third round, no further round starts.
 */
function startRound(data: AppData, order: DeliveryOrder, now: number) {
  if (!data.settings.publicBroadcast) return; // switch off: no new public offers
  if (!isAutoDispatchEligible(order)) return; // scheduled: Admin-only
  const attempt = (order.dispatchAttempt ?? 0) + 1;
  if (attempt > MAX_DISPATCH_ROUNDS) return returnToQueue(data, order, now, ROUNDS_EXHAUSTED_REASON);

  const alreadyOffered = new Set(data.offers.filter((o) => o.orderId === order.id && o.round === order.dispatchRound).map((o) => o.captainId));
  const eligible = data.captains.filter((c) => !alreadyOffered.has(c.id) && captainEligibility(data, c).eligible);
  const size = data.demo.offerPolicy === 'sequential' ? 1 : Math.max(1, data.demo.groupSize);
  const batch = rankByProximity(eligible, order.pickup.position).slice(0, size);
  if (batch.length === 0) return returnToQueue(data, order, now, NO_CANDIDATE_REASON);

  order.dispatchAttempt = attempt;
  if (attempt > 1) note(order, SYSTEM_ACTOR, now, `لم يُقبل العرض — بدء الجولة ${attempt} من ${MAX_DISPATCH_ROUNDS}`);
  batch.forEach((r, i) => {
    data.offers.push({
      id: uid('of'),
      orderId: order.id,
      captainId: r.captain.id,
      mode: 'public',
      round: order.dispatchRound,
      attempt,
      status: 'pending',
      offeredAt: now,
      expiresAt: now + DISPATCH_ROUND_SEC * 1000,
      distanceMeters: r.distanceMeters,
      rank: alreadyOffered.size + i + 1,
    });
  });
}

/** Starts a new public cycle of up to three rounds (system on creation, or an explicit Admin publish). */
export function startPublicDispatch(data: AppData, order: DeliveryOrder, actor: ActorRef, now: number) {
  if (!isAutoDispatchEligible(order)) return;
  order.dispatchRound += 1;
  order.dispatchAttempt = 0;
  order.dispatchMode = 'public';
  order.queueReason = undefined;
  transition(order, 'awaiting_captain', actor, now, `نشر للعموم — ترتيب حسب القرب من التاجر، الجولة 1 من ${MAX_DISPATCH_ROUNDS}`);
  startRound(data, order, now);
}

/**
 * Called after an offer is rejected, expires or is withdrawn. A round ends when
 * none of its offers is still pending (all declined, or the 60 s window passed).
 */
export function afterOfferResolved(data: AppData, orderId: ID, now: number, reason: 'rejected' | 'expired' | 'withdrawn') {
  const order = data.orders.find((o) => o.id === orderId);
  if (!order) return;
  if (data.offers.some((o) => o.orderId === orderId && o.status === 'pending')) return;
  if (order.status === 'offered_privately') {
    const label = reason === 'rejected' ? 'رفض الكابتن العرض الخاص' : reason === 'expired' ? 'انتهت مهلة العرض الخاص' : 'سُحب العرض الخاص';
    order.queueReason = label;
    transition(order, 'pending_dispatch', SYSTEM_ACTOR, now, `${label} — أُعيد إلى طابور الإدارة`);
    pushAlert(data, 'private_returned', `الطلب ${order.reference}: ${label}، وعاد إلى طابور الإدارة`, now, order.id);
  } else if (order.status === 'awaiting_captain') {
    startRound(data, order, now);
  }
}
