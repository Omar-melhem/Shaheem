import './setup';
import { useAppStore, captainEligibility } from '@/application/store';
import { merchantZoneOptions, resolveZoneFee } from '@/application/queries';
import { polygonCentroid, polygonError } from '@/domain/geo';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS, ROUNDS_EXHAUSTED_REASON } from '@/domain/dispatch';
import { isValidOptionalPhone, isValidPhone, normalizePhone } from '@/domain/phone';
import { destinationPinError, isAreaOnly } from '@/domain/destination';
import { parseJodInput } from '@/domain/money';
import { ORDER_VALUE_INVALID, ORDER_VALUE_REQUIRED, checkOrderValue } from '@/domain/orderValue';
import { previewPricingCopy } from '@/application/pricingCopy';
import { check, finish, section } from './harness';

// Business-rule checks against the real store and seed. Run with `npm test`.
const S = () => useAppStore.getState();
const at = (zoneId: string) => polygonCentroid(S().areas.find((a) => a.id === zoneId)!.polygon);
const PHONE = '0791111111';

section('Auth');
check(S().authenticate('admin', 'admin1234').ok, 'admin login');
const ml = S().authenticate('merchant1', 'demo1234');
check(ml.ok && ml.value.role === 'merchant' && ml.value.id === 'm-sanabel', 'merchant1 → Sanabel');
check(S().authenticate('captain1', 'demo1234').ok, 'captain1 login');
check(!S().authenticate('admin', 'wrong').ok, 'bad password rejected');

section('Business category (FE-CR §8)');
const base = { businessName: 'x', contactName: 'y', phone: '0790000888', cityId: 'amman', areaId: 'a-jubaiha', pickup: { lat: 32.02, lng: 35.87 }, password: 'secret1' };
check(!S().createMerchant({ ...base, category: null, username: 'nocat' }).ok, 'merchant without category rejected');
check(!S().createMerchant({ ...base, category: 'shoes' as any, username: 'badcat' }).ok, 'category outside taxonomy rejected');
check(S().merchants.find((m) => m.id === 'm-yasmine')!.category === null, 'legacy merchant stays uncategorised (not defaulted)');
const y = S().merchants.find((m) => m.id === 'm-yasmine')!;
const { id: _i, createdAt: _c, status: _s, ...yIn } = y;
check(!S().updateMerchant(y.id, yIn).ok, 'editing uncategorised merchant requires a category');
check(S().updateMerchant(y.id, { ...yIn, category: 'bakery' }).ok && S().merchants.find((m) => m.id === y.id)!.category === 'bakery', 'Admin sets category on edit');

section('Zone pricing setup (Spec §13)');
const created = S().createMerchant({ businessName: 'مطعم الجبيهة', category: 'restaurant', contactName: 'سامي', phone: '0790000999', cityId: 'amman', areaId: 'a-jubaiha', pickup: { lat: 32.02, lng: 35.87 }, username: 'jubeiha', password: 'secret1' });
check(created.ok, 'Admin registers new merchant');
const mid = created.ok ? created.value : '';
check(merchantZoneOptions(S(), mid).length === 0, 'new merchant has no zones yet');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 }).ok, 'order blocked without zones');
check(S().setMerchantAreaPrice(mid, 'a-jubaiha', 1000).ok, 'add Jubeiha 1.00');
check(S().setMerchantAreaPrice(mid, 'a-tla', 1500).ok, "add Tla' Al-Ali 1.50");
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2000).ok, 'add Khalda 2.00');
check(!S().setMerchantAreaPrice(mid, 'a-abdoun', 0).ok, 'zero fee rejected');
check(S().prices.filter((p) => p.merchantId === mid && p.areaId === 'a-khalda').length === 1, 'no duplicate merchant-zone row');
check(merchantZoneOptions(S(), mid).length === 3, 'merchant selector shows 3 zones');
check(S().authenticate('jubeiha', 'secret1').ok, 'new merchant can log in');

