import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import type {
  ActorRef,
  Captain,
  DeliveryOrder,
  DemoSettings,
  DispatchOffer,
  ID,
  RequestType,
  LatLng,
  Merchant,
  Money,
  OrderStatus,
  ServiceArea,
  SupportContact,
} from '@/domain/types';
import { isMerchantCategory } from '@/domain/types';
import { ADMIN_ACTOR, SYSTEM_ACTOR, createSeedData, type AppData } from '@/infrastructure/seed';
import { describeReasons } from '@/domain/eligibility';
import { isValidLatLng, moveTowards, haversineMeters } from '@/domain/geo';
import { isAutoDispatchEligible } from '@/domain/dispatch';
import { isDestinationActive } from '@/domain/regions';
import { isGovernorateId } from '@/domain/governorates';
import { cityName, isCityInGovernorate } from '@/domain/cities';
import { PHONE_ERROR, isValidOptionalPhone, isValidPhone, normalizePhone } from '@/domain/phone';
import {
  CANCELLABLE_STATUSES,
  CAPTAIN_NEXT_STATUS,
  ORDER_STATUS_LABEL,
  isActiveDelivery,
  isInQueue,
} from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { AREA_REQUIRED, AREA_UNAVAILABLE, PINNED_LOCATION_LABEL, destinationPinError } from '@/domain/destination';
import { resolveZoneFee } from './queries';
import { isUnchangedLegacyLocation, pickupAddressLabel, pickupLocationError } from './merchantLocation';
import { previewPricingCopy, type PricingCopyMode } from './pricingCopy';
import { captainActiveOrder, captainBalance, captainEligibility } from './captainQueries';
import { pushAlert, transition, uid, withdrawPendingOffers } from './orderMutations';
import { afterOfferResolved, startPublicDispatch } from './dispatchRounds';

export { captainActiveOrder, captainBalance, captainEligibility };

// Application layer: use cases operating on shared state. In the prototype this
// stands in for the backend (source of truth); in production each action maps
// to an authenticated API call validated server-side (SRS §13.4).

export interface Failure {
  ok: false;
  error: string;
  /** Machine-readable reason, e.g. 'fee_changed'. */
  code?: string;
  currentFee?: Money;
}
export type Result<T = undefined> = { ok: true; value: T } | Failure;
const ok = <T,>(value: T): Result<T> => ({ ok: true, value });
const done: Result = { ok: true, value: undefined };
const fail = (error: string, extra?: Omit<Failure, 'ok' | 'error'>): Failure => ({ ok: false, error, ...extra });

const captainActor = (c: Captain): ActorRef => ({ role: 'captain', id: c.id, name: c.fullName });
const merchantActor = (m: Merchant): ActorRef => ({ role: 'merchant', id: m.id, name: m.businessName });

// ---------- store ----------

export interface CreateOrderInput {
  /** Optional; when supplied it must be exactly 10 digits (CR v1.3 §8.4). */
  customerPhone?: string;
  /** Required delivery area chosen from the list. The fee comes from Merchant + this area. */
  areaId: ID;
  /** Optional exact customer pin; it must lie inside the area and never affects the fee. */
  location?: LatLng | null;
  /** Name of the searched place, if the pin came from search. */
  placeName?: string;
  /** Immediate (default) is auto-dispatched; scheduled goes to the Admin manual queue only (CR v1.4 §6). */
  requestType?: RequestType;
  /** Required for scheduled requests: Captain pickup time at the Merchant, epoch ms, in the future. */
  scheduledPickupAt?: number;
  /** Fee the Merchant saw; if the current fee differs, creation is refused with code 'fee_changed'. */
  expectedFee?: Money;
}

export interface ZoneInput {
  governorateId: string;
  cityId: string;
  /** Set to create a sub-area (قسم) under a top-level area; it inherits the parent's governorate and city. */
  parentId?: ID | null;
  name: string;
  aliases: string[];
  notes?: string;
}

/** One line per area, or "Area / Sub-area". Names only: no coordinates are invented. */
export interface AreaImportInput {
  governorateId: string;
  cityId: string;
  lines: string;
}

export interface RouteInput {
  governorateId: string;
  originAreaId: ID;
  destinationAreaId: ID;
}

export type Session = { role: 'admin'; id: 'admin' } | { role: 'merchant'; id: ID } | { role: 'captain'; id: ID };

/** The address label is derived from City + Area; it is not typed by Admin. */
export type MerchantInput = Omit<Merchant, 'id' | 'createdAt' | 'status' | 'address'>;
export type CaptainInput = Pick<Captain, 'fullName' | 'phone' | 'username' | 'password'>;

export const DEMO_ADMIN = { username: 'admin', password: 'admin1234' };

const normalizeName = (v: string) =>
  v.trim().toLowerCase().replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي').replace(/\s+/g, ' ');

function usernameTaken(data: AppData, username: string, exceptId?: ID): boolean {
  const u = username.trim().toLowerCase();
  return (
    u === DEMO_ADMIN.username ||
    data.merchants.some((m) => m.id !== exceptId && m.username.toLowerCase() === u) ||
    data.captains.some((c) => c.id !== exceptId && c.username.toLowerCase() === u)
  );
}

function validateCredentials(data: AppData, creds: { username: string; password: string }, exceptId?: ID): string | null {
  if (!/^[a-zA-Z0-9._-]{3,30}$/.test(creds.username.trim())) return 'اسم المستخدم: 3 أحرف إنجليزية أو أرقام على الأقل';
  if (creds.password.length < 6) return 'كلمة المرور: 6 أحرف على الأقل';
  if (usernameTaken(data, creds.username, exceptId)) return 'اسم المستخدم مستخدم لحساب آخر';
  return null;
}

