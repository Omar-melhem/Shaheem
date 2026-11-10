import './setup';
import { useAppStore, captainEligibility } from '@/application/store';
import { merchantZoneOptions, pricedAreaIds, resolveZoneFee } from '@/application/queries';
import { polygonCentroid } from '@/domain/geo';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS, ROUNDS_EXHAUSTED_REASON, isAutoDispatchEligible } from '@/domain/dispatch';
import { commissionFils, isValidCommissionBp } from '@/domain/commission';
import { ammanDayKey, ammanWallTimeToEpoch, lastThreeAmmanDays } from '@/domain/time';
import { areaLabel, isDestinationActive } from '@/domain/regions';
import { isValidOptionalPhone, isValidPhone, normalizePhone } from '@/domain/phone';
import { destinationPinError, isAreaOnly } from '@/domain/destination';
import { formatJodInput, parseJodAmount, parseJodInput } from '@/domain/money';
import { previewPricingCopy } from '@/application/pricingCopy';
import { ACTIVITY_DAYS, MERCHANT_RECENT_PREVIEW, availabilitySummary, merchantOrderOverview, operationalAlerts, operationalKpis, orderActivity, platformKpis } from '@/application/dashboard';
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
const base = { businessName: 'x', phone: '0790000888', cityId: 'amman', areaId: 'a-jubaiha', pickup: { lat: 32.02, lng: 35.87 }, password: 'secret1' };
check(!S().createMerchant({ ...base, category: null, username: 'nocat' }).ok, 'merchant without category rejected');
check(!S().createMerchant({ ...base, category: 'shoes' as any, username: 'badcat' }).ok, 'category outside taxonomy rejected');
check(S().merchants.find((m) => m.id === 'm-yasmine')!.category === null, 'legacy merchant stays uncategorised (not defaulted)');
const y = S().merchants.find((m) => m.id === 'm-yasmine')!;
const { id: _i, createdAt: _c, status: _s, ...yIn } = y;
check(!S().updateMerchant(y.id, yIn).ok, 'editing uncategorised merchant requires a category');
check(S().updateMerchant(y.id, { ...yIn, category: 'bakery' }).ok && S().merchants.find((m) => m.id === y.id)!.category === 'bakery', 'Admin sets category on edit');

section('Zone pricing setup (Spec §13)');
const created = S().createMerchant({ businessName: 'مطعم الجبيهة', category: 'restaurant', phone: '0790000999', cityId: 'amman', areaId: 'a-jubaiha', pickup: { lat: 32.02, lng: 35.87 }, username: 'jubeiha', password: 'secret1' });
check(created.ok, 'Admin registers new merchant');
const mid = created.ok ? created.value : '';
check(merchantZoneOptions(S(), mid).length === 0, 'new merchant has no zones yet');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda') }).ok, 'order blocked without zones');
check(S().setMerchantAreaPrice(mid, 'a-jubaiha', 1000).ok, 'add Jubeiha 1.00');
check(S().setMerchantAreaPrice(mid, 'a-tla', 1500).ok, "add Tla' Al-Ali 1.50");
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2000).ok, 'add Khalda 2.00');
check(!S().setMerchantAreaPrice(mid, 'a-abdoun', 0).ok, 'zero fee rejected');
check(merchantZoneOptions(S(), mid).length === 0, 'priced but not covered → not orderable (CR v1.4 §2)');
check(pricedAreaIds(S(), mid).size === 3 && pricedAreaIds(S(), mid).has('a-khalda'), 'pricing filter counts distinct priced areas, independent of coverage');
check(S().setMerchantCoverage(mid, ['a-jubaiha', 'a-tla', 'a-khalda'], true).ok, 'Admin enables coverage for the priced zones');
check(S().prices.filter((p) => p.merchantId === mid && p.areaId === 'a-khalda').length === 1, 'no duplicate merchant-zone row');
check(merchantZoneOptions(S(), mid).length === 3, 'merchant selector shows 3 zones');
check(S().authenticate('jubeiha', 'secret1').ok, 'new merchant can log in');