section('Order creation from the customer pin');
const o1 = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000, expectedFee: 2000 });
check(o1.ok, 'order to Khalda from pin');
const order1 = S().orders.find((o) => o1.ok && o.id === o1.value.id)!;
check(order1.deliveryPrice === 2000 && order1.areaName === 'خلدا', 'order stores JOD 2.00');
check(!!order1.pricingSnapshotAt, 'pricing snapshot timestamp');
check(order1.destination.position?.lat === at('a-khalda').lat && !order1.destination.approximate, 'order stores the exact customer pin');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: 31.5, lng: 36.5 }, mealValue: 5000 }).ok, 'pin outside every zone rejected');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: NaN, lng: 0 }, mealValue: 5000 }).ok, 'missing/invalid pin rejected');
const named = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-tla', location: at('a-tla'), placeName: 'سيتي مول', mealValue: 5000 });
check(named.ok && S().orders.find((o) => o.id === named.value.id)!.destination.label.includes('سيتي مول'), 'searched place name kept on the order');

section('Fee lock and re-confirmation');
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2500).ok, 'Admin changes Khalda to 2.50');
const stale = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000, expectedFee: 2000 });
check(!stale.ok && stale.code === 'fee_changed' && stale.currentFee === 2500, 'stale displayed fee → fee_changed with new fee');
const o2 = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000, expectedFee: 2500 });
check(o2.ok && S().orders.find((o) => o.id === o2.value.id)!.deliveryPrice === 2500, 'second order uses 2.50');
check(S().orders.find((o) => o.id === order1.id)!.deliveryPrice === 2000, 'first order still 2.00');

section('Request validation');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-abdoun', location: at('a-abdoun'), mealValue: 5000 }).ok, 'zone not enabled for merchant rejected');
check(S().createOrder(mid, { customerPhone: '', areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 }).ok, 'customer phone is optional (CR v1.3 §8.4)');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 0 }).ok, 'zero order value rejected');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: -500 }).ok, 'negative order value rejected');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 12.5 }).ok, 'non-integer fils rejected');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda') } as never).ok, 'missing order value rejected');
S().setMerchantAreaPriceStatus(mid, 'a-tla', false);
check(!merchantZoneOptions(S(), mid).some((z) => z.area.id === 'a-tla'), 'disabled zone hidden from merchant');
S().setServiceAreaStatus('a-jubaiha', false);
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-jubaiha', location: at('a-jubaiha'), mealValue: 5000 }).ok, 'central zone deactivated → rejected');
S().setServiceAreaStatus('a-jubaiha', true);

section('Zones');
check(!S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'خلدا', aliases: [] }).ok, 'duplicate zone name rejected');
check(!S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'منطقة', aliases: ['Khalda'] }).ok, 'duplicate via alias rejected');
check(S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'ضاحية الرشيد', aliases: ['Rashid'] }).ok, 'new central zone');

section('Dispatch, delivery and wallet');
const o = S().orders.find((x) => o2.ok && x.id === o2.value.id)!;
check(o.status === 'awaiting_captain', `public dispatch still works (${o.status})`);
const offer = S().offers.find((x) => x.orderId === o.id && x.status === 'pending')!;
check(!!offer, 'offer created');
check(S().acceptOffer(offer.id, offer.captainId).ok, 'captain accepts');
for (let i = 0; i < 4; i++) S().advanceDelivery(o.id, offer.captainId);
check(S().orders.find((x) => x.id === o.id)!.status === 'delivered', 'delivered');
check(!captainEligibility(S(), S().captains.find((c) => c.id === 'c-yazan')!).eligible, 'wallet eligibility intact');

section('Dispatch rounds: 60 s × 3, then Admin queue (FU-1.2 §5)');
// One Captain per round so three rounds need only three eligible Captains.
S().updateDemoSettings({ offerPolicy: 'sequential' });
const newOrder = () => {
  const r = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 });
  return r.ok ? r.value.id : '';
};
const orderById = (id: string) => S().orders.find((x) => x.id === id)!;
const pendingOf = (id: string) => S().offers.filter((x) => x.orderId === id && x.status === 'pending');
const ROUND_MS = DISPATCH_ROUND_SEC * 1000;

