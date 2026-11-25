// Core SHAHM domain entities (SRS §14). Framework-free: no React, no storage.

export type ID = string;

export interface LatLng {
  lat: number;
  lng: number;
}

/** Money is stored in integer minor units (fils; 1 JOD = 1000 fils) — SRS §14.3. */
export type Money = number;

export type AccountStatus = 'active' | 'inactive';

/**
 * Business category (merchant type) — a classification only; it never affects
 * pricing, dispatch or eligibility (FE-CR FR-MER-006). Proposed taxonomy pending
 * Product Owner approval (OPEN-FE-07). Codes are stable; 'retail' predates this list.
 */
export const MERCHANT_CATEGORIES = ['restaurant', 'cafe', 'retail', 'grocery', 'pharmacy', 'bakery', 'other'] as const;
export type MerchantCategory = (typeof MERCHANT_CATEGORIES)[number];
export const isMerchantCategory = (v: unknown): v is MerchantCategory => MERCHANT_CATEGORIES.includes(v as MerchantCategory);

/**
 * Demo login credentials set by Admin. Stored in plain text for the prototype
 * only — production uses a real authentication provider (SRS §13.3).
 */
export interface DemoCredentials {
  username: string;
  password: string;
}

export interface Merchant extends DemoCredentials {
  id: ID;
  businessName: string;
  /** null = legacy record not yet categorised by Admin (shown as "غير مصنّف"). */
  category: MerchantCategory | null;
  phone: string;
  /** Display label. Legacy Merchants have only this (cityId/areaId null) until Admin sets City → Area. */
  address: string;
  cityId: string | null;
  areaId: ID | null;
  /** Exact pickup coordinates chosen on the map, never derived from an Area centroid. */
  pickup: LatLng;
  status: AccountStatus;
  createdAt: number;
}

export type Availability = 'available' | 'offline';

/**
 * Every coordinate in the prototype is simulated. `trip_simulated` stands in for
 * active-delivery GPS; `idle_report` stands in for the Captain app's periodic report while
 * Available with no delivery (owner request: every 60 s — `domain/location.ts`); `demo_idle`
 * is a seeded/presenter-set position that has not been reported yet.
 */
export type LocationSource = 'trip_simulated' | 'demo_idle' | 'idle_report';

export interface CaptainLocation {
  position: LatLng;
  recordedAt: number;
  source: LocationSource;
  activeOrderId?: ID;
}

export interface Captain extends DemoCredentials {
  id: ID;
  fullName: string;
  phone: string;
  status: AccountStatus;
  availability: Availability;
  lastLocation?: CaptainLocation;
  /** Demo-only switch used to simulate GPS loss (SRS §19.7 Scenario D). */
  gpsSignal: 'ok' | 'lost';
  /** Inherited, unconfirmed feature (SRS §4.5, O-033). */
  rating?: number;
  adminNotes?: string;
  createdAt: number;
}

/**
 * Central delivery zone, defined once and reused by every Merchant
 * (Zone-Based Pricing Spec §4). It belongs to a Governorate (FU-1.2 §7); its
 * polygon is how a customer pin is matched to the zone (owner, 2026-11-02).
 */
export interface ServiceArea {
  id: ID;
  /** Governorate code from `GOVERNORATES` (domain/governorates). */
  governorateId: string;
  /** City code from `CITIES` (domain/cities). */
  cityId: string;
  /** Parent area for a sub-area (قسم); null for a top-level area. One level only (CR v1.4 §1.2). */
  parentId: ID | null;
  name: string;
  aliases: string[];
  notes?: string;
  /** Legacy drawn boundary; the catalogue no longer creates or edits these (CR v1.4 §1.1). */
  polygon: LatLng[];
  status: AccountStatus;
  createdAt: number;
  updatedAt: number;
}

/** A Merchant serves this destination (CR v1.4 §2). Coverage alone is not orderable: a price is also required. */
export interface MerchantCoverage {
  merchantId: ID;
  areaId: ID;
  enabledAt: number;
}

export type RequestType = 'immediate' | 'scheduled';

/**
 * Origin area → destination area connection inside one Governorate (FU-1.2 §7.1).
 * A separate record: it does not change the Merchant + destination-zone pricing.
 * Whether routes are availability only or become a pricing key is open (FU-1.2 §14.5).
 */
export interface DeliveryRoute {
  id: ID;
  governorateId: string;
  originAreaId: ID;
  destinationAreaId: ID;
  status: AccountStatus;
  createdAt: number;
}

/** Merchant + zone → fixed full delivery fee. Unique per (merchantId, areaId). */
export interface MerchantAreaPrice {
  id: ID;
  merchantId: ID;
  areaId: ID;
  price: Money;
  status: AccountStatus;
  updatedAt: number;
  updatedBy: string;
}

/** One Admin price-copy operation, with before/after values per Area (CR v1.3 §4.2). */
export interface PricingCopyAudit {
  id: ID;
  sourceMerchantId: ID;
  targetMerchantId: ID;
  mode: 'fill_missing' | 'overwrite';
  changes: Array<{ areaId: ID; previous?: Money; next: Money }>;
  actor: string;
  at: number;
}

export type OrderStatus =
  | 'pending_dispatch'
  | 'awaiting_captain'
  | 'offered_privately'
  | 'accepted'
  | 'heading_to_pickup'
  | 'picked_up'
  | 'on_the_way'
  | 'delivered'
  | 'cancelled'
  | 'dispatch_expired';

export type DispatchMode = 'public' | 'private';

export type ActorRole = 'admin' | 'merchant' | 'captain' | 'system';

export interface ActorRef {
  role: ActorRole;
  id?: ID;
  name: string;
}