section('Order creation from the customer pin');
const o1 = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), expectedFee: 2000 });
check(o1.ok, 'order to Khalda from pin');
const order1 = S().orders.find((o) => o1.ok && o.id === o1.value.id)!;
check(order1.deliveryPrice === 2000 && order1.areaName === 'خلدا', 'order stores JOD 2.00');
check(!!order1.pricingSnapshotAt, 'pricing snapshot timestamp');
check(!('customerName' in order1) && S().orders.every((o) => !('customerName' in o)), 'orders carry no customer name (Master Prompt §13)');
check(order1.destination.position?.lat === at('a-khalda').lat && !order1.destination.approximate, 'order stores the exact customer pin');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: 31.5, lng: 36.5 } }).ok, 'pin outside every zone rejected');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: NaN, lng: 0 } }).ok, 'missing/invalid pin rejected');
const named = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-tla', location: at('a-tla'), placeName: 'سيتي مول' });
check(named.ok && S().orders.find((o) => o.id === named.value.id)!.destination.label.includes('سيتي مول'), 'searched place name kept on the order');

section('Fee lock and re-confirmation');
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2500).ok, 'Admin changes Khalda to 2.50');
const stale = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), expectedFee: 2000 });
check(!stale.ok && stale.code === 'fee_changed' && stale.currentFee === 2500, 'stale displayed fee → fee_changed with new fee');
const o2 = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda'), expectedFee: 2500 });
check(o2.ok && S().orders.find((o) => o.id === o2.value.id)!.deliveryPrice === 2500, 'second order uses 2.50');
check(S().orders.find((o) => o.id === order1.id)!.deliveryPrice === 2000, 'first order still 2.00');

section('Request validation');
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-abdoun', location: at('a-abdoun') }).ok, 'zone not enabled for merchant rejected');
check(S().createOrder(mid, { customerPhone: '', areaId: 'a-khalda', location: at('a-khalda') }).ok, 'customer phone is optional (CR v1.3 §8.4)');
const noGoods = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda' });
check(noGoods.ok && S().orders.find((x) => x.id === noGoods.value.id)!.mealValue === undefined, 'no goods/order value is collected (CR v1.4 §4)');
S().setMerchantAreaPriceStatus(mid, 'a-tla', false);
check(!merchantZoneOptions(S(), mid).some((z) => z.area.id === 'a-tla'), 'disabled zone hidden from merchant');
S().setServiceAreaStatus('a-jubaiha', false);
check(!S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-jubaiha', location: at('a-jubaiha') }).ok, 'central zone deactivated → rejected');
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
  const r = S().createOrder(mid, { customerPhone: PHONE, areaId: 'a-khalda', location: at('a-khalda') });
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
check(!S().createOrder(mid, { customerPhone: '079111111', areaId: 'a-khalda', location: at('a-khalda') }).ok, '9-digit customer phone rejected');
const spaced = S().createOrder(mid, { customerPhone: '079 111 1111', areaId: 'a-khalda', location: at('a-khalda') });
check(spaced.ok && orderById(spaced.value.id).customerPhone === '0791111111', 'customer phone stored normalised');
check(!S().createMerchant({ ...base, category: 'cafe', phone: '079000088', username: 'shortphone' }).ok, 'merchant 9-digit phone rejected');
check(!S().createCaptain({ fullName: 'ك', phone: '07900001234', username: 'longphone', password: 'secret1' }).ok, 'captain 11-digit phone rejected');
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

section('Region catalogue without boundaries (CR v1.4 §1)');
const legacyPolygon = JSON.stringify(S().areas.find((a) => a.id === 'a-khalda')!.polygon);
check(S().updateZone('a-khalda', { notes: 'ملاحظة' }).ok && JSON.stringify(S().areas.find((a) => a.id === 'a-khalda')!.polygon) === legacyPolygon, 'editing an area keeps its legacy boundary untouched');
const plain = S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'منطقة بالاسم فقط', aliases: [] });
check(plain.ok && S().areas.find((a) => a.id === plain.value)!.polygon.length === 0, 'an area is created by name, with no coordinates');