/** An existing zone with the same name/alias, if any (no duplicate zones — Spec §4). */
/** Same name or alias among siblings (same city, same parent). Equal names elsewhere are allowed (CR v1.4 §1.2). */
function duplicateZone(data: AppData, input: ZoneInput, exceptId?: ID): ServiceArea | undefined {
  const names = [input.name, ...input.aliases].map(normalizeName).filter(Boolean);
  const parentId = input.parentId ?? null;
  return data.areas.find(
    (a) => a.id !== exceptId && a.cityId === input.cityId && (a.parentId ?? null) === parentId && [a.name, ...a.aliases].map(normalizeName).some((n) => names.includes(n)),
  );
}

/** Resolves a sub-area's parent and inherits its location; an error string when invalid. */
function zoneParent(data: AppData, input: ZoneInput): { parent: ServiceArea | null } | string {
  if (!input.parentId) return { parent: null };
  const parent = data.areas.find((a) => a.id === input.parentId);
  if (!parent) return 'المنطقة الأم غير موجودة';
  if (parent.parentId) return 'لا يمكن إضافة قسم داخل قسم — اختر منطقة رئيسية';
  return { parent };
}

interface Actions {
  resetDemo: () => void;
  authenticate: (username: string, password: string) => Result<Session>;
  tick: (now: number) => void;

  createMerchant: (input: MerchantInput) => Result<ID>;
  updateMerchant: (id: ID, input: MerchantInput) => Result;
  setMerchantStatus: (id: ID, active: boolean) => Result;

  createCaptain: (input: CaptainInput) => Result<ID>;
  updateCaptain: (id: ID, input: CaptainInput) => Result;
  setCaptainStatus: (id: ID, active: boolean) => Result;
  rateCaptain: (id: ID, rating: number | undefined, notes: string) => Result;

  createZone: (input: ZoneInput) => Result<ID>;
  updateZone: (id: ID, patch: Partial<Omit<ZoneInput, 'parentId'>>) => Result;
  importAreas: (input: AreaImportInput) => Result<{ created: number; skipped: number }>;
  setMerchantCoverage: (merchantId: ID, areaIds: ID[], enabled: boolean) => Result<{ changed: number }>;
  setServiceAreaStatus: (id: ID, active: boolean) => Result;

  createRoute: (input: RouteInput) => Result<ID>;
  removeRoute: (id: ID) => Result;

  setMerchantAreaPrice: (merchantId: ID, areaId: ID, price: Money | null) => Result;
  setMerchantAreaPriceStatus: (merchantId: ID, areaId: ID, active: boolean) => Result;
  copyMerchantPricing: (sourceId: ID, targetId: ID, mode: PricingCopyMode) => Result<{ changed: number }>;

  rechargeWallet: (captainId: ID, amount: Money, reason: string) => Result;

  createOrder: (merchantId: ID, input: CreateOrderInput) => Result<{ id: ID; reference: string }>;
  setPublicBroadcast: (enabled: boolean) => Result;
  dispatchPublic: (orderId: ID) => Result;
  assignPrivate: (orderId: ID, captainId: ID) => Result;
  cancelOrder: (orderId: ID, reason: string) => Result;

  setCaptainAvailability: (captainId: ID, available: boolean) => Result;
  acceptOffer: (offerId: ID, captainId: ID) => Result;
  rejectOffer: (offerId: ID, captainId: ID) => Result;
  advanceDelivery: (orderId: ID, captainId: ID) => Result<OrderStatus>;

  saveSupportContact: (contact: Omit<SupportContact, 'id' | 'order'> & { id?: ID }) => Result;
  removeSupportContact: (id: ID) => void;
  moveSupportContact: (id: ID, direction: -1 | 1) => void;

  markAlertsRead: () => void;

  // Demo-only controls (SRS §19.8)
  updateDemoSettings: (patch: Partial<DemoSettings>) => void;
  setGpsSignal: (captainId: ID, signal: 'ok' | 'lost') => void;
  setCaptainDemoLocation: (captainId: ID, position: LatLng) => Result;
}

export type AppState = AppData & Actions;

// v8: no merchant contact person, no captain vehicle data, no customer name on orders (older saved demo data is discarded).
export const STORAGE_KEY = 'shahm-demo-v8';

