import type { DeliveryOrder, ID } from '@/domain/types';
import { FINAL_STATUSES, isActiveDelivery, isInQueue, isOffering } from '@/domain/orderStatus';
import { ammanDayKey } from '@/domain/time';

/** The slice of a Captain view the overview needs (keeps this module free of React hooks). */
export interface CaptainSnapshot {
  opStatus: 'inactive' | 'offline' | 'busy' | 'available';
}

export interface DashboardInput {
  orders: DeliveryOrder[];
  merchantCount: number;
  captains: CaptainSnapshot[];
}

export interface OperationalKpis {
  queue: number;
  offered: number;
  activeDeliveries: number;
  deliveredToday: number;
}

export interface PlatformKpis {
  availableNow: number;
  /** Denominator for «المتاحون الآن»: active (not deactivated) Captain accounts. */
  activeCaptainAccounts: number;
  merchants: number;
  captains: number;
}

export type AvailabilitySummary = Record<CaptainSnapshot['opStatus'], number>;

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

/** «حسابات المنصة»: available Captains out of active accounts, plus account totals. */
export function platformKpis(input: Pick<DashboardInput, 'merchantCount' | 'captains'>): PlatformKpis {
  return {
    availableNow: input.captains.filter((c) => c.opStatus === 'available').length,
    activeCaptainAccounts: input.captains.filter((c) => c.opStatus !== 'inactive').length,
    merchants: input.merchantCount,
    captains: input.captains.length,
  };
}

export function availabilitySummary(captains: CaptainSnapshot[]): AvailabilitySummary {
  const summary: AvailabilitySummary = { available: 0, busy: 0, offline: 0, inactive: 0 };
  for (const c of captains) summary[c.opStatus] += 1;
  return summary;
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