section('Orders: destination and optional fields (CR v1.3 §8, v1.4 §4)');
const nameless = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-khalda') });
const namelessOrder = S().orders.find((x) => nameless.ok && x.id === nameless.value.id)!;
check(nameless.ok && namelessOrder.customerPhone === undefined && namelessOrder.mealValue === undefined, 'name, phone and goods value all absent');
check(!!namelessOrder.destination.position && !namelessOrder.destination.approximate && namelessOrder.destination.label !== '', 'exact pin and a label stored without a typed description');
check(S().orders.some((x) => x.mealValue !== undefined), 'older orders keep their recorded goods value (read-only)');
check(!S().createOrder(mid, { customerPhone: '123', areaId: 'a-khalda', location: at('a-khalda') }).ok, 'a supplied phone must still be 10 digits');

section('Orders: required area, optional exact pin');
const ordersBefore = S().orders.length;
check(!S().createOrder(mid, {} as never).ok && !S().createOrder(mid, { areaId: '' }).ok, 'no area → rejected even with a valid value');
check(!S().createOrder(mid, { location: at('a-khalda') } as never).ok, 'a pin alone does not replace the required area');
check(!S().createOrder(mid, { areaId: 'خلدا' }).ok, 'typed area name is not an area ID');
check(S().orders.length === ordersBefore, 'rejected requests create no order');

const zoneFee = resolveZoneFee(S(), mid, 'a-khalda');
const areaOnlyResult = S().createOrder(mid, { areaId: 'a-khalda' });
const areaOnlyOrder = S().orders.find((x) => areaOnlyResult.ok && x.id === areaOnlyResult.value.id)!;
check(areaOnlyResult.ok && areaOnlyOrder.areaId === 'a-khalda' && areaOnlyOrder.deliveryPrice === (zoneFee.kind === 'ok' ? zoneFee.price : -1), 'area-only order created with the merchant + area fee');
check(areaOnlyOrder.destination.position === undefined && !areaOnlyOrder.destination.approximate && isAreaOnly(areaOnlyOrder.destination), 'area-only order stores no coordinates (no centroid, no 0,0)');
check(areaOnlyOrder.destination.label.includes(areaOnlyOrder.areaName), 'area-only label names the area');
const placeIgnored = S().createOrder(mid, { areaId: 'a-khalda', placeName: 'مكان وهمي' });
check(placeIgnored.ok && !S().orders.find((x) => x.id === placeIgnored.value.id)!.destination.label.includes('مكان وهمي'), 'a place name without a pin is not presented as a location');

const withPin = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-khalda') });
const withPinOrder = S().orders.find((x) => withPin.ok && x.id === withPin.value.id)!;
check(withPin.ok && withPinOrder.areaId === 'a-khalda' && !isAreaOnly(withPinOrder.destination) && withPinOrder.destination.position?.lat === at('a-khalda').lat, 'area + pin stores both');
const mismatch = S().createOrder(mid, { areaId: 'a-khalda', location: at('a-tla') });
check(!mismatch.ok && mismatch.code === 'pin_outside_area', "pin in another area is rejected, it never switches the area or the fee");
check(!S().createOrder(mid, { areaId: 'a-khalda', location: { lat: 0, lng: 0 } }).ok, 'fictitious 0,0 pin rejected');
check(withPinOrder.deliveryPrice === areaOnlyOrder.deliveryPrice, 'adding a pin does not change the fee');