export const useAppStore = create<AppState>()(
  persist(
    immer((set, get) => {
      /** Runs a mutation and returns its result (immer draft inside). */
      const run = <T,>(fn: (d: AppData, now: number) => Result<T>): Result<T> => {
        let result: Result<T> = fail('لم يتم تنفيذ العملية');
        set((draft) => {
          result = fn(draft as unknown as AppData, Date.now());
        });
        return result;
      };

      return {
        ...createSeedData(),

        resetDemo: () => set(() => ({ ...createSeedData() })),

        // Demo authentication only — production uses a real identity provider.
        authenticate: (username, password) => {
          const d = get();
          const u = username.trim().toLowerCase();
          if (u === DEMO_ADMIN.username && password === DEMO_ADMIN.password) return ok<Session>({ role: 'admin', id: 'admin' });
          const m = d.merchants.find((x) => x.username.toLowerCase() === u && x.password === password);
          if (m) return ok<Session>({ role: 'merchant', id: m.id });
          const c = d.captains.find((x) => x.username.toLowerCase() === u && x.password === password);
          if (c) return ok<Session>({ role: 'captain', id: c.id });
          return fail('اسم المستخدم أو كلمة المرور غير صحيحة');
        },

        tick: (now) =>
          set((d) => {
            // 1. Expire offers whose response window has passed.
            const expiredOrders = new Set<ID>();
            for (const offer of d.offers) {
              if (offer.status === 'pending' && offer.expiresAt <= now) {
                offer.status = 'expired';
                offer.respondedAt = now;
                expiredOrders.add(offer.orderId);
              }
            }
            expiredOrders.forEach((orderId) => afterOfferResolved(d as AppData, orderId, now, 'expired'));

            // 2. Simulated active-delivery GPS (tracking only during an active delivery — SRS §6.8).
            for (const order of d.orders) {
              if (!isActiveDelivery(order.status) || !order.captainId) continue;
              const captain = d.captains.find((c) => c.id === order.captainId);
              if (!captain?.lastLocation) continue;
              const loc = captain.lastLocation;
              if (captain.gpsSignal === 'lost') {
                const staleMs = d.demo.staleAfterSec * 1000;
                if (!order.gpsStaleAlerted && now - loc.recordedAt > staleMs) {
                  order.gpsStaleAlerted = true;
                  pushAlert(d as AppData, 'gps_stale', `انقطع تحديث موقع الكابتن ${captain.fullName} أثناء الطلب ${order.reference}`, now, order.id);
                }
                continue;
              }
              const target =
                order.status === 'accepted' || order.status === 'heading_to_pickup' ? order.pickup.position : order.destination.position;
              const moving = !!target && (order.status === 'heading_to_pickup' || order.status === 'on_the_way');
              const stepSec = Math.min(5, Math.max(0, (now - loc.recordedAt) / 1000));
              const position = moving ? moveTowards(loc.position, target!, d.demo.simSpeedMps * stepSec) : loc.position;
              const shouldUpdate =
                moving
                  ? haversineMeters(position, loc.position) > 0.5 || now - loc.recordedAt > 5000
                  : now - loc.recordedAt > 5000;
              if (shouldUpdate || loc.activeOrderId !== order.id || loc.source !== 'trip_simulated') {
                captain.lastLocation = { position, recordedAt: now, source: 'trip_simulated', activeOrderId: order.id };
                order.gpsStaleAlerted = false;
              }
            }
          }),

        // ----- Merchants -----
        createMerchant: (input) =>
          run((d, now) => {
            if (!input.businessName.trim()) return fail('اسم النشاط التجاري مطلوب');
            if (!isMerchantCategory(input.category)) return fail('اختر فئة النشاط التجاري');
            if (!isValidPhone(input.phone)) return fail(PHONE_ERROR);
            const locErr = pickupLocationError(d.areas, input);
            if (locErr) return fail(locErr);
            const credErr = validateCredentials(d, input);
            if (credErr) return fail(credErr);
            const id = uid('m');
            d.merchants.push({ ...input, address: pickupAddressLabel(d.areas, undefined, input), phone: normalizePhone(input.phone), id, status: 'active', createdAt: now });
            return ok(id);
          }),
        updateMerchant: (id, input) =>
          run((d) => {
            const m = d.merchants.find((x) => x.id === id);
            if (!m) return fail('التاجر غير موجود');
            if (!input.businessName.trim()) return fail('اسم النشاط التجاري مطلوب');
            if (!isMerchantCategory(input.category)) return fail('اختر فئة النشاط التجاري');
            if (!isValidPhone(input.phone)) return fail(PHONE_ERROR);
            if (!isUnchangedLegacyLocation(m, input)) {
              const locErr = pickupLocationError(d.areas, input);
              if (locErr) return fail(locErr);
            }
            const credErr = validateCredentials(d, input, id);
            if (credErr) return fail(credErr);
            Object.assign(m, { ...input, address: pickupAddressLabel(d.areas, m, input), phone: normalizePhone(input.phone) });
            return done;
          }),
        setMerchantStatus: (id, active) =>
          run((d) => {
            const m = d.merchants.find((x) => x.id === id);
            if (!m) return fail('التاجر غير موجود');
            m.status = active ? 'active' : 'inactive';
            return done;
          }),

        // ----- Captains -----
        createCaptain: (input) =>
          run((d, now) => {
            if (!input.fullName.trim()) return fail('اسم الكابتن مطلوب');
            if (!input.phone.trim()) return fail('رقم هاتف الكابتن مطلوب');
            if (!isValidPhone(input.phone)) return fail(PHONE_ERROR);
            const credErr = validateCredentials(d, input);
            if (credErr) return fail(credErr);
            const id = uid('c');
            d.captains.push({ ...input, phone: normalizePhone(input.phone), id, status: 'active', availability: 'offline', gpsSignal: 'ok', createdAt: now });
            return ok(id);
          }),
        updateCaptain: (id, input) =>
          run((d) => {
            const c = d.captains.find((x) => x.id === id);
            if (!c) return fail('الكابتن غير موجود');
            if (!input.fullName.trim() || !input.phone.trim()) return fail('الاسم ورقم الهاتف مطلوبان');
            if (!isValidPhone(input.phone)) return fail(PHONE_ERROR);
            const credErr = validateCredentials(d, input, id);
            if (credErr) return fail(credErr);
            Object.assign(c, { ...input, phone: normalizePhone(input.phone) });
            return done;
          }),
        setCaptainStatus: (id, active) =>
          run((d, now) => {
            const c = d.captains.find((x) => x.id === id);
            if (!c) return fail('الكابتن غير موجود');
            if (!active && captainActiveOrder(d, id)) return fail('لا يمكن إيقاف كابتن لديه توصيل نشط');
            c.status = active ? 'active' : 'inactive';
            if (!active) {
              c.availability = 'offline';
              const affected = d.offers.filter((o) => o.captainId === id && o.status === 'pending');
              affected.forEach((o) => {
                o.status = 'withdrawn';
                o.respondedAt = now;
              });
              affected.forEach((o) => afterOfferResolved(d, o.orderId, now, 'withdrawn'));
            }
            return done;
          }),
        rateCaptain: (id, rating, notes) =>
          run((d) => {
            const c = d.captains.find((x) => x.id === id);
            if (!c) return fail('الكابتن غير موجود');
            c.rating = rating;
            c.adminNotes = notes.trim() || undefined;
            return done;
          }),

        // ----- Service areas -----
        createZone: (raw) =>
          run((d, now) => {
            const parentCheck = zoneParent(d, raw);
            if (typeof parentCheck === 'string') return fail(parentCheck);
            const { parent } = parentCheck;
            const input = parent ? { ...raw, governorateId: parent.governorateId, cityId: parent.cityId } : raw;
            if (!isGovernorateId(input.governorateId)) return fail('اختر المحافظة أولاً');
            if (!isCityInGovernorate(input.cityId, input.governorateId)) return fail('اختر مدينة تابعة للمحافظة');
            if (!input.name.trim()) return fail(parent ? 'اسم القسم مطلوب' : 'اسم المنطقة مطلوب');
            const aliases = input.aliases.map((a) => a.trim()).filter(Boolean);
            const dup = duplicateZone(d, { ...input, aliases });
            if (dup) return fail(`يوجد ${parent ? 'قسم' : 'منطقة'} بنفس الاسم أو الاسم البديل في نفس المكان: «${dup.name}»`);
            const id = uid('a');
            d.areas.push({ id, governorateId: input.governorateId, cityId: input.cityId, parentId: parent?.id ?? null, name: input.name.trim(), aliases, notes: input.notes?.trim() || undefined, polygon: [], status: 'active', createdAt: now, updatedAt: now });
            return ok(id);
          }),
        updateZone: (id, patch) =>
          run((d, now) => {
            const a = d.areas.find((x) => x.id === id);
            if (!a) return fail('المنطقة غير موجودة');
            if (patch.name !== undefined && !patch.name.trim()) return fail('اسم المنطقة مطلوب');
            if (a.parentId && ((patch.cityId && patch.cityId !== a.cityId) || (patch.governorateId && patch.governorateId !== a.governorateId))) {
              return fail('القسم يتبع مدينة منطقته الأم');
            }
            const nextCity = patch.cityId ?? a.cityId;
            if (nextCity !== a.cityId && d.areas.some((x) => x.parentId === id)) return fail('لا يمكن نقل منطقة لها أقسام إلى مدينة أخرى');
            if (!isCityInGovernorate(nextCity, patch.governorateId ?? a.governorateId)) return fail('اختر مدينة تابعة للمحافظة');
            if (nextCity !== a.cityId && d.merchants.some((m) => m.areaId === id)) return fail('لا يمكن نقل منطقة مرتبطة بمواقع تجار إلى مدينة أخرى');
            if (patch.governorateId !== undefined && !isGovernorateId(patch.governorateId)) return fail('اختر المحافظة');
            if (patch.governorateId && patch.governorateId !== a.governorateId && d.routes.some((r) => r.originAreaId === id || r.destinationAreaId === id)) {
              return fail('لا يمكن نقل منطقة مرتبطة بمسارات توصيل إلى محافظة أخرى — احذف مساراتها أولاً');
            }
            const next: ZoneInput = { governorateId: patch.governorateId ?? a.governorateId, cityId: nextCity, parentId: a.parentId, name: patch.name ?? a.name, aliases: (patch.aliases ?? a.aliases).map((x) => x.trim()).filter(Boolean) };
            const dup = duplicateZone(d, next, id);
            if (dup) return fail(`توجد منطقة بنفس الاسم أو الاسم البديل: «${dup.name}»`);
            a.governorateId = next.governorateId;
            a.cityId = next.cityId;
            a.name = next.name.trim();
            a.aliases = next.aliases;
            if (patch.notes !== undefined) a.notes = patch.notes.trim() || undefined;
            a.updatedAt = now;
            return done;
          }),
        setServiceAreaStatus: (id, active) =>
          run((d, now) => {
            const a = d.areas.find((x) => x.id === id);
            if (!a) return fail('المنطقة غير موجودة');
            a.status = active ? 'active' : 'inactive';
            a.updatedAt = now;
            return done;
          }),

        // Bulk catalogue entry from typed names (CR v1.4 §1.2). Existing names are skipped, never duplicated.
        importAreas: ({ governorateId, cityId, lines }) =>
          run((d, now) => {
            if (!isGovernorateId(governorateId)) return fail('اختر المحافظة أولاً');
            if (!isCityInGovernorate(cityId, governorateId)) return fail('اختر مدينة تابعة للمحافظة');
            const rows = lines.split('\n').map((l) => l.split(/\s*[/›>]\s*/).map((x) => x.trim()).filter(Boolean)).filter((r) => r.length > 0);
            if (rows.length === 0) return fail('اكتب اسم منطقة واحدة على الأقل');
            if (rows.some((r) => r.length > 2)) return fail('مستويان كحد أقصى في السطر: «منطقة» أو «منطقة / قسم»');
            let created = 0;
            let skipped = 0;
            const ensure = (name: string, parentId: ID | null): ID => {
              const existing = duplicateZone(d, { governorateId, cityId, parentId, name, aliases: [] });
              if (existing) { skipped++; return existing.id; }
              const id = uid('a');
              d.areas.push({ id, governorateId, cityId, parentId, name, aliases: [], polygon: [], status: 'active', createdAt: now, updatedAt: now });
              created++;
              return id;
            };
            for (const [areaName, subName] of rows) {
              const areaId = ensure(areaName, null);
              if (subName) ensure(subName, areaId);
            }
            return ok({ created, skipped });
          }),

        // Coverage is separate from price: enabling a destination never invents a fee (CR v1.4 §2).
        setMerchantCoverage: (merchantId, areaIds, enabled) =>
          run((d, now) => {
            if (!d.merchants.some((m) => m.id === merchantId)) return fail('التاجر غير موجود');
            const unique = [...new Set(areaIds)];
            if (unique.some((id) => !d.areas.some((a) => a.id === id))) return fail('منطقة غير موجودة');
            let changed = 0;
            if (enabled) {
              const inactive = unique.filter((id) => !isDestinationActive(d.areas.find((a) => a.id === id)!, d.areas));
              if (inactive.length) return fail('لا يمكن تفعيل منطقة متوقفة للتاجر');
              for (const areaId of unique) {
                if (d.coverage.some((c) => c.merchantId === merchantId && c.areaId === areaId)) continue;
                d.coverage.push({ merchantId, areaId, enabledAt: now });
                changed++;
              }
            } else {
              const before = d.coverage.length;
              d.coverage = d.coverage.filter((c) => !(c.merchantId === merchantId && unique.includes(c.areaId)));
              changed = before - d.coverage.length;
            }
            return ok({ changed });
          }),

        // ----- Delivery routes (origin → destination; availability record only, no pricing effect) -----
        createRoute: (input) =>
          run((d, now) => {
            if (!isGovernorateId(input.governorateId)) return fail('اختر المحافظة أولاً');
            const origin = d.areas.find((a) => a.id === input.originAreaId);
            const destination = d.areas.find((a) => a.id === input.destinationAreaId);
            if (!origin) return fail('اختر منطقة الانطلاق');
            if (!destination) return fail('اختر منطقة الوصول');
            if (origin.governorateId !== input.governorateId || destination.governorateId !== input.governorateId) {
              return fail('المنطقتان يجب أن تكونا ضمن المحافظة المختارة');
            }
            if (origin.id === destination.id) return fail('اختر منطقة وصول مختلفة عن منطقة الانطلاق');
            if (d.routes.some((r) => r.originAreaId === origin.id && r.destinationAreaId === destination.id)) {
              return fail(`المسار من «${origin.name}» إلى «${destination.name}» موجود مسبقاً`);
            }
            const id = uid('rt');
            d.routes.push({ id, governorateId: input.governorateId, originAreaId: origin.id, destinationAreaId: destination.id, status: 'active', createdAt: now });
            return ok(id);
          }),
        removeRoute: (id) =>
          run((d) => {
            const i = d.routes.findIndex((r) => r.id === id);
            if (i < 0) return fail('المسار غير موجود');
            d.routes.splice(i, 1);
            return done;
          }),

        // ----- Pricing -----
        setMerchantAreaPrice: (merchantId, areaId, price) =>
          run((d, now) => {
            const idx = d.prices.findIndex((p) => p.merchantId === merchantId && p.areaId === areaId);
            if (price === null) {
              if (idx >= 0) d.prices.splice(idx, 1);
              return done;
            }
            // Zero (free delivery) is not an approved business case (Spec §5).
            if (!Number.isInteger(price) || price <= 0) return fail('أدخل رسوم توصيل صالحة أكبر من صفر');
            if (!d.merchants.some((m) => m.id === merchantId)) return fail('التاجر غير موجود');
            if (!d.areas.some((a) => a.id === areaId)) return fail('المنطقة غير موجودة');
            if (idx >= 0) {
              Object.assign(d.prices[idx], { price, updatedAt: now, updatedBy: ADMIN_ACTOR.name });
            } else {
              d.prices.push({ id: uid('pr'), merchantId, areaId, price, status: 'active', updatedAt: now, updatedBy: ADMIN_ACTOR.name });
            }
            return done;
          }),
        setMerchantAreaPriceStatus: (merchantId, areaId, active) =>
          run((d, now) => {
            const p = d.prices.find((x) => x.merchantId === merchantId && x.areaId === areaId);
            if (!p) return fail('لا يوجد سعر لهذه المنطقة');
            if (active && !(p.price > 0)) return fail('لا يمكن تفعيل منطقة بدون رسوم توصيل صالحة');
            p.status = active ? 'active' : 'inactive';
            p.updatedAt = now;
            p.updatedBy = ADMIN_ACTOR.name;
            return done;
          }),

        // Applied in one store update: all rows change together or none do. Re-running changes nothing new.
        copyMerchantPricing: (sourceId, targetId, mode) =>
          run((d, now) => {
            if (sourceId === targetId) return fail('لا يمكن نسخ تسعيرة المتجر إلى نفسه');
            if (!d.merchants.some((m) => m.id === sourceId) || !d.merchants.some((m) => m.id === targetId)) return fail('التاجر غير موجود');
            const preview = previewPricingCopy(d, sourceId, targetId, mode);
            const rows = preview.rows.filter((r) => r.action === 'add' || r.action === 'update');
            if (rows.some((r) => !Number.isInteger(r.sourcePrice) || r.sourcePrice <= 0)) return fail('توجد رسوم غير صالحة لدى المتجر المصدر');
            if (rows.length === 0) return ok({ changed: 0 });
            for (const r of rows) {
              const existing = d.prices.find((p) => p.merchantId === targetId && p.areaId === r.areaId);
              if (existing) Object.assign(existing, { price: r.sourcePrice, updatedAt: now, updatedBy: ADMIN_ACTOR.name });
              else d.prices.push({ id: uid('pr'), merchantId: targetId, areaId: r.areaId, price: r.sourcePrice, status: 'active', updatedAt: now, updatedBy: ADMIN_ACTOR.name });
            }
            d.pricingAudit.unshift({
              id: uid('pa'),
              sourceMerchantId: sourceId,
              targetMerchantId: targetId,
              mode,
              changes: rows.map((r) => ({ areaId: r.areaId, previous: r.targetPrice, next: r.sourcePrice })),
              actor: ADMIN_ACTOR.name,
              at: now,
            });
            return ok({ changed: rows.length });
          }),

        // ----- Wallet (Admin only; recharge is simulated — SRS §4.10) -----
        rechargeWallet: (captainId, amount, reason) =>
          run((d, now) => {
            const c = d.captains.find((x) => x.id === captainId);
            if (!c) return fail('الكابتن غير موجود');
            if (!Number.isInteger(amount) || amount <= 0) return fail('أدخل مبلغاً موجباً');
            if (amount > 500_000) return fail('المبلغ يتجاوز الحد التجريبي (500 د.أ)');
            d.walletTx.unshift({
              id: uid('tx'),
              captainId,
              type: 'recharge',
              amount,
              createdAt: now,
              actor: ADMIN_ACTOR,
              reason: reason.trim() || 'شحن رصيد (محاكاة)',
            });
            return done;
          }),

        // ----- Orders & dispatch -----
        createOrder: (merchantId, input) =>
          run((d, now) => {
            const m = d.merchants.find((x) => x.id === merchantId);
            if (!m) return fail('حساب التاجر غير موجود');
            if (m.status !== 'active') return fail('حساب التاجر غير مفعّل — تواصل مع إدارة شهم');
            if (!isValidOptionalPhone(input.customerPhone)) return fail(PHONE_ERROR);
            const requestType: RequestType = input.requestType ?? 'immediate';
            if (requestType === 'scheduled') {
              const at = input.scheduledPickupAt;
              if (at === undefined || !Number.isFinite(at)) return fail('حدّد تاريخ ووقت وصول الكابتن إلى المتجر', { code: 'no_schedule' });
              if (at <= now) return fail('وقت الاستلام المطلوب يجب أن يكون في المستقبل', { code: 'schedule_past' });
            }
            if (!input.areaId) return fail(AREA_REQUIRED, { code: 'no_area' });
            // Read the current fee for Merchant + chosen area at confirmation (Spec §8, §10).
            const resolution = resolveZoneFee(d, merchantId, input.areaId);
            if (resolution.kind !== 'ok') return fail(AREA_UNAVAILABLE, { code: resolution.kind });
            const pin = input.location ?? undefined;
            if (pin) {
              if (!isValidLatLng(pin)) return fail('الموقع الدقيق غير صالح. حرّك الدبوس أو أزله.', { code: 'invalid_pin' });
              const pinError = destinationPinError(resolution.area, pin);
              if (pinError) return fail(pinError, { code: 'pin_outside_area' });
            }
            if (input.expectedFee !== undefined && input.expectedFee !== resolution.price) {
              return fail(`تغيّرت رسوم التوصيل لهذه المنطقة إلى ${formatMoney(resolution.price)}. راجع الرسوم الجديدة وأكّد مرة أخرى.`, {
                code: 'fee_changed',
                currentFee: resolution.price,
              });
            }
            const reference = `SH-${++d.seq}`;
            const zone = resolution.area;
            const order: DeliveryOrder = {
              id: uid('o'),
              reference,
              merchantId,
              pickup: { position: m.pickup, address: m.address },
              customerPhone: input.customerPhone?.trim() ? normalizePhone(input.customerPhone) : undefined,
              destination: {
                label: pin ? input.placeName?.trim() || PINNED_LOCATION_LABEL : `منطقة ${zone.name}`,
                address: `${zone.name}، ${cityName(zone.cityId)}`,
                position: pin,
              },
              areaId: zone.id,
              areaName: zone.name,
              requestType,
              scheduledPickupAt: requestType === 'scheduled' ? input.scheduledPickupAt : undefined,
              queueReason: requestType === 'scheduled' ? 'طلب مؤجل — بانتظار تنسيق الإدارة' : undefined,
              deliveryPrice: resolution.price,
              pricingSnapshotAt: now,
              dispatchRound: 0,
              status: 'pending_dispatch',
              createdAt: now,
              updatedAt: now,
              history: [{ to: 'pending_dispatch', actor: merchantActor(m), at: now, note: requestType === 'scheduled' ? 'تم إنشاء طلب مؤجل — يُسند يدوياً من الإدارة' : 'تم إنشاء الطلب' }],
            };
            d.orders.unshift(order);
            pushAlert(d, 'new_order', `${requestType === 'scheduled' ? 'طلب مؤجل' : 'طلب جديد'} ${reference} من ${m.businessName} — ${zone.name}`, now, order.id);
            const draftOrder = d.orders[0];
            if (d.settings.publicBroadcast && isAutoDispatchEligible(draftOrder)) startPublicDispatch(d, draftOrder, SYSTEM_ACTOR, now);
            return ok({ id: order.id, reference });
          }),

        setPublicBroadcast: (enabled) =>
          run((d, now) => {
            if (d.settings.publicBroadcast === enabled) return done;
            d.settings.publicBroadcast = enabled;
            if (!enabled) {
              // Demo behaviour for outstanding public offers (O-032 open): withdraw and return to queue.
              for (const order of d.orders) {
                if (order.status !== 'awaiting_captain') continue;
                withdrawPendingOffers(d, order.id, now);
                order.queueReason = 'أُوقف البث العام';
                transition(order, 'pending_dispatch', ADMIN_ACTOR, now, 'أُوقف البث العام — سُحبت العروض وأُعيد الطلب إلى الطابور');
              }
            }
            pushAlert(d, 'broadcast', enabled ? 'تم تفعيل البث العام للطلبات' : 'تم إيقاف البث العام — الطلبات الجديدة تبقى في طابور الإدارة', now);
            return done;
          }),

        dispatchPublic: (orderId) =>
          run((d, now) => {
            if (!d.settings.publicBroadcast) return fail('البث العام متوقف — فعّله أولاً أو استخدم الإسناد الخاص');
            const order = d.orders.find((o) => o.id === orderId);
            if (!order) return fail('الطلب غير موجود');
            if (!isInQueue(order.status)) return fail(`لا يمكن نشر طلب حالته "${ORDER_STATUS_LABEL[order.status]}"`);
            if (!isAutoDispatchEligible(order)) return fail('الطلب المؤجل يُسند يدوياً فقط — استخدم الإسناد الخاص');
            startPublicDispatch(d, order, ADMIN_ACTOR, now);
            return done;
          }),

        assignPrivate: (orderId, captainId) =>
          run((d, now) => {
            const order = d.orders.find((o) => o.id === orderId);
            const captain = d.captains.find((c) => c.id === captainId);
            if (!order || !captain) return fail('الطلب أو الكابتن غير موجود');
            if (!isInQueue(order.status)) return fail(`لا يمكن إسناد طلب حالته "${ORDER_STATUS_LABEL[order.status]}"`);
            const elig = captainEligibility(d, captain);
            if (!elig.eligible) return fail(`الكابتن غير مؤهل: ${describeReasons(elig.reasons, d.demo.walletThreshold)}`);
            order.dispatchRound += 1;
            order.dispatchMode = 'private';
            order.queueReason = undefined;
            const distanceMeters = captain.lastLocation ? haversineMeters(captain.lastLocation.position, order.pickup.position) : undefined;
            d.offers.push({
              id: uid('of'),
              orderId,
              captainId,
              mode: 'private',
              round: order.dispatchRound,
              status: 'pending',
              offeredAt: now,
              expiresAt: now + d.demo.offerTimeoutSec * 1000,
              distanceMeters,
            });
            transition(order, 'offered_privately', ADMIN_ACTOR, now, `عرض خاص للكابتن ${captain.fullName}`);
            return done;
          }),

        cancelOrder: (orderId, reason) =>
          run((d, now) => {
            const order = d.orders.find((o) => o.id === orderId);
            if (!order) return fail('الطلب غير موجود');
            if (!CANCELLABLE_STATUSES.includes(order.status)) return fail('الإلغاء متاح قبل قبول الكابتن فقط في هذا النموذج');
            withdrawPendingOffers(d, orderId, now);
            transition(order, 'cancelled', ADMIN_ACTOR, now, reason.trim() || 'إلغاء من الإدارة');
            pushAlert(d, 'cancelled', `تم إلغاء الطلب ${order.reference}`, now, orderId);
            return done;
          }),

        // ----- Captain actions -----
        setCaptainAvailability: (captainId, available) =>
          run((d, now) => {
            const c = d.captains.find((x) => x.id === captainId);
            if (!c) return fail('الكابتن غير موجود');
            if (available && c.status !== 'active') return fail('الحساب غير مفعّل — تواصل مع إدارة شهم');
            if (!available && captainActiveOrder(d, captainId)) return fail('أكمل التوصيل الحالي قبل التحول إلى غير متاح');
            c.availability = available ? 'available' : 'offline';
            if (!available) {
              const affected = d.offers.filter((o) => o.captainId === captainId && o.status === 'pending');
              affected.forEach((o) => {
                o.status = 'withdrawn';
                o.respondedAt = now;
              });
              affected.forEach((o) => afterOfferResolved(d, o.orderId, now, 'withdrawn'));
            }
            return done;
          }),

        acceptOffer: (offerId, captainId) =>
          run((d, now) => {
            const offer = d.offers.find((o) => o.id === offerId);
            if (!offer || offer.captainId !== captainId) return fail('العرض غير متاح لهذا الكابتن');
            if (offer.status !== 'pending') return fail('لم يعد هذا العرض متاحاً');
            if (offer.expiresAt <= now) return fail('انتهت مهلة العرض');
            const order = d.orders.find((o) => o.id === offer.orderId);
            const captain = d.captains.find((c) => c.id === captainId);
            if (!order || !captain) return fail('الطلب غير موجود');
            // Concurrency guard: only one Captain can acquire the order. In production
            // this must be a server-side transaction (SRS §8.6).
            if (order.captainId || (order.status !== 'awaiting_captain' && order.status !== 'offered_privately')) {
              return fail('تم إسناد هذا الطلب لكابتن آخر');
            }
            const elig = captainEligibility(d, captain);
            if (!elig.eligible) return fail(`لا يمكن القبول: ${describeReasons(elig.reasons, d.demo.walletThreshold)}`);
            offer.status = 'accepted';
            offer.respondedAt = now;
            withdrawPendingOffers(d, order.id, now, offer.id);
            order.captainId = captainId;
            transition(order, 'accepted', captainActor(captain), now);
            // Trip-start event for tracking is open; the demo starts at acceptance.
            if (captain.lastLocation) {
              captain.lastLocation = { ...captain.lastLocation, recordedAt: now, source: 'trip_simulated', activeOrderId: order.id };
            }
            pushAlert(d, 'accepted', `الكابتن ${captain.fullName} قبل الطلب ${order.reference}`, now, order.id);
            return done;
          }),

        rejectOffer: (offerId, captainId) =>
          run((d, now) => {
            const offer = d.offers.find((o) => o.id === offerId);
            if (!offer || offer.captainId !== captainId) return fail('العرض غير متاح لهذا الكابتن');
            if (offer.status !== 'pending') return fail('لم يعد هذا العرض متاحاً');
            offer.status = 'rejected';
            offer.respondedAt = now;
            const order = d.orders.find((o) => o.id === offer.orderId);
            const captain = d.captains.find((c) => c.id === captainId);
            if (order && offer.mode === 'public') {
              order.history.push({ from: order.status, to: order.status, actor: captainActor(captain!), at: now, note: 'رفض الكابتن العرض' });
            }
            afterOfferResolved(d, offer.orderId, now, 'rejected');
            return done;
          }),

        advanceDelivery: (orderId, captainId) =>
          run((d, now) => {
            const order = d.orders.find((o) => o.id === orderId);
            const captain = d.captains.find((c) => c.id === captainId);
            if (!order || !captain) return fail('الطلب غير موجود');
            if (order.captainId !== captainId) return fail('هذا الطلب غير مسند إليك');
            if (order.status === 'delivered') return fail('تم تأكيد التسليم مسبقاً');
            const next = CAPTAIN_NEXT_STATUS[order.status];
            if (!next) return fail(`لا يمكن تحديث طلب حالته "${ORDER_STATUS_LABEL[order.status]}"`);
            transition(order, next, captainActor(captain), now);
            if (next === 'delivered') {
              order.deliveredAt = now;
              // Tracking ends: the position becomes a last-known location.
              if (captain.lastLocation) captain.lastLocation = { ...captain.lastLocation, activeOrderId: undefined, recordedAt: now };
              pushAlert(d, 'delivered', `تم تسليم الطلب ${order.reference} بواسطة ${captain.fullName}`, now, order.id);
            }
            return ok(next);
          }),

        // ----- Support contacts -----
        saveSupportContact: (contact) =>
          run((d) => {
            if (!contact.label.trim() || !contact.value.trim()) return fail('العنوان وبيانات التواصل مطلوبة');
            if (contact.channel === 'phone' && !isValidPhone(contact.value)) return fail(PHONE_ERROR);
            if (contact.channel === 'phone') contact = { ...contact, value: normalizePhone(contact.value) };
            if (contact.id) {
              const existing = d.supportContacts.find((c) => c.id === contact.id);
              if (!existing) return fail('جهة التواصل غير موجودة');
              Object.assign(existing, { ...contact, label: contact.label.trim(), value: contact.value.trim() });
            } else {
              const order = d.supportContacts.reduce((m, c) => Math.max(m, c.order), 0) + 1;
              d.supportContacts.push({ ...contact, id: uid('sc'), order, label: contact.label.trim(), value: contact.value.trim() });
            }
            return done;
          }),
        removeSupportContact: (id) =>
          set((d) => {
            d.supportContacts = d.supportContacts.filter((c) => c.id !== id);
          }),
        moveSupportContact: (id, direction) =>
          set((d) => {
            const sorted = [...d.supportContacts].sort((a, b) => a.order - b.order);
            const i = sorted.findIndex((c) => c.id === id);
            const j = i + direction;
            if (i < 0 || j < 0 || j >= sorted.length) return;
            const a = d.supportContacts.find((c) => c.id === sorted[i].id)!;
            const b = d.supportContacts.find((c) => c.id === sorted[j].id)!;
            [a.order, b.order] = [b.order, a.order];
          }),

        markAlertsRead: () =>
          set((d) => {
            d.alerts.forEach((a) => (a.read = true));
          }),

        // ----- Demo controls -----
        updateDemoSettings: (patch) =>
          set((d) => {
            Object.assign(d.demo, patch);
          }),
        setGpsSignal: (captainId, signal) =>
          set((d) => {
            const c = d.captains.find((x) => x.id === captainId);
            if (c) c.gpsSignal = signal;
          }),
        setCaptainDemoLocation: (captainId, position) =>
          run((d, now) => {
            const c = d.captains.find((x) => x.id === captainId);
            if (!c) return fail('الكابتن غير موجود');
            if (captainActiveOrder(d, captainId)) return fail('لا يمكن نقل كابتن أثناء توصيل نشط — موقعه يُحدَّث بالتتبع');
            c.lastLocation = { position, recordedAt: now, source: 'demo_idle' };
            return done;
          }),
      };
    }),
    {
      name: STORAGE_KEY,
      version: 1,
      storage: createJSONStorage(() => localStorage),
      partialize: (s) => {
        const { merchants, captains, areas, routes, prices, coverage, pricingAudit, orders, offers, walletTx, supportContacts, alerts, settings, demo, seq } = s;
        return { merchants, captains, areas, routes, prices, coverage, pricingAudit, orders, offers, walletTx, supportContacts, alerts, settings, demo, seq };
      },
    },
  ),
);

/** Same-browser tab sync: rehydrate when another tab writes (single-browser demo only). */
export function enableCrossTabSync() {
  const handler = (e: StorageEvent) => {
    if (e.key === STORAGE_KEY) void useAppStore.persist.rehydrate();
  };
  window.addEventListener('storage', handler);
  return () => window.removeEventListener('storage', handler);
}

export const getAppData = (): AppData => useAppStore.getState();

export type { AppData, ServiceArea, DispatchOffer };
export { formatMoney };