const r1 = newOrder();
check(orderById(r1).dispatchAttempt === 1 && pendingOf(r1).length === 1, 'round 1 starts immediately');
const first = pendingOf(r1)[0];
check(first.expiresAt - first.offeredAt === ROUND_MS && ROUND_MS === 60_000, 'round window is 60 seconds');
let clock = first.offeredAt;
clock += ROUND_MS + 1000;
S().tick(clock);
check(orderById(r1).dispatchAttempt === 2 && pendingOf(r1)[0]?.attempt === 2, 'no acceptance → round 2 starts automatically');
check(pendingOf(r1)[0]?.captainId !== first.captainId, 'round 2 goes to the next nearest Captain');
clock += ROUND_MS + 1000;
S().tick(clock);
check(orderById(r1).dispatchAttempt === 3, 'round 3 starts');
clock += ROUND_MS + 1000;
S().tick(clock);
const exhausted = orderById(r1);
check(exhausted.status === 'dispatch_expired' && exhausted.queueReason === ROUNDS_EXHAUSTED_REASON, 'after 3 rounds → Admin queue with reason');
check(pendingOf(r1).length === 0 && !S().offers.some((x) => x.orderId === r1 && (x.attempt ?? 0) > MAX_DISPATCH_ROUNDS), 'no fourth automatic round');
S().tick(clock + 5 * ROUND_MS);
check(orderById(r1).status === 'dispatch_expired', 'stays in the queue — never cancelled or delivered by expiry');
check(S().dispatchPublic(r1).ok && orderById(r1).dispatchAttempt === 1 && !orderById(r1).queueReason, 'explicit Admin publish starts a new cycle');
S().cancelOrder(r1, 'تنظيف الاختبار');

const r2 = newOrder();
const o2offer = pendingOf(r2)[0];
check(S().acceptOffer(o2offer.id, o2offer.captainId).ok, 'accepted in round 1');
S().tick(o2offer.offeredAt + 3 * ROUND_MS + 3000);
check(orderById(r2).status === 'accepted' && orderById(r2).dispatchAttempt === 1 && pendingOf(r2).length === 0, 'acceptance stops further rounds');
check(!S().acceptOffer(o2offer.id, o2offer.captainId).ok, 'accepting the same offer twice is refused');

const r3 = newOrder();
const o3offer = pendingOf(r3)[0];
S().rejectOffer(o3offer.id, o3offer.captainId);
check(orderById(r3).dispatchAttempt === 2, 'all offers declined → next round starts without waiting');
check(S().setPublicBroadcast(false).ok && orderById(r3).status === 'pending_dispatch' && pendingOf(r3).length === 0, 'broadcast off withdraws offers, no new public offers');
S().tick(Date.now() + 10 * ROUND_MS);
check(pendingOf(r3).length === 0, 'no rounds start while broadcast is off');
S().setPublicBroadcast(true);
S().cancelOrder(r3, 'تنظيف الاختبار');

section('Phone numbers: exactly 10 digits (FU-1.2 §1.3)');
check(isValidPhone('0791234567') && !isValidPhone('079123456') && !isValidPhone('07912345678'), '10 digits only');
check(normalizePhone('079 123-4567') === '0791234567' && normalizePhone('٠٧٩١٢٣٤٥٦٧') === '0791234567', 'separators dropped, Arabic digits converted, leading zero kept');
check(isValidOptionalPhone('') && !isValidOptionalPhone('123'), 'optional phone: blank valid, short invalid');
check(!S().createOrder(mid, { customerPhone: '079111111', areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 }).ok, '9-digit customer phone rejected');
const spaced = S().createOrder(mid, { customerPhone: '079 111 1111', areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 });
check(spaced.ok && orderById(spaced.value.id).customerPhone === '0791111111', 'customer phone stored normalised');
check(!S().createMerchant({ ...base, category: 'cafe', phone: '079000088', username: 'shortphone' }).ok, 'merchant 9-digit phone rejected');
check(!S().createCaptain({ fullName: 'ك', phone: '07900001234', vehicleType: 'car', vehicleDescription: '', username: 'longphone', password: 'secret1' }).ok, 'captain 11-digit phone rejected');
check(S().setMerchantAreaPrice(mid, 'a-tla', 1750).ok, 'prices are not phone-validated');