const areaBeforeEdit = S().areas.find((a) => a.id === 'a-khalda')!;
check(destinationPinError(areaBeforeEdit, at('a-khalda')) === null && destinationPinError(areaBeforeEdit, at('a-tla')) !== null, 'pin check follows the selected area');
check(destinationPinError({ ...areaBeforeEdit, polygon: [] }, at('a-khalda')) === null, 'an area with no boundary accepts the optional pin, unverified');
const noBoundaryArea = S().createZone({ governorateId: areaBeforeEdit.governorateId, cityId: areaBeforeEdit.cityId, name: 'منطقة بلا حدود', aliases: [], polygon: [] } as never);
check(noBoundaryArea.ok, 'area without a boundary can be configured');
if (noBoundaryArea.ok) {
  check(S().setMerchantAreaPrice(mid, noBoundaryArea.value, 1200).ok && S().setMerchantCoverage(mid, [noBoundaryArea.value], true).ok, 'covered and priced area without a boundary');
  const noBoundary = S().createOrder(mid, { areaId: noBoundaryArea.value });
  check(noBoundary.ok && S().orders.find((x) => x.id === noBoundary.value.id)!.deliveryPrice === 1200, 'area without a boundary can still be ordered area-only');
  const unverified = S().createOrder(mid, { areaId: noBoundaryArea.value, location: at('a-khalda') });
  check(unverified.ok && S().orders.find((x) => x.id === unverified.value.id)!.areaId === noBoundaryArea.value, 'its optional pin is kept, never moving the order to another area');
}
check(!S().createOrder(mid, { areaId: 'a-abdoun' }).ok && resolveZoneFee(S(), mid, 'a-abdoun').kind === 'not_covered', 'not covered → blocked');
S().setMerchantCoverage(mid, ['a-abdoun'], true);
check(!S().createOrder(mid, { areaId: 'a-abdoun' }).ok && resolveZoneFee(S(), mid, 'a-abdoun').kind === 'no_price', 'covered but no merchant price → blocked, no invented fee');
S().setMerchantCoverage(mid, ['a-abdoun'], false);
const staleAreaOnly = S().createOrder(mid, { areaId: 'a-khalda', expectedFee: 1 });
check(!staleAreaOnly.ok && staleAreaOnly.code === 'fee_changed', 'area-only order still re-confirms a changed fee');

const areaOnlyId = areaOnlyOrder.id;
const walk = (status: string) => S().orders.find((x) => x.id === areaOnlyId)!.status === status;
check(walk('pending_dispatch') || walk('awaiting_captain'), 'area-only order enters the normal dispatch flow');
S().tick(Date.now());
check(S().orders.find((x) => x.id === areaOnlyId)!.destination.position === undefined, 'simulation clock never invents coordinates for an area-only order');

section('Shared JOD parser (Admin money fields)');
const shown = (raw: string) => { const r = parseJodAmount(raw); return r.ok ? formatJodInput(r.fils) : null; };
const filsOf = (raw: string) => { const r = parseJodAmount(raw); return r.ok ? r.fils : null; };
for (const [raw, display, fils] of [
  ['50', '50.00', 50000], ['50.5', '50.50', 50500], ['50.125', '50.125', 50125], ['.5', '0.50', 500], ['1.005', '1.005', 1005],
  ['٥٠', '50.00', 50000], ['١٢٫٥', '12.50', 12500], ['12,5', '12.50', 12500], ['1,000.50', '1000.50', 1000500],
] as const) {
  check(shown(raw) === display && filsOf(raw) === fils, `"${raw}" → ${display} (${fils} fils)`);
}
for (const raw of ['abc', '-5', '+5', '.', '1.2.3', '50 د.أ', 'NaN', '1e3', '']) check(filsOf(raw) === null, `"${raw}" rejected`);
check(filsOf('50.1234') === null && filsOf('1,500') === null, 'a fourth decimal and the ambiguous "1,500" are refused, never guessed');
check(parseJodInput('0') === 0 && parseJodInput('2') === 2000 && parseJodInput('١٫٥') === 1500, 'parser still serves the Admin money fields');

section('Commission boundary (CR v1.3 §6): nothing charged from browser code');
const txBefore = S().walletTx.length;
const debitOrder = S().orders.find((x) => x.status === 'on_the_way')!;
S().advanceDelivery(debitOrder.id, debitOrder.captainId!);
check(S().walletTx.length === txBefore && S().walletTx.every((t) => t.amount > 0), 'delivery posts no wallet debit in the prototype');

