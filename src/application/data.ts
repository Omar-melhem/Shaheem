import type {
  ActorRef,
  Captain,
  DeliveryOrder,
  DemoSettings,
  Merchant,
  MerchantAreaPrice,
  OpsAlert,
  PlatformSettings,
  ServiceArea,
  SupportContact,
  WalletTransaction,
  DispatchOffer,
  DeliveryRoute,
  PricingCopyAudit,
  MerchantCoverage,
} from '@/domain/types';
export interface AppData {
  merchants: Merchant[];
  captains: Captain[];
  areas: ServiceArea[];
  routes: DeliveryRoute[];
  prices: MerchantAreaPrice[];
  coverage: MerchantCoverage[];
  pricingAudit: PricingCopyAudit[];
  orders: DeliveryOrder[];
  offers: DispatchOffer[];
  walletTx: WalletTransaction[];
  supportContacts: SupportContact[];
  alerts: OpsAlert[];
  settings: PlatformSettings;
  demo: DemoSettings;
  seq: number;
}

export const ADMIN_ACTOR: ActorRef = { role: 'admin', id: 'admin-demo', name: 'مدير النظام (تجريبي)' };
export const SYSTEM_ACTOR: ActorRef = { role: 'system', name: 'النظام' };

