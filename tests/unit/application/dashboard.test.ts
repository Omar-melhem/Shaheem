import { describe, expect, it } from 'vitest';
import { operationalKpis, scheduledForToday } from '@/application/dashboard';
import type { DeliveryOrder } from '@/domain/types';

// Amman is UTC+3 all year (IANA Asia/Amman since 2022); the code uses the time zone, never a fixed offset.
const NOW = Date.UTC(2026, 10, 18, 7, 0); // 2026-11-18 10:00 Amman
const YESTERDAY = Date.UTC(2026, 10, 17, 9, 0);

const o = (id: string, over: Partial<DeliveryOrder>): DeliveryOrder =>
  ({ id, createdAt: YESTERDAY, updatedAt: YESTERDAY, requestType: 'scheduled', status: 'pending_dispatch', ...over }) as DeliveryOrder;

describe('scheduledForToday («الطلبات المؤجلة اليوم»)', () => {
  it('counts by pickup day, not by creation day', () => {
    const createdYesterdayForToday = o('a', { createdAt: YESTERDAY, scheduledPickupAt: Date.UTC(2026, 10, 18, 12, 0) });
    const createdTodayForTomorrow = o('b', { createdAt: NOW, scheduledPickupAt: Date.UTC(2026, 10, 19, 12, 0) });
    expect(scheduledForToday([createdYesterdayForToday, createdTodayForTomorrow], NOW)).toBe(1);
  });

  it('uses the Amman calendar day: 01:30 Amman counts even though it is the previous UTC day', () => {
    const justAfterAmmanMidnight = o('a', { scheduledPickupAt: Date.UTC(2026, 10, 17, 22, 30) }); // 18 Nov 01:30 Amman
    const justBeforeAmmanMidnight = o('b', { scheduledPickupAt: Date.UTC(2026, 10, 17, 20, 59) }); // 17 Nov 23:59 Amman
    const lastMinuteToday = o('c', { scheduledPickupAt: Date.UTC(2026, 10, 18, 20, 59) }); // 18 Nov 23:59 Amman
    const firstMinuteTomorrow = o('d', { scheduledPickupAt: Date.UTC(2026, 10, 18, 21, 0) }); // 19 Nov 00:00 Amman
    expect(scheduledForToday([justAfterAmmanMidnight, justBeforeAmmanMidnight, lastMinuteToday, firstMinuteTomorrow], NOW)).toBe(2);
  });

  it('rolls over at Amman midnight', () => {
    const tomorrowMorning = o('a', { scheduledPickupAt: Date.UTC(2026, 10, 19, 6, 0) });
    expect(scheduledForToday([tomorrowMorning], Date.UTC(2026, 10, 18, 20, 59))).toBe(0); // 23:59 Amman
    expect(scheduledForToday([tomorrowMorning], Date.UTC(2026, 10, 18, 21, 0))).toBe(1); // 00:00 Amman next day
  });

  it('excludes immediate and cancelled orders, keeps delivered and in-progress ones, counts each once', () => {
    const pickup = Date.UTC(2026, 10, 18, 9, 0);
    const orders = [
      o('waiting', { scheduledPickupAt: pickup }),
      o('offered', { status: 'offered_privately', scheduledPickupAt: pickup }),
      o('delivering', { status: 'on_the_way', scheduledPickupAt: pickup }),
      o('delivered', { status: 'delivered', scheduledPickupAt: pickup, deliveredAt: pickup + 3_600_000 }),
      o('cancelled', { status: 'cancelled', scheduledPickupAt: pickup }),
      o('immediate', { requestType: 'immediate', createdAt: NOW }),
      o('no-time', { scheduledPickupAt: undefined }),
    ];
    expect(scheduledForToday(orders, NOW)).toBe(4);
  });

  it('a confirmed empty day is 0 and is part of the operational KPIs', () => {
    expect(scheduledForToday([], NOW)).toBe(0);
    const kpis = operationalKpis([o('a', { scheduledPickupAt: Date.UTC(2026, 10, 18, 9, 0) })], NOW);
    expect(kpis.scheduledToday).toBe(1);
  });
});