section('Sub-areas (CR v1.4 §1.2)');
const parentRes = S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'ضاحية الاختبار', aliases: [] });
const parentId = parentRes.ok ? parentRes.value : '';
const sec1 = S().createZone({ governorateId: '', cityId: '', parentId, name: 'الحي الشرقي', aliases: [] });
const sec2 = S().createZone({ governorateId: '', cityId: '', parentId, name: 'الحي الغربي', aliases: [] });
const sec1Area = S().areas.find((a) => sec1.ok && a.id === sec1.value)!;
check(sec1.ok && sec2.ok && sec1Area.parentId === parentId && sec1Area.cityId === 'amman', 'an area holds several sections that inherit its city');
check(!S().createZone({ governorateId: '', cityId: '', parentId, name: 'الحي الشرقي', aliases: [] }).ok, 'duplicate section in the same area rejected');
check(S().createZone({ governorateId: '', cityId: '', parentId: 'a-khalda', name: 'الحي الشرقي', aliases: [] }).ok, 'same section name under another area is allowed');
check(!S().createZone({ governorateId: '', cityId: '', parentId: sec1Area.id, name: 'فرعي', aliases: [] }).ok, 'no section inside a section');
check(areaLabel(sec1Area, S().areas) === 'ضاحية الاختبار › الحي الشرقي', 'sections are named with their parent');
check(S().setMerchantAreaPrice(mid, sec1Area.id, 1300).ok && S().setMerchantCoverage(mid, [sec1Area.id], true).ok && resolveZoneFee(S(), mid, sec1Area.id).kind === 'ok', 'a section is its own priced destination');
check(resolveZoneFee(S(), mid, parentId).kind !== 'ok', 'no price is inherited from section to parent or back');
S().setServiceAreaStatus(parentId, false);
check(!isDestinationActive(S().areas.find((a) => a.id === sec1Area.id)!, S().areas) && resolveZoneFee(S(), mid, sec1Area.id).kind === 'zone_unavailable', 'stopping an area stops its sections');
S().setServiceAreaStatus(parentId, true);
const imported = S().importAreas({ governorateId: 'amman', cityId: 'amman', lines: 'ضاحية الاختبار / الحي الشمالي\nحي مستورد\nحي مستورد' });
check(imported.ok && imported.value.created === 2 && imported.value.skipped === 2, 'import creates new names and skips existing ones');
check(!S().importAreas({ governorateId: 'amman', cityId: 'irbid', lines: 'x' }).ok, 'import needs a city of the governorate');

section('Merchant coverage (CR v1.4 §2)');
const covTarget = S().createMerchant({ ...base, category: 'cafe', phone: '0790000555', username: 'covtarget' });
const cid = covTarget.ok ? covTarget.value : '';
const activeIds = S().areas.filter((a) => isDestinationActive(a, S().areas)).map((a) => a.id);
check(S().setMerchantCoverage(cid, activeIds, true).ok && S().coverage.filter((c) => c.merchantId === cid).length === activeIds.length, 'select all covers every active destination');
check(merchantZoneOptions(S(), cid).length === 0, 'covered but unpriced → still not orderable (no invented fee)');
check(S().setMerchantCoverage(cid, activeIds, true).ok && S().coverage.filter((c) => c.merchantId === cid).length === activeIds.length, 'selecting again adds no duplicates');
S().setServiceAreaStatus('a-abdoun', false);
check(!S().setMerchantCoverage(cid, ['a-abdoun'], true).ok, 'a stopped destination cannot be newly enabled');
S().setServiceAreaStatus('a-abdoun', true);
const later = S().createZone({ governorateId: 'amman', cityId: 'amman', name: 'منطقة جديدة لاحقاً', aliases: [] });
check(later.ok && !S().coverage.some((c) => c.merchantId === cid && c.areaId === later.value), 'areas added later are not auto-covered');
check(S().setMerchantCoverage(cid, activeIds, false).ok && S().coverage.every((c) => c.merchantId !== cid), 'clear all removes coverage only');

