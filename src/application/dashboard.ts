import type { DeliveryOrder, ID, Money, WalletTransaction } from '@/domain/types';
import { realizedCommission } from '@/domain/wallet';
import { FINAL_STATUSES, countByGroup, isActiveDelivery } from '@/domain/orderStatus';
import { ammanDayKey } from '@/domain/time';

/** Group counts come from `countByGroup`, the same helper the distribution center uses. */
export interface OperationalKpis {
  pendingDispatch: number;
  needsAdmin: number;
  offered: number;
  activeDeliveries: number;
  deliveredToday: number;
  /** «الطلبات المؤجلة اليوم»: see `scheduledForToday`. */
  scheduledToday: number;
}

export interface PlatformKpis {
  merchants: number;
  captains: number;
}

/**
 * Today's scheduled workload: scheduled (مؤجل) orders whose pickup falls on the Amman calendar
 * day of `now` — by pickup time, never by creation time. Every status counts (waiting, offered,
 * delivering, delivered) except cancelled. Immediate orders never count. Each order counts once.
 */
export function scheduledForToday(orders: DeliveryOrder[], now: number): number {
  const today = ammanDayKey(now);
  return orders.filter(
    (o) => o.requestType === 'scheduled' && o.status !== 'cancelled' && o.scheduledPickupAt !== undefined && ammanDayKey(o.scheduledPickupAt) === today,
  ).length;
}

/** «مؤشرات التشغيل»: the live order counts. «Today» is the Amman calendar day. */
export function operationalKpis(orders: DeliveryOrder[], now: number): OperationalKpis {
  const today = ammanDayKey(now);
  const groups = countByGroup(orders);
  return {
    pendingDispatch: groups.pending_dispatch,
    needsAdmin: groups.needs_admin,
    offered: groups.offered,
    activeDeliveries: groups.active,
    deliveredToday: orders.filter((o) => o.status === 'delivered' && o.deliveredAt !== undefined && ammanDayKey(o.deliveredAt) === today).length,
    scheduledToday: scheduledForToday(orders, now),
  };
}

/** «حسابات المنصة»: account totals only (availability is shown on the Captains page and live map). */
export function platformKpis(input: { merchantCount: number; captainCount: number }): PlatformKpis {
  return { merchants: input.merchantCount, captains: input.captainCount };
}

export interface MerchantOrderOverview {
  /** Assigned to a Captain and on the way (accepted → on the way), newest update first. */
  active: DeliveryOrder[];
  /** Not finished and no Captain yet (waiting, offered or back with Admin), newest update first. */
  waiting: DeliveryOrder[];
  /** Delivered or cancelled, newest first. */
  history: DeliveryOrder[];
}

export const MERCHANT_RECENT_PREVIEW = 3;

const hasCaptain = (o: DeliveryOrder) => !!o.captainId && isActiveDelivery(o.status);
const byLatestUpdate = (a: DeliveryOrder, b: DeliveryOrder) => b.updatedAt - a.updatedAt;

/** One Merchant's orders only (isolation), split into active (with a Captain), waiting for a Captain, and finished. */
export function merchantOrderOverview(orders: DeliveryOrder[], merchantId: ID | undefined): MerchantOrderOverview {
  const mine = orders.filter((o) => o.merchantId === merchantId);
  const open = mine.filter((o) => !FINAL_STATUSES.includes(o.status));
  return {
    active: open.filter(hasCaptain).sort(byLatestUpdate),
    waiting: open.filter((o) => !hasCaptain(o)).sort(byLatestUpdate),
    history: mine.filter((o) => FINAL_STATUSES.includes(o.status)).sort((a, b) => b.createdAt - a.createdAt),
  };
}

export type RevenuePeriod = 'today' | 'month' | 'all';
export const REVENUE_PERIOD_LABEL: Record<RevenuePeriod, string> = { today: 'اليوم', month: 'هذا الشهر', all: 'الإجمالي' };

export interface CommissionRevenue {
  amount: Money;
  /** Delivered orders whose commission is in `amount`. */
  orders: number;
}

/**
 * «أرباح شهم»: commission finalised on delivered orders, by the Amman calendar day or month of the
 * debit. Top-ups, holds on undelivered orders and «مجموع الطلب» are never included. Gross
 * commission revenue, not net profit.
 */
export function commissionRevenue(walletTx: WalletTransaction[], now: number, period: RevenuePeriod): CommissionRevenue {
  const today = ammanDayKey(now);
  const inPeriod = (t: WalletTransaction) =>
    period === 'all' ? true : period === 'today' ? ammanDayKey(t.createdAt) === today : ammanDayKey(t.createdAt).slice(0, 7) === today.slice(0, 7);
  return {
    amount: realizedCommission(walletTx, inPeriod),
    orders: walletTx.filter((t) => t.type === 'commission_debit' && inPeriod(t)).length,
  };
}