section('Governorates and delivery routes (FU-1.2 §7)');
check(!S().createZone({ governorateId: '', cityId: '', name: 'بلا محافظة', aliases: [] }).ok, 'zone requires a governorate');
const irbid = S().createZone({ governorateId: 'irbid', cityId: 'irbid', name: 'الحصن', aliases: [] });
const pricesBefore = JSON.stringify(S().prices);
const route = S().createRoute({ governorateId: 'amman', originAreaId: 'a-khalda', destinationAreaId: 'a-tla' });
check(route.ok && S().routes.length === 1, 'origin → destination route saved');
check(!S().createRoute({ governorateId: 'amman', originAreaId: 'a-khalda', destinationAreaId: 'a-tla' }).ok, 'duplicate route rejected');
check(!S().createRoute({ governorateId: 'amman', originAreaId: 'a-khalda', destinationAreaId: 'a-khalda' }).ok, 'same origin and destination rejected');
check(irbid.ok && !S().createRoute({ governorateId: 'amman', originAreaId: 'a-khalda', destinationAreaId: irbid.value }).ok, 'area outside the governorate rejected');
check(!S().createRoute({ governorateId: 'amman', originAreaId: '', destinationAreaId: 'a-tla' }).ok, 'missing origin rejected');
check(JSON.stringify(S().prices) === pricesBefore, 'routes do not change Merchant prices');

section('Merchant City → Area → pin (CR v1.3 §3)');
const loc = { ...base, category: 'cafe' as const, phone: '0790000777' };
check(!S().createMerchant({ ...loc, cityId: null, username: 'nocity' }).ok, 'City required for a new merchant');
check(!S().createMerchant({ ...loc, areaId: null, username: 'noarea' }).ok, 'Area required for a new merchant');
check(!S().createMerchant({ ...loc, cityId: 'irbid', username: 'wrongcity' }).ok, 'Area from another City rejected');
check(!S().createMerchant({ ...loc, pickup: { lat: 31.95, lng: 35.88 }, username: 'outside' }).ok, 'pin outside the Area polygon rejected, Area not reassigned');
const placed = S().createMerchant({ ...loc, username: 'placed' });
const placedM = S().merchants.find((m) => placed.ok && m.id === placed.value)!;
check(placed.ok && placedM.areaId === 'a-jubaiha' && placedM.pickup.lat === 32.02 && placedM.address.includes('الجبيهة'), 'saved with IDs, exact pin and derived label');
const legacy = S().merchants.find((m) => m.id === 'm-yasmine')!;
const { id: _li, createdAt: _lc, status: _ls, address: legacyAddress, ...legacyInput } = legacy;
check(!legacy.areaId && S().updateMerchant(legacy.id, legacyInput).ok && S().merchants.find((m) => m.id === legacy.id)!.address === legacyAddress, 'legacy text-address merchant stays editable and unchanged');
check(!S().updateMerchant(legacy.id, { ...legacyInput, pickup: { lat: 31.96, lng: 35.86 } }).ok, 'moving a legacy pin requires City and Area');