section('Commission as a percentage of the delivery fee (CR v1.4 §3)');
check(commissionFils(1000, 2000) === 200 && commissionFils(1500, 2000) === 300 && commissionFils(2000, 2000) === 400 && commissionFils(750, 2000) === 150, '20%: 1.000→0.200, 1.500→0.300, 2.000→0.400, 0.750→0.150');
check(commissionFils(1000, 1500) === 150, '15%: 1.000 → 0.150');
check(commissionFils(3, 2000) === 1 && commissionFils(2, 2000) === 0 && commissionFils(1, 5000) === 1, 'fractional fils round half up (0.6→1, 0.4→0, 0.5→1)');
check(commissionFils(1250, 1250) === 156, '12.5% of 1.250 = 156.25 → 156 fils');
check(isValidCommissionBp(0) && isValidCommissionBp(10000) && !isValidCommissionBp(10001) && !isValidCommissionBp(-1) && !isValidCommissionBp(12.5), 'rate limited to 0–100% in whole basis points');
let threw = false;
try { commissionFils(1.5, 2000); } catch { threw = true; }
check(threw, 'a non-integer fee is refused, never floated');

section('Scheduled requests are Admin-only (CR v1.4 §6)');
const T = Date.now();
const offersOf = (id: string) => S().offers.filter((x) => x.orderId === id);
check(!S().createOrder(mid, { areaId: 'a-khalda', requestType: 'scheduled' }).ok, 'scheduled needs a pickup time');
check(!S().createOrder(mid, { areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: T - 60_000 }).ok, 'a past pickup time is rejected');
const sch = S().createOrder(mid, { areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: T + 3 * 3_600_000 });
const schId = sch.ok ? sch.value.id : '';
const schOrder = () => S().orders.find((x) => x.id === schId)!;
check(sch.ok && schOrder().status === 'pending_dispatch' && schOrder().requestType === 'scheduled' && !!schOrder().queueReason, 'scheduled order waits in the Admin queue');
check(offersOf(schId).length === 0, 'no public offer is made for it');
S().tick(T + 10 * 3_600_000);
check(offersOf(schId).length === 0 && schOrder().status === 'pending_dispatch', 'still no offers after its time passes (no auto release)');
check(!S().dispatchPublic(schId).ok && offersOf(schId).length === 0, 'Admin cannot publish it to everyone');
check(!isAutoDispatchEligible(schOrder()) && isAutoDispatchEligible({}), 'eligibility rule: scheduled no, immediate/legacy yes');
const freeCaptain = S().captains.find((c) => captainEligibility(S(), c).eligible)!;
check(S().assignPrivate(schId, freeCaptain.id).ok && schOrder().status === 'offered_privately', 'Admin assigns it privately');
const privOffer = offersOf(schId).find((x) => x.status === 'pending')!;
S().rejectOffer(privOffer.id, freeCaptain.id);
check(schOrder().status === 'pending_dispatch' && schOrder().requestType === 'scheduled' && offersOf(schId).every((x) => x.mode === 'private'), 'a declined private offer returns it to the manual queue, never to broadcast');
const imm = S().createOrder(mid, { areaId: 'a-khalda' });
check(imm.ok && S().orders.find((x) => x.id === imm.value.id)!.requestType === 'immediate' && offersOf(imm.value.id).some((x) => x.mode === 'public'), 'immediate orders keep automatic dispatch');
S().cancelOrder(schId, 'تنظيف');
if (imm.ok) S().cancelOrder(imm.value.id, 'تنظيف');

