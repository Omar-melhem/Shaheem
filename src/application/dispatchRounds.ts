import type { ActorRef, DeliveryOrder, ID } from '@/domain/types';
import {
  DISPATCH_ROUND_SEC,
  MAX_DISPATCH_RADIUS_M,
  MAX_DISPATCH_ROUNDS,
  ROUNDS_EXHAUSTED_REASON,
  describeRound,
  isAutoDispatchEligible,
  rankByProximity,
  roundPolicy,
  roundsEndedReason,
  selectRoundCandidates,
} from '@/domain/dispatch';
import { SYSTEM_ACTOR, type AppData } from '@/application/data';
import { eligibleCaptains } from './captainQueries';
import { note, pushAlert, transition, uid } from './orderMutations';

// Public dispatch rounds (owner, 2026-11-25: 3 within 5 km → next 3 within 10 km → all left within
// 10 km, 60 s each). In the prototype the browser simulation clock drives expiry; in production the
// rounds, their persisted start/expiry times, atomic accept/expire and the 3-round cap belong to a
// backend job — a page timer is never the dispatcher clock.

/** Moves the order to the Admin queue with a visible reason. Never cancels or delivers it. */
function returnToQueue(data: AppData, order: DeliveryOrder, now: number, reason: string) {
  order.queueReason = reason;
  transition(order, 'dispatch_expired', SYSTEM_ACTOR, now, `${reason} — أُعيد إلى طابور الإدارة`);
  pushAlert(data, 'no_candidate', `الطلب ${order.reference}: ${reason} — بحاجة إلى إجراء من الإدارة`, now, order.id);
}

/**
 * Starts the next public round. Candidates are re-checked for eligibility now, ranked by distance
 * from the Merchant pickup, limited to the round's radius and size, and never include a Captain
 * already offered this order in the cycle. A round with nobody in range is skipped (noted in the
 * history) rather than waited out empty. After the last round the order goes to the Admin queue.
 */
function startRound(data: AppData, order: DeliveryOrder, now: number) {
  if (!data.settings.publicBroadcast) return; // switch off: no new public offers
  if (!isAutoDispatchEligible(order)) return; // scheduled: Admin-only
  const previous = order.dispatchAttempt ?? 0;
  if (previous >= MAX_DISPATCH_ROUNDS) return returnToQueue(data, order, now, ROUNDS_EXHAUSTED_REASON);

  const cycleOffers = data.offers.filter((o) => o.orderId === order.id && o.round === order.dispatchRound);
  const alreadyOffered = new Set(cycleOffers.map((o) => o.captainId));
  const eligibleNow = eligibleCaptains(data);
  const ranked = rankByProximity(eligibleNow, order.pickup.position);

  for (let attempt = previous + 1; attempt <= MAX_DISPATCH_ROUNDS; attempt++) {
    const policy = roundPolicy(attempt)!;
    const batch = selectRoundCandidates(ranked, policy, alreadyOffered);
    if (batch.length === 0) {
      note(order, SYSTEM_ACTOR, now, `الجولة ${attempt} من ${MAX_DISPATCH_ROUNDS}: لا يوجد مستلم جديد (${describeRound(policy)})`);
      continue;
    }
    order.dispatchAttempt = attempt;
    note(order, SYSTEM_ACTOR, now, `بدء الجولة ${attempt} من ${MAX_DISPATCH_ROUNDS}: ${describeRound(policy)} — ${batch.length} عرض`);
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
        rank: cycleOffers.length + i + 1,
      });
    });
    return;
  }
  order.dispatchAttempt = MAX_DISPATCH_ROUNDS;
  const inRange = ranked.filter((r) => r.distanceMeters <= MAX_DISPATCH_RADIUS_M).length;
  returnToQueue(data, order, now, roundsEndedReason(eligibleNow.length, inRange));
}

/** Starts a new public cycle of up to three rounds (system on creation, or an explicit Admin publish). */
export function startPublicDispatch(data: AppData, order: DeliveryOrder, actor: ActorRef, now: number) {
  if (!isAutoDispatchEligible(order)) return;
  order.dispatchRound += 1;
  order.dispatchAttempt = 0;
  order.dispatchMode = 'public';
  order.queueReason = undefined;
  transition(order, 'awaiting_captain', actor, now, `نشر للعموم — حتى ${MAX_DISPATCH_ROUNDS} جولات حسب القرب من موقع التاجر`);
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