section('Copy merchant pricing (CR v1.3 §4)');
const newTarget = S().createMerchant({ ...loc, username: 'copytarget' });
const tid = newTarget.ok ? newTarget.value : '';
const priceOf = (m: string, a: string) => S().prices.find((x) => x.merchantId === m && x.areaId === a);
S().setMerchantAreaPrice(tid, 'a-khalda', 9000);
const srcKhalda = priceOf('m-sanabel', 'a-khalda')!.price;
const historic = S().orders.map((x) => [x.id, x.deliveryPrice]);
check(!S().copyMerchantPricing(tid, tid, 'fill_missing').ok, 'copying onto itself rejected');
const fill = previewPricingCopy(S(), 'm-sanabel', tid, 'fill_missing');
check(fill.counts.kept === 1 && fill.counts.update === 0 && fill.counts.add > 0, 'fill preview keeps the existing price');
const auditBefore = S().pricingAudit.length;
const filled = S().copyMerchantPricing('m-sanabel', tid, 'fill_missing');
check(filled.ok && filled.value.changed === fill.changes && priceOf(tid, 'a-khalda')!.price === 9000, 'default mode fills missing and does not overwrite');
check(S().pricingAudit.length === auditBefore + 1 && S().pricingAudit[0].changes.length === fill.changes && S().pricingAudit[0].actor !== '', 'copy is audited with its changes');
const countAfterFill = S().prices.filter((x) => x.merchantId === tid).length;
const retry = S().copyMerchantPricing('m-sanabel', tid, 'fill_missing');
check(retry.ok && retry.value.changed === 0 && S().prices.filter((x) => x.merchantId === tid).length === countAfterFill && S().pricingAudit.length === auditBefore + 1, 'retry is idempotent: no duplicates, no new audit');
const over = previewPricingCopy(S(), 'm-sanabel', tid, 'overwrite');
check(over.counts.update === 1 && S().copyMerchantPricing('m-sanabel', tid, 'overwrite').ok && priceOf(tid, 'a-khalda')!.price === srcKhalda, 'overwrite replaces only when explicitly chosen');
const stopArea = fill.rows[0].areaId;
S().setServiceAreaStatus(stopArea, false);
const skipPreview = previewPricingCopy(S(), 'm-sanabel', tid, 'fill_missing');
check(skipPreview.rows.find((r) => r.areaId === stopArea)?.action === 'skipped', 'stopped area is skipped and shown');
S().setServiceAreaStatus(stopArea, true);
check(JSON.stringify(S().orders.filter((x) => historic.some(([i]) => i === x.id)).map((x) => [x.id, x.deliveryPrice])) === JSON.stringify(historic), 'existing order fee snapshots unchanged');

section('Boundaries (CR v1.3 §5)');
check(polygonError([{ lat: 1, lng: 1 }, { lat: 2, lng: 2 }]) !== null, 'fewer than 3 points invalid');
check(polygonError([{ lat: 1, lng: 1 }, { lat: 1, lng: 1 }, { lat: 2, lng: 2 }]) !== null, 'duplicate vertices do not count');
check(polygonError([{ lat: 0, lng: 0 }, { lat: 1, lng: 1 }, { lat: 1, lng: 0 }, { lat: 0, lng: 1 }]) !== null, 'self-intersecting boundary invalid');
check(polygonError(S().areas.find((a) => a.id === 'a-khalda')!.polygon) === null, 'seed boundary valid');
check(!S().updateZone('a-khalda', { polygon: [{ lat: 0, lng: 0 }, { lat: 1, lng: 1 }, { lat: 1, lng: 0 }, { lat: 0, lng: 1 }] }).ok, 'store refuses an invalid boundary');
const other = JSON.stringify(S().areas.find((a) => a.id === 'a-tla')!.polygon);
const square = [{ lat: 31.97, lng: 35.81 }, { lat: 31.97, lng: 35.846 }, { lat: 32.011, lng: 35.846 }, { lat: 32.011, lng: 35.81 }];
check(S().updateZone('a-khalda', { polygon: square }).ok && JSON.stringify(S().areas.find((a) => a.id === 'a-khalda')!.polygon) === JSON.stringify(square) && JSON.stringify(S().areas.find((a) => a.id === 'a-tla')!.polygon) === other, 'saving writes only to the selected Area');

section('Orders: order value and destination (CR v1.3 §8)');
const nameless = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-khalda'), mealValue: 12500 });
const namelessOrder = S().orders.find((x) => nameless.ok && x.id === nameless.value.id)!;
check(nameless.ok && namelessOrder.mealValue === 12500 && namelessOrder.customerPhone === undefined, 'order value kept in fils; name and phone optional');
check(namelessOrder.deliveryPrice !== namelessOrder.mealValue, 'order value and delivery fee stay separate');
check(!!namelessOrder.destination.position && !namelessOrder.destination.approximate && namelessOrder.destination.label !== '', 'exact pin and a label stored without a typed description');
check(S().orders.some((x) => x.mealValue === undefined), 'older orders without an order value stay readable');
check(!S().createOrder(mid, { customerPhone: '123', areaId: 'a-khalda', location: at('a-khalda'), mealValue: 5000 }).ok, 'a supplied phone must still be 10 digits');

