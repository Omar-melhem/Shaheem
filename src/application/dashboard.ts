import type { DeliveryOrder, ID } from '@/domain/types';
import { FINAL_STATUSES, isActiveDelivery, isInQueue, isOffering } from '@/domain/orderStatus';
import { ammanDayKey } from '@/domain/time';
import type { LocationFreshness } from '@/domain/location';

/** The slice of a Captain view the overview needs (keeps this module free of React hooks). */
export interface CaptainSnapshot {
  opStatus: 'inactive' | 'offline' | 'busy' | 'available';
  eligible: boolean;
  freshness: LocationFreshness;
}

export interface DashboardInput {
  orders: DeliveryOrder[];
  merchantCount: number;
  captains: CaptainSnapshot[];
  publicBroadcast: boolean;
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

export interface ActivityDay {
  dayKey: string;
  /** A timestamp inside that Amman day, for formatting the label. */
  at: number;
  created: number;
  delivered: number;
}

export interface OperationalAlert {
  id: string;
  tone: 'warning' | 'danger';
  title: string;
  detail: string;
  to: string;
  actionLabel: string;
}

export const ACTIVITY_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;

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

/** Orders created and delivered per Amman day, oldest first, from real order timestamps only. */
export function orderActivity(orders: DeliveryOrder[], now: number, days = ACTIVITY_DAYS): ActivityDay[] {
  const result: ActivityDay[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const at = now - i * DAY_MS;
    result.push({ dayKey: ammanDayKey(at), at, created: 0, delivered: 0 });
  }
  const byKey = new Map(result.map((d) => [d.dayKey, d]));
  for (const o of orders) {
    const created = byKey.get(ammanDayKey(o.createdAt));
    if (created) created.created += 1;
    if (o.status === 'delivered' && o.deliveredAt !== undefined) {
      const delivered = byKey.get(ammanDayKey(o.deliveredAt));
      if (delivered) delivered.delivered += 1;
    }
  }
  return result;
}

/** Only alerts the data actually supports, each with the page that resolves it. */
export function operationalAlerts(input: DashboardInput): OperationalAlert[] {
  const alerts: OperationalAlert[] = [];
  const waiting = input.orders.filter((o) => isInQueue(o.status)).length;
  const offered = input.orders.filter((o) => isOffering(o.status)).length;
  const eligible = input.captains.filter((c) => c.eligible).length;
  const blindDeliveries = input.captains.filter((c) => c.opStatus === 'busy' && (c.freshness === 'stale' || c.freshness === 'none')).length;

  if (!input.publicBroadcast) {
    alerts.push({
      id: 'broadcast-off', tone: 'warning', title: 'البث العام متوقف',
      detail: 'الطلبات الجديدة لا تُعرض على الكباتن وتبقى في طابور الإدارة حتى تُسند يدوياً أو يُعاد تفعيل البث.',
      to: '/admin/dispatch', actionLabel: 'مركز التوزيع',
    });
  }
  if (waiting > 0) {
    alerts.push({
      id: 'queue', tone: 'warning', title: `${waiting} طلب بانتظار التوزيع`,
      detail: 'طلبات لم تُعرض أو انتهت جولاتها دون قبول، وتحتاج إسناداً من الإدارة.',
      to: '/admin/dispatch', actionLabel: 'إسناد الطلبات',
    });
  }
  if (waiting + offered > 0 && eligible === 0) {
    alerts.push({
      id: 'no-eligible', tone: 'danger', title: 'لا يوجد كابتن مؤهل الآن',
      detail: 'هناك طلبات تنتظر كابتناً ولا يوجد أي كابتن يستوفي شروط استقبال العروض (التوفر، الحساب، المحفظة، الموقع).',
      to: '/admin/captains', actionLabel: 'الكباتن',
    });
  }
  if (blindDeliveries > 0) {
    alerts.push({
      id: 'gps', tone: 'danger', title: `${blindDeliveries} توصيل بلا موقع حديث`,
      detail: 'آخر موقع لكابتن أثناء التوصيل قديم أو غير متوفر؛ لا يمكن متابعة مكانه الآن.',
      to: '/admin/map', actionLabel: 'الخريطة الحية',
    });
  }
  return alerts;
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