/**
 * Customer destination. The required delivery area lives on the order (`areaId`).
 * `position` is the Merchant's optional exact pin, absent for an area-only order;
 * on older demo orders it is a zone centre marked `approximate`.
 */
export interface Destination {
  /** Searched place name or map-pin label. Older orders hold a typed address description here. */
  label: string;
  /** Zone context, e.g. "خلدا، عمّان". */
  address: string;
  position?: LatLng;
  approximate?: boolean;
  note?: string;
}

export interface StatusHistoryEntry {
  from?: OrderStatus;
  to: OrderStatus;
  actor: ActorRef;
  at: number;
  note?: string;
}

export interface DeliveryOrder {
  id: ID;
  reference: string;
  merchantId: ID;
  pickup: { position: LatLng; address: string };
  customerPhone?: string;
  destination: Destination;
  areaId: ID;
  /** Snapshot so later area renames do not rewrite history. */
  areaName: string;
  /**
   * «مجموع الطلب»: the optional goods/basket total the Merchant typed (owner, 2026-11-25). Absent when
   * left blank. Information only: it never feeds the fee, the commission or SHAHM's revenue.
   */
  mealValue?: Money;
  deliveryInstructions?: string;
  /** Missing on older orders = immediate. Scheduled orders are dispatched by Admin only (CR v1.4 §6). */
  requestType?: RequestType;
  /** Requested Captain pickup time at the Merchant (epoch ms), for scheduled orders. */
  scheduledPickupAt?: number;
  /** Fee locked at confirmation time (Pricing Spec §8). */
  deliveryPrice: Money;
  pricingSnapshotAt: number;
  /**
   * Commission rate (basis points) and amount locked when a Captain accepts (owner, 2026-11-25).
   * Later rate changes never touch them. Absent on orders accepted before commission existed:
   * those are never charged.
   */
  commissionBp?: number;
  commissionFils?: Money;
  captainId?: ID;
  dispatchMode?: DispatchMode;
  /** Dispatch cycle counter (each public publish or private assignment starts one). */
  dispatchRound: number;
  /** Public round within the current cycle, 1…MAX_DISPATCH_ROUNDS (0 = not offered yet). */
  dispatchAttempt?: number;
  /** Why the order is sitting in the Admin queue, shown to Admin. */
  queueReason?: string;
  status: OrderStatus;
  createdAt: number;
  updatedAt: number;
  deliveredAt?: number;
  gpsStaleAlerted?: boolean;
  history: StatusHistoryEntry[];
}

export type OfferStatus = 'pending' | 'accepted' | 'rejected' | 'expired' | 'withdrawn';

export interface DispatchOffer {
  id: ID;
  orderId: ID;
  captainId: ID;
  mode: DispatchMode;
  round: number;
  /** Public round number within the cycle (private offers have none). */
  attempt?: number;
  status: OfferStatus;
  offeredAt: number;
  expiresAt: number;
  respondedAt?: number;
  distanceMeters?: number;
  rank?: number;
}

/**
 * Append-only Captain wallet ledger. `recharge` is an Admin credit (> 0); `commission_debit` is
 * SHAHM's commission on one delivered order (< 0). The balance is the signed sum.
 */
export type WalletTxType = 'recharge' | 'commission_debit';

export interface WalletTransaction {
  id: ID;
  captainId: ID;
  type: WalletTxType;
  /** Signed fils: credits positive, debits negative. */
  amount: Money;
  createdAt: number;
  actor: ActorRef;
  /** Older recharges carry a typed reference; new ones have none (owner, 2026-11-25). */
  reason?: string;
  /** The delivered order a commission debit belongs to. */
  orderId?: ID;
  /** Rate snapshot behind a commission debit. */
  commissionBp?: number;
  /** One business operation = one entry: `recharge:{operationId}` or `commission:{orderId}`. */
  idempotencyKey?: string;
}

/** Admin audit trail: financial policy and account-security actions. Never holds a password. */
export type AdminAuditEntry =
  | { id: ID; kind: 'commission_rate'; previousBp: number; nextBp: number; actor: ActorRef; at: number }
  | { id: ID; kind: 'password_reset'; targetRole: 'merchant' | 'captain'; targetId: ID; targetName: string; actor: ActorRef; at: number };

export type SupportChannel = 'phone' | 'whatsapp' | 'email' | 'other';

export interface SupportContact {
  id: ID;
  channel: SupportChannel;
  label: string;
  value: string;
  enabled: boolean;
  order: number;
}

export type AlertKind =
  | 'new_order'
  | 'accepted'
  | 'rejected'
  | 'no_candidate'
  | 'delivered'
  | 'gps_stale'
  | 'broadcast'
  | 'private_returned'
  | 'cancelled';

export interface OpsAlert {
  id: ID;
  kind: AlertKind;
  message: string;
  at: number;
  orderId?: ID;
  read: boolean;
}

/**
 * Presenter-configurable demo assumptions. None of these are approved business
 * rules — each maps to an open SRS decision.
 */
export interface DemoSettings {
  /** O-020: wallet amount a Captain must hold to qualify. */
  walletThreshold: Money;
  /** O-006: seconds a Captain has to respond to a private offer. Public rounds are fixed at 60 s. */
  offerTimeoutSec: number;
  /** Seconds without a GPS update before a trip location is shown as stale. */
  staleAfterSec: number;
  /** Simulated movement speed of a Captain during an active trip. */
  simSpeedMps: number;
}

export interface PlatformSettings {
  publicBroadcast: boolean;
  /** Global commission rate in basis points (2000 = 20%), applied to new acceptances only. */
  commissionBp: number;
}
