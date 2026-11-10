import type { DeliveryOrder, ID } from '@/domain/types';
import { FINAL_STATUSES, isActiveDelivery, isInQueue, isOffering } from '@/domain/orderStatus';
import { ammanDayKey } from '@/domain/time';

export interface OperationalKpis {
  queue: number;
  offered: number;
  activeDeliveries: number;
  deliveredToday: number;
}

export interface PlatformKpis {
  merchants: number;
  captains: number;
}

/** «مؤشرات التشغيل»: the four live order counts. «Today» is the Amman calendar day. */
export function operationalKpis(orders: DeliveryOrder[], now: number): OperationalKpis {
  const today = ammanDayKey(now);
  return {
    queue: orders.filter((o) => isInQueue(o.status)).length,
    offered: orders.filter((o) => isOffering(o.status)).length,
    activeDeliveries: orders.filter((o) => isActiveDelivery(o.status)).length,
    deliveredToday: orders.filter((o) => o.status === 'delivered' && o.deliveredAt !== undefined && ammanDayKey(o.deliveredAt) === today).length,
  };
}

/** «حسابات المنصة»: account totals only (availability is shown on the Captains page and live map). */
export function platformKpis(input: { merchantCount: number; captainCount: number }): PlatformKpis {
  return { merchants: input.merchantCount, captains: input.captainCount };
}

export interface MerchantOrderOverview {
  /** Not delivered or cancelled yet, newest update first. */
  active: DeliveryOrder[];
  /** Delivered or cancelled, newest first. */
  history: DeliveryOrder[];
}

export const MERCHANT_RECENT_PREVIEW = 3;

/** One Merchant's orders only (isolation), split into active and finished. */
export function merchantOrderOverview(orders: DeliveryOrder[], merchantId: ID | undefined): MerchantOrderOverview {
  const mine = orders.filter((o) => o.merchantId === merchantId);
  return {
    active: mine.filter((o) => !FINAL_STATUSES.includes(o.status)).sort((a, b) => b.updatedAt - a.updatedAt),
    history: mine.filter((o) => FINAL_STATUSES.includes(o.status)).sort((a, b) => b.createdAt - a.createdAt),
  };
}
