import { startDemoClock } from '@/app/state';
import { useEffect, useMemo, useState } from 'react';
import { useAppStore, captainActiveOrder, captainBalance, captainEligibility, eligibleCaptains } from '@/app/state';
import { liveMapPresence, locationFreshness, type LocationFreshness, type MapPresence } from '@/domain/location';
import type { Captain, ID } from '@/domain/types';
import type { Eligibility } from '@/domain/eligibility';

/** Re-renders on an interval so countdowns and freshness labels stay current. */
export function useNow(intervalMs = 1000): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), intervalMs);
    return () => clearInterval(t);
  }, [intervalMs]);
  return now;
}

export interface CaptainView {
  captain: Captain;
  balance: number;
  eligibility: Eligibility;
  activeOrderId?: ID;
  freshness: LocationFreshness;
  /** Derived operational status for display. */
  opStatus: 'inactive' | 'offline' | 'busy' | 'available';
  /** Whether and how the Captain appears on the live map (`liveMapPresence`). */
  presence: MapPresence;
}

/** Combines a Captain with derived wallet, eligibility and location freshness. */
export function useCaptainViews(now: number): CaptainView[] {
  const captains = useAppStore((s) => s.captains);
  const orders = useAppStore((s) => s.orders);
  const walletTx = useAppStore((s) => s.walletTx);
  const demo = useAppStore((s) => s.demo);
  return useMemo(() => {
    const data = useAppStore.getState();
    return captains.map((captain) => {
      const active = captainActiveOrder(data, captain.id);
      const opStatus: CaptainView['opStatus'] =
        captain.status !== 'active' ? 'inactive' : active ? 'busy' : captain.availability === 'available' ? 'available' : 'offline';
      const freshness = locationFreshness(captain, now, demo.staleAfterSec, active?.id);
      return {
        captain,
        balance: captainBalance(data, captain.id),
        eligibility: captainEligibility(data, captain),
        activeOrderId: active?.id,
        freshness,
        opStatus,
        presence: liveMapPresence({ accountActive: captain.status === 'active', available: captain.availability === 'available', hasActiveDelivery: !!active, freshness }),
      };
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [captains, orders, walletTx, demo, now]);
}

/** How many Captains pass the shared eligibility check now — the same set the assign dialog enables. */
export function useEligibleCaptainCount(): number {
  const captains = useAppStore((s) => s.captains);
  const orders = useAppStore((s) => s.orders);
  const walletTx = useAppStore((s) => s.walletTx);
  const demo = useAppStore((s) => s.demo);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  return useMemo(() => eligibleCaptains(useAppStore.getState()).length, [captains, orders, walletTx, demo]);
}

export const OP_STATUS_LABEL: Record<CaptainView['opStatus'], string> = {
  available: 'متاح',
  busy: 'في توصيل',
  offline: 'غير متاح',
  inactive: 'موقوف',
};

export function useSimulationClock() { useEffect(() => startDemoClock(), []); }