section('Amman business time (CR v1.4 §6–7)');
check(ammanWallTimeToEpoch('2026-11-09', '10:00') === Date.UTC(2026, 10, 9, 7, 0), 'Amman 10:00 = 07:00 UTC');
check(ammanWallTimeToEpoch('2026-02-31', '10:00') === null && ammanWallTimeToEpoch('2026-11-09', '25:00') === null, 'impossible dates/times rejected');
const lateUtc = Date.UTC(2026, 10, 9, 22, 30); // 01:30 on the 10th in Amman
check(ammanDayKey(lateUtc) === '2026-11-10', 'calendar day follows Amman, not UTC');
check(JSON.stringify(lastThreeAmmanDays(lateUtc)) === JSON.stringify(['2026-11-10', '2026-11-09', '2026-11-08']), 'today, yesterday, day before (calendar days, not 72 hours)');
check(JSON.stringify(lastThreeAmmanDays(Date.UTC(2026, 2, 1, 12))) === JSON.stringify(['2026-03-01', '2026-02-28', '2026-02-27']), 'crosses a month boundary correctly');

section('Admin overview and merchant dashboard (application/dashboard.ts)');
{
  const now = Date.now();
  const st = S();
  const ops = operationalKpis(st.orders, now);
  check(ops.queue + ops.offered + ops.activeDeliveries <= st.orders.length, 'KPI groups never exceed the order count');
  check(ops.activeDeliveries === st.orders.filter((o) => ['accepted', 'heading_to_pickup', 'picked_up', 'on_the_way'].includes(o.status)).length, 'active deliveries KPI uses the delivery stages');
  const snaps = [
    { opStatus: 'available' as const, eligible: true, freshness: 'demo' as const },
    { opStatus: 'busy' as const, eligible: false, freshness: 'stale' as const },
    { opStatus: 'offline' as const, eligible: false, freshness: 'none' as const },
    { opStatus: 'inactive' as const, eligible: false, freshness: 'none' as const },
  ];
  const plat = platformKpis({ merchantCount: 6, captains: snaps });
  check(plat.availableNow === 1 && plat.activeCaptainAccounts === 3 && plat.captains === 4, 'available captains counted out of active accounts only');
  const sum = availabilitySummary(snaps);
  check(sum.available === 1 && sum.busy === 1 && sum.offline === 1 && sum.inactive === 1, 'availability summary uses real op statuses');
  const act = orderActivity(st.orders, now);
  check(act.length === ACTIVITY_DAYS && act[act.length - 1].dayKey === ammanDayKey(now), 'activity covers 7 Amman days ending today');
  check(act.reduce((n, d) => n + d.created, 0) === st.orders.filter((o) => act.some((d) => d.dayKey === ammanDayKey(o.createdAt))).length, 'activity counts only real orders in the window');
  const pending = st.orders.find((o) => o.status === 'pending_dispatch');
  const alertsOff = operationalAlerts({ orders: st.orders, merchantCount: 6, captains: snaps, publicBroadcast: false });
  check(alertsOff.some((a) => a.id === 'broadcast-off' && a.to === '/admin/dispatch'), 'broadcast paused raises an actionable alert');
  check(alertsOff.some((a) => a.id === 'gps'), 'busy captain with stale location raises a GPS alert');
  const alertsCalm = operationalAlerts({ orders: [], merchantCount: 0, captains: [], publicBroadcast: true });
  check(alertsCalm.length === 0, 'no invented alerts when nothing needs attention');
  check(!pending || alertsOff.some((a) => a.id === 'queue'), 'waiting orders raise a queue alert');
  const ov = merchantOrderOverview(st.orders, 'm-sanabel');
  check(ov.active.concat(ov.history).every((o) => o.merchantId === 'm-sanabel'), 'merchant overview is isolated to one merchant');
  check(ov.history.every((o) => o.status === 'delivered' || o.status === 'cancelled') && ov.active.every((o) => o.status !== 'delivered' && o.status !== 'cancelled'), 'active vs finished split');
  check(MERCHANT_RECENT_PREVIEW === 3 && ov.history.slice(0, MERCHANT_RECENT_PREVIEW).length <= 3, 'dashboard preview shows at most three orders');
}

finish();
