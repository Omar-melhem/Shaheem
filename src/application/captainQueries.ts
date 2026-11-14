import type { Captain, DeliveryOrder, ID, Money } from '@/domain/types';
import { evaluateEligibility } from '@/domain/eligibility';
import { isActiveDelivery } from '@/domain/orderStatus';
import type { AppData } from '@/application/data';

// Pure reads over AppData, shared by the store, the dispatch rounds and selectors.

export function captainBalance(data: AppData, captainId: ID): Money {
  return data.walletTx.filter((t) => t.captainId === captainId).reduce((sum, t) => sum + t.amount, 0);
}

export function captainActiveOrder(data: AppData, captainId: ID): DeliveryOrder | undefined {
  return data.orders.find((o) => o.captainId === captainId && isActiveDelivery(o.status));
}

export function captainEligibility(data: AppData, captain: Captain) {
  return evaluateEligibility(captain, {
    hasActiveDelivery: !!captainActiveOrder(data, captain.id),
    balance: captainBalance(data, captain.id),
    walletThreshold: data.demo.walletThreshold,
  });
}
