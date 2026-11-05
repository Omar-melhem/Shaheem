import type {
  ActorRef,
  Captain,
  DeliveryOrder,
  DemoSettings,
  LatLng,
  Merchant,
  MerchantAreaPrice,
  OpsAlert,
  OrderStatus,
  PlatformSettings,
  ServiceArea,
  StatusHistoryEntry,
  SupportContact,
  WalletTransaction,
  DispatchOffer,
  DeliveryRoute,
  PricingCopyAudit,
} from '@/domain/types';
import { MAX_DISPATCH_ROUNDS, ROUNDS_EXHAUSTED_REASON } from '@/domain/dispatch';
import { haversineMeters, polygonCentroid } from '@/domain/geo';
import { jodToFils } from '@/domain/money';

// Fictional demo fixtures for Amman (SRS §19.6). Names, phones and prices are
// illustrative only — not real business data or approved prices.

export interface AppData {
  merchants: Merchant[];
  captains: Captain[];
  areas: ServiceArea[];
  routes: DeliveryRoute[];
  prices: MerchantAreaPrice[];
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

export const DEFAULT_DEMO_SETTINGS: DemoSettings = {
  walletThreshold: jodToFils(2),
  offerPolicy: 'group',
  groupSize: 3,
  offerTimeoutSec: 60,
  staleAfterSec: 20,
  simSpeedMps: 60,
};

const rect = (latMin: number, latMax: number, lngMin: number, lngMax: number): LatLng[] => [
  { lat: latMin, lng: lngMin },
  { lat: latMin, lng: lngMax },
  { lat: latMax, lng: lngMax },
  { lat: latMax, lng: lngMin },
];

const MIN = 60_000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

export function createSeedData(now: number = Date.now()): AppData {
  const areas: ServiceArea[] = [
    { id: 'a-jubaiha', name: 'الجبيهة', aliases: ['Jubeiha', 'الجبيهه'], polygon: rect(32.01, 32.04, 35.85, 35.89) },
    { id: 'a-tla', name: 'تلاع العلي', aliases: ["Tla' Al-Ali", 'تلاع'], polygon: rect(31.985, 32.01, 35.845, 35.88) },
    { id: 'a-khalda', name: 'خلدا', aliases: ['Khalda'], polygon: rect(31.972, 32.01, 35.815, 35.845) },
    { id: 'a-uthaina', name: 'أم أذينة', aliases: ['Um Uthaina', 'ام اذينه'], polygon: rect(31.968, 31.985, 35.845, 35.88) },
    { id: 'a-sweifieh', name: 'الصويفية', aliases: ['Sweifieh', 'الصويفيه'], polygon: rect(31.948, 31.968, 35.845, 35.87) },
    { id: 'a-shmeisani', name: 'الشميساني', aliases: ['Shmeisani'], polygon: rect(31.96, 31.98, 35.89, 35.915) },
    { id: 'a-abdoun', name: 'عبدون', aliases: ['Abdoun'], polygon: rect(31.935, 31.952, 35.87, 35.9) },
  ].map((a) => ({ ...a, governorateId: 'amman', cityId: 'amman', status: 'active' as const, createdAt: now - 30 * DAY, updatedAt: now - 30 * DAY }));

  const merchantDefs: Array<Omit<Merchant, 'status' | 'createdAt' | 'username' | 'password'> & { status?: Merchant['status'] }> = [
    { id: 'm-sanabel', cityId: 'amman', areaId: 'a-jubaiha', businessName: 'مطعم السنابل', category: 'restaurant', contactName: 'رامي حدّاد', phone: '0790000201', address: 'الجبيهة، قرب دوار المنهل', pickup: { lat: 32.02, lng: 35.86 } },
    { id: 'm-hail', cityId: 'amman', areaId: 'a-khalda', businessName: 'مقهى الهيل', category: 'cafe', contactName: 'دانا السعدي', phone: '0790000202', address: 'خلدا، شارع عامر بن مالك', pickup: { lat: 31.996, lng: 35.828 } },
    { id: 'm-taboon', cityId: 'amman', areaId: 'a-tla', businessName: 'مخبز الطابون', category: 'bakery', contactName: 'باسل قاسم', phone: '0790000203', address: 'تلاع العلي، قرب دوار الواحة', pickup: { lat: 31.998, lng: 35.855 } },
    // Deliberately legacy: no category and a text-only address, awaiting Admin classification (FR-MER-005, CR v1.3 §3.2).
    { id: 'm-yasmine', cityId: null, areaId: null, businessName: 'حلويات الياسمين', category: null, contactName: 'هالة نصّار', phone: '0790000204', address: 'الصويفية، شارع الوكالات', pickup: { lat: 31.956, lng: 35.862 } },
    { id: 'm-zahra', cityId: 'amman', areaId: 'a-shmeisani', businessName: 'متجر زهرة البلد', category: 'retail', contactName: 'سليم عوّاد', phone: '0790000205', address: 'الشميساني، شارع الثقافة', pickup: { lat: 31.968, lng: 35.902 } },
    { id: 'm-rayhan', cityId: 'amman', areaId: 'a-abdoun', businessName: 'صيدلية الريحان', category: 'pharmacy', contactName: 'نور الكردي', phone: '0790000206', address: 'عبدون، قرب جسر عبدون', pickup: { lat: 31.944, lng: 35.88 }, status: 'inactive' },
  ];
  const merchants: Merchant[] = merchantDefs.map((m, i) => ({
    ...m,
    status: m.status ?? 'active',
    createdAt: now - (40 - i) * DAY,
    username: `merchant${i + 1}`,
    password: 'demo1234',
  }));

  const captainDefs: Array<Omit<Captain, 'createdAt' | 'gpsSignal' | 'lastLocation' | 'username' | 'password'> & { at?: LatLng }> = [
    { id: 'c-ahmad', fullName: 'أحمد العمري', phone: '0790000101', vehicleType: 'motorcycle', vehicleDescription: 'دراجة نارية — أحمر', status: 'active', availability: 'available', rating: 5, at: { lat: 32.018, lng: 35.865 } },
    { id: 'c-mohammad', fullName: 'محمد الخطيب', phone: '0790000102', vehicleType: 'motorcycle', vehicleDescription: 'دراجة نارية — أسود', status: 'active', availability: 'available', rating: 4, at: { lat: 31.993, lng: 35.835 } },
    { id: 'c-yazan', fullName: 'يزن الحسن', phone: '0790000103', vehicleType: 'car', vehicleDescription: 'سيارة صغيرة — أبيض', status: 'active', availability: 'available', at: { lat: 32.0, lng: 35.858 } },
    { id: 'c-omar', fullName: 'عمر الزعبي', phone: '0790000104', vehicleType: 'motorcycle', vehicleDescription: 'دراجة نارية — أزرق', status: 'active', availability: 'available', rating: 4, at: { lat: 31.958, lng: 35.858 } },
    { id: 'c-khaled', fullName: 'خالد النسور', phone: '0790000105', vehicleType: 'motorcycle', vehicleDescription: 'دراجة نارية — رمادي', status: 'active', availability: 'offline', at: { lat: 31.972, lng: 35.9 } },
    { id: 'c-samer', fullName: 'سامر الربضي', phone: '0790000106', vehicleType: 'car', vehicleDescription: 'سيارة — فضي', status: 'active', availability: 'available', rating: 5, at: { lat: 31.975, lng: 35.866 } },
    { id: 'c-firas', fullName: 'فراس المومني', phone: '0790000107', vehicleType: 'motorcycle', vehicleDescription: 'دراجة نارية — أحمر', status: 'active', availability: 'available', at: { lat: 31.945, lng: 35.884 } },
    { id: 'c-laith', fullName: 'ليث العبادي', phone: '0790000108', vehicleType: 'bicycle', vehicleDescription: 'دراجة هوائية', status: 'inactive', availability: 'offline' },
  ];
  const captains: Captain[] = captainDefs.map(({ at, ...c }, i) => ({
    ...c,
    gpsSignal: 'ok',
    username: `captain${i + 1}`,
    password: 'demo1234',
    createdAt: now - (35 - i) * DAY,
    lastLocation: at ? { position: at, recordedAt: now - 10 * MIN, source: 'demo_idle' } : undefined,
  }));

  // Merchant-specific prices: roughly by distance, with some areas left unpriced on purpose.
  const unpriced = new Set(['m-sanabel|a-abdoun', 'm-hail|a-shmeisani', 'm-taboon|a-abdoun', 'm-zahra|a-khalda']);
  const prices: MerchantAreaPrice[] = [];
  for (const m of merchants) {
    for (const a of areas) {
      if (unpriced.has(`${m.id}|${a.id}`)) continue;
      const km = haversineMeters(m.pickup, polygonCentroid(a.polygon)) / 1000;
      const jod = Math.min(4, 1.25 + Math.round(km / 2) * 0.25);
      prices.push({ id: `pr-${m.id}-${a.id}`, merchantId: m.id, areaId: a.id, price: jodToFils(jod), status: 'active', updatedAt: now - 20 * DAY, updatedBy: ADMIN_ACTOR.name });
    }
  }

  const walletTx: WalletTransaction[] = [];
  const recharge = (captainId: string, jod: number, daysAgo: number, reason = 'شحن رصيد تجريبي') =>
    walletTx.push({ id: `tx-${walletTx.length + 1}`, captainId, type: 'recharge', amount: jodToFils(jod), createdAt: now - daysAgo * DAY, actor: ADMIN_ACTOR, reason });
  recharge('c-ahmad', 5, 12);
  recharge('c-ahmad', 5, 3);
  recharge('c-mohammad', 5, 6);
  recharge('c-omar', 1, 4);
  recharge('c-khaled', 10, 8);
  recharge('c-samer', 8, 2);
  recharge('c-firas', 3, 9);
  recharge('c-firas', 3, 1);
  recharge('c-laith', 3, 20);

  const priceOf = (merchantId: string, areaId: string) => prices.find((p) => p.merchantId === merchantId && p.areaId === areaId)?.price ?? jodToFils(2);
  const areaName = (areaId: string) => areas.find((a) => a.id === areaId)!.name;
  const merchantActor = (m: Merchant): ActorRef => ({ role: 'merchant', id: m.id, name: m.businessName });
  const captainActor = (id: string): ActorRef => ({ role: 'captain', id, name: captains.find((c) => c.id === id)!.fullName });

  interface OrderDef {
    merchant: string;
    area: string;
    dest: { label: string; address: string };
    customerName?: string;
    customerPhone?: string;
    mealJod?: number;
    captain?: string;
    status: OrderStatus;
    ageMin: number;
  }

  // Address descriptions as a merchant would type them — no customer GPS (Pricing Spec §7).
  const D = {
    khaled: { label: 'بجانب سوبرماركت الخالد، عمارة 12، الطابق الثاني', address: 'الجبيهة، عمّان' },
    uj: { label: 'مقابل البوابة الرئيسية للجامعة الأردنية', address: 'الجبيهة، عمّان' },
    waha: { label: 'قرب دوار الواحة، خلف البنك، عمارة 4', address: 'تلاع العلي، عمّان' },
    city: { label: 'خلف سيتي مول، شارع المعارض', address: 'خلدا، عمّان' },
    wakalat: { label: 'شارع الوكالات، فوق محل الأحذية', address: 'الصويفية، عمّان' },
    taj: { label: 'بجانب تاج مول، فيلا رقم 7', address: 'عبدون، عمّان' },
    uthaina: { label: 'قرب دوار أم أذينة، عمارة السلام، شقة 3', address: 'أم أذينة، عمّان' },
    thaqafa: { label: 'شارع الثقافة، مجمع النور التجاري', address: 'الشميساني، عمّان' },
  };

  const defs: OrderDef[] = [
    { merchant: 'm-sanabel', area: 'a-jubaiha', dest: D.khaled, customerName: 'لينا', mealJod: 12.5, captain: 'c-ahmad', status: 'delivered', ageMin: 6 * DAY / MIN },
    { merchant: 'm-hail', area: 'a-khalda', dest: D.city, captain: 'c-mohammad', status: 'delivered', ageMin: 5 * DAY / MIN },
    { merchant: 'm-taboon', area: 'a-tla', dest: D.waha, customerName: 'سعيد', customerPhone: '0790000301', captain: 'c-samer', status: 'delivered', ageMin: 5 * DAY / MIN + 120 },
    { merchant: 'm-yasmine', area: 'a-sweifieh', dest: D.wakalat, mealJod: 18, captain: 'c-firas', status: 'delivered', ageMin: 4 * DAY / MIN },
    { merchant: 'm-zahra', area: 'a-shmeisani', dest: D.thaqafa, captain: 'c-khaled', status: 'delivered', ageMin: 3 * DAY / MIN },
    { merchant: 'm-sanabel', area: 'a-tla', dest: D.waha, customerPhone: '0790000302', captain: 'c-ahmad', status: 'delivered', ageMin: 2 * DAY / MIN },
    { merchant: 'm-hail', area: 'a-uthaina', dest: D.uthaina, customerName: 'ريم', captain: 'c-samer', status: 'delivered', ageMin: 1 * DAY / MIN + 300 },
    { merchant: 'm-taboon', area: 'a-jubaiha', dest: D.uj, captain: 'c-mohammad', status: 'delivered', ageMin: 1 * DAY / MIN },
    { merchant: 'm-yasmine', area: 'a-abdoun', dest: D.taj, customerName: 'مها', mealJod: 25, captain: 'c-firas', status: 'delivered', ageMin: 300 },
    { merchant: 'm-sanabel', area: 'a-jubaiha', dest: D.uj, customerName: 'طارق', captain: 'c-ahmad', status: 'delivered', ageMin: 140 },
    { merchant: 'm-zahra', area: 'a-sweifieh', dest: D.wakalat, status: 'cancelled', ageMin: 2 * DAY / MIN },
    { merchant: 'm-hail', area: 'a-tla', dest: D.waha, status: 'dispatch_expired', ageMin: 35 },
    { merchant: 'm-taboon', area: 'a-uthaina', dest: D.uthaina, customerName: 'جود', status: 'pending_dispatch', ageMin: 12 },
    { merchant: 'm-yasmine', area: 'a-sweifieh', dest: D.wakalat, customerPhone: '0790000303', mealJod: 9, status: 'pending_dispatch', ageMin: 6 },
    { merchant: 'm-sanabel', area: 'a-uthaina', dest: D.uthaina, customerName: 'عبدالله', customerPhone: '0790000304', captain: 'c-samer', status: 'on_the_way', ageMin: 18 },
  ];

  let seq = 10000;
  const orders: DeliveryOrder[] = defs.map((d, i) => {
    const m = merchants.find((x) => x.id === d.merchant)!;
    const createdAt = now - d.ageMin * MIN;
    const history: StatusHistoryEntry[] = [{ to: 'pending_dispatch', actor: merchantActor(m), at: createdAt, note: 'تم إنشاء الطلب' }];
    const push = (to: OrderStatus, offsetMin: number, actor: ActorRef, note?: string) =>
      history.push({ from: history[history.length - 1].to, to, actor, at: createdAt + offsetMin * MIN, note });
    if (d.captain) {
      push('awaiting_captain', 0.2, SYSTEM_ACTOR, 'نشر للعموم');
      push('accepted', 1.5, captainActor(d.captain));
      push('heading_to_pickup', 2, captainActor(d.captain));
      push('picked_up', 9, captainActor(d.captain));
      push('on_the_way', 10, captainActor(d.captain));
      if (d.status === 'delivered') push('delivered', 24, captainActor(d.captain));
    } else if (d.status === 'cancelled') {
      push('cancelled', 4, ADMIN_ACTOR, 'إلغاء تجريبي قبل الإسناد');
    } else if (d.status === 'dispatch_expired') {
      push('awaiting_captain', 0.2, SYSTEM_ACTOR, 'نشر للعموم — الجولة 1 من 3');
      push('dispatch_expired', 3.2, SYSTEM_ACTOR, `${ROUNDS_EXHAUSTED_REASON} — أُعيد إلى طابور الإدارة`);
    }
    const last = history[history.length - 1];
    return {
      id: `o-${i + 1}`,
      reference: `SH-${++seq}`,
      merchantId: m.id,
      pickup: { position: m.pickup, address: m.address },
      customerName: d.customerName,
      customerPhone: d.customerPhone ?? `07900004${String(i + 1).padStart(2, '0')}`,
      destination: { ...d.dest, position: polygonCentroid(areas.find((a) => a.id === d.area)!.polygon), approximate: true },
      areaId: d.area,
      areaName: areaName(d.area),
      mealValue: d.mealJod !== undefined ? jodToFils(d.mealJod) : undefined,
      deliveryPrice: priceOf(m.id, d.area),
      pricingSnapshotAt: createdAt,
      captainId: d.captain,
      dispatchMode: d.captain || d.status === 'dispatch_expired' ? 'public' : undefined,
      dispatchRound: d.captain || d.status === 'dispatch_expired' ? 1 : 0,
      dispatchAttempt: d.status === 'dispatch_expired' ? MAX_DISPATCH_ROUNDS : d.captain ? 1 : 0,
      queueReason: d.status === 'dispatch_expired' ? ROUNDS_EXHAUSTED_REASON : undefined,
      status: d.status,
      createdAt,
      updatedAt: last.at,
      deliveredAt: d.status === 'delivered' ? last.at : undefined,
      history,
    };
  });

  // The seeded active delivery: Captain Samer is part-way to the customer.
  const active = orders.find((o) => o.status === 'on_the_way')!;
  const samer = captains.find((c) => c.id === 'c-samer')!;
  samer.lastLocation = { position: { lat: 31.9885, lng: 35.8625 }, recordedAt: now, source: 'trip_simulated', activeOrderId: active.id };

  return {
    merchants,
    captains,
    areas,
    routes: [],
    prices,
    pricingAudit: [],
    orders,
    offers: [],
    walletTx,
    // Official contact details are pending from the Product Owner (SRS §4.11) — start empty.
    supportContacts: [],
    alerts: [
      { id: 'al-1', kind: 'no_candidate', message: `الطلب ${orders[11].reference}: ${ROUNDS_EXHAUSTED_REASON} — بحاجة إلى إجراء من الإدارة`, at: orders[11].updatedAt, orderId: orders[11].id, read: false },
      { id: 'al-2', kind: 'new_order', message: `طلب جديد ${orders[13].reference} من ${merchants[3].businessName}`, at: orders[13].createdAt, orderId: orders[13].id, read: false },
    ],
    settings: { publicBroadcast: true },
    demo: { ...DEFAULT_DEMO_SETTINGS },
    seq,
  };
}