section('Orders: required area, optional exact pin');
const ordersBefore = S().orders.length;
check(!S().createOrder(mid, { mealValue: 5000 } as never).ok && !S().createOrder(mid, { areaId: '', mealValue: 5000 }).ok, 'no area → rejected even with a valid value');
check(!S().createOrder(mid, { location: at('a-khalda'), mealValue: 5000 } as never).ok, 'a pin alone does not replace the required area');
check(!S().createOrder(mid, { areaId: 'خلدا', mealValue: 5000 }).ok, 'typed area name is not an area ID');
check(S().orders.length === ordersBefore, 'rejected requests create no order');

const zoneFee = resolveZoneFee(S(), mid, 'a-khalda');
const areaOnlyResult = S().createOrder(mid, { areaId: 'a-khalda', mealValue: 7000 });
const areaOnlyOrder = S().orders.find((x) => areaOnlyResult.ok && x.id === areaOnlyResult.value.id)!;
check(areaOnlyResult.ok && areaOnlyOrder.areaId === 'a-khalda' && areaOnlyOrder.deliveryPrice === (zoneFee.kind === 'ok' ? zoneFee.price : -1), 'area-only order created with the merchant + area fee');
check(areaOnlyOrder.destination.position === undefined && !areaOnlyOrder.destination.approximate && isAreaOnly(areaOnlyOrder.destination), 'area-only order stores no coordinates (no centroid, no 0,0)');
check(areaOnlyOrder.destination.label.includes(areaOnlyOrder.areaName), 'area-only label names the area');
const placeIgnored = S().createOrder(mid, { areaId: 'a-khalda', placeName: 'مكان وهمي', mealValue: 7000 });
check(placeIgnored.ok && !S().orders.find((x) => x.id === placeIgnored.value.id)!.destination.label.includes('مكان وهمي'), 'a place name without a pin is not presented as a location');

const withPin = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-khalda'), mealValue: 7000 });
const withPinOrder = S().orders.find((x) => withPin.ok && x.id === withPin.value.id)!;
check(withPin.ok && withPinOrder.areaId === 'a-khalda' && !isAreaOnly(withPinOrder.destination) && withPinOrder.destination.position?.lat === at('a-khalda').lat, 'area + pin stores both');
const mismatch = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-tla'), mealValue: 7000 });
check(!mismatch.ok && mismatch.code === 'pin_outside_area', "pin in another area is rejected, it never switches the area or the fee");
check(!S().createOrder(mid, { areaId: 'a-khalda', location: { lat: 0, lng: 0 }, mealValue: 7000 }).ok, 'fictitious 0,0 pin rejected');
check(withPinOrder.deliveryPrice === areaOnlyOrder.deliveryPrice, 'adding a pin does not change the fee');

const areaBeforeEdit = S().areas.find((a) => a.id === 'a-khalda')!;
check(destinationPinError(areaBeforeEdit, at('a-khalda')) === null && destinationPinError(areaBeforeEdit, at('a-tla')) !== null, 'pin check follows the selected area');
check(destinationPinError({ ...areaBeforeEdit, polygon: [] }, at('a-khalda')) !== null, 'a pin cannot be verified against an area with no boundary');
const noBoundaryArea = S().createZone({ governorateId: areaBeforeEdit.governorateId, cityId: areaBeforeEdit.cityId, name: 'منطقة بلا حدود', aliases: [], polygon: [] } as never);
check(noBoundaryArea.ok, 'area without a boundary can be configured');
if (noBoundaryArea.ok) {
  check(S().setMerchantAreaPrice(mid, noBoundaryArea.value, 1200).ok, 'priced area without a boundary');
  const noBoundary = S().createOrder(mid, { areaId: noBoundaryArea.value, mealValue: 7000 });
  check(noBoundary.ok && S().orders.find((x) => x.id === noBoundary.value.id)!.deliveryPrice === 1200, 'area without a boundary can still be ordered area-only');
  check(!S().createOrder(mid, { areaId: noBoundaryArea.value, location: at('a-khalda'), mealValue: 7000 }).ok, 'and refuses a pin it cannot verify');
}
check(!S().createOrder(mid, { areaId: 'a-abdoun', mealValue: 7000 }).ok && resolveZoneFee(S(), mid, 'a-abdoun').kind === 'no_price', 'no merchant price → blocked, no invented fee');
const staleAreaOnly = S().createOrder(mid, { areaId: 'a-khalda', mealValue: 7000, expectedFee: 1 });
check(!staleAreaOnly.ok && staleAreaOnly.code === 'fee_changed', 'area-only order still re-confirms a changed fee');

const areaOnlyId = areaOnlyOrder.id;
const walk = (status: string) => S().orders.find((x) => x.id === areaOnlyId)!.status === status;
check(walk('pending_dispatch') || walk('awaiting_captain'), 'area-only order enters the normal dispatch flow');
S().tick(Date.now());
check(S().orders.find((x) => x.id === areaOnlyId)!.destination.position === undefined, 'simulation clock never invents coordinates for an area-only order');

section('Order value input: parsing and display');
const shown = (raw: string) => { const c = checkOrderValue(raw); return c.ok ? c.display : null; };
const filsOf = (raw: string) => { const c = checkOrderValue(raw); return c.ok ? c.fils : null; };
const errorOf = (raw: string) => { const c = checkOrderValue(raw); return c.ok ? null : c.error; };
for (const [raw, display, fils] of [
  ['50', '50.00', 50000], ['50.0', '50.00', 50000], ['50.5', '50.50', 50500], ['50.75', '50.75', 50750], ['50.125', '50.125', 50125],
  ['5', '5.00', 5000], ['50.', '50.00', 50000], ['.5', '0.50', 500], ['0.001', '0.001', 1], ['1.005', '1.005', 1005], ['4.35', '4.35', 4350],
  ['٥٠', '50.00', 50000], ['۵۰', '50.00', 50000], ['١٢٫٥', '12.50', 12500], ['١٢٫١٢٥', '12.125', 12125], ['12,5', '12.50', 12500], ['٥٠،٧٥', '50.75', 50750],
  ['1,000.50', '1000.50', 1000500], ['1,000,000', '1000000.00', 1000000000], ['١٬٥٠٠', '1500.00', 1500000],
  ['‏50‎', '50.00', 50000], ['  50  ', '50.00', 50000],
] as const) {
  check(shown(raw) === display && filsOf(raw) === fils, `"${raw}" → ${display} (${fils} fils)`);
}
check(shown(shown('12.125')!) === '12.125' && filsOf(shown('50')!) === 50000, 'a normalized value stays editable and re-parses to the same amount (never converted twice)');
check(errorOf('') === ORDER_VALUE_REQUIRED && errorOf('   ') === ORDER_VALUE_REQUIRED, 'empty → required message');
for (const raw of ['abc', '-5', '+5', '0', '0.000', '.', '1.2.3', '5 0', '50 د.أ', 'NaN', 'Infinity', '1e3', '12,', '1,2345', '12,34,56', '1,00.5', '٬', '9'.repeat(30)]) {
  check(errorOf(raw) === ORDER_VALUE_INVALID, `"${raw.slice(0, 12)}" rejected as invalid`);
}
check(!!errorOf('50.1234') && errorOf('50.1234') !== ORDER_VALUE_INVALID, 'a fourth decimal is reported, never rounded away');
check(!!errorOf('1,500') && filsOf('1,500') === null && parseJodInput('1,500') === null, 'ambiguous "1,500" is reported, never read as 1.5 or 1500');
check(parseJodInput('0') === 0 && parseJodInput('2') === 2000 && parseJodInput('١٫٥') === 1500, 'shared parser still serves the Admin money fields');
const fromInput = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-khalda'), mealValue: filsOf('٥٠٫٧٥')! });
check(fromInput.ok && S().orders.find((x) => x.id === fromInput.value.id)!.mealValue === 50750, 'typed value reaches the order in fils, exactly');

section('Commission boundary (CR v1.3 §6): nothing charged from browser code');
const txBefore = S().walletTx.length;
const debitOrder = S().orders.find((x) => x.status === 'on_the_way')!;
S().advanceDelivery(debitOrder.id, debitOrder.captainId!);
check(S().walletTx.length === txBefore && S().walletTx.every((t) => t.amount > 0), 'delivery posts no wallet debit in the prototype');

finish();
