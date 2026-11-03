import './setup';
import { useAppStore, captainEligibility } from '@/application/store';
import { merchantZoneOptions, resolveLocationFee } from '@/application/queries';
import { polygonCentroid } from '@/domain/geo';
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
const base = { businessName: 'x', contactName: 'y', phone: '0790000888', address: 'z', pickup: { lat: 32, lng: 35.9 }, password: 'secret1' };
check(!S().createMerchant({ ...base, category: null, username: 'nocat' }).ok, 'merchant without category rejected');
check(!S().createMerchant({ ...base, category: 'shoes' as any, username: 'badcat' }).ok, 'category outside taxonomy rejected');
check(S().merchants.find((m) => m.id === 'm-yasmine')!.category === null, 'legacy merchant stays uncategorised (not defaulted)');
const y = S().merchants.find((m) => m.id === 'm-yasmine')!;
const { id: _i, createdAt: _c, status: _s, ...yIn } = y;
check(!S().updateMerchant(y.id, yIn).ok, 'editing uncategorised merchant requires a category');
check(S().updateMerchant(y.id, { ...yIn, category: 'bakery' }).ok && S().merchants.find((m) => m.id === y.id)!.category === 'bakery', 'Admin sets category on edit');

section('Zone pricing setup (Spec §13)');
const created = S().createMerchant({ businessName: 'مطعم الجبيهة', category: 'restaurant', contactName: 'سامي', phone: '0790000999', address: 'الجبيهة', pickup: { lat: 32.02, lng: 35.87 }, username: 'jubeiha', password: 'secret1' });
check(created.ok, 'Admin registers new merchant');
const mid = created.ok ? created.value : '';
check(merchantZoneOptions(S(), mid).length === 0, 'new merchant has no zones yet');
check(!S().createOrder(mid, { customerPhone: PHONE, location: at('a-khalda'), addressDescription: 'x' }).ok, 'order blocked without zones');
check(S().setMerchantAreaPrice(mid, 'a-jubaiha', 1000).ok, 'add Jubeiha 1.00');
check(S().setMerchantAreaPrice(mid, 'a-tla', 1500).ok, "add Tla' Al-Ali 1.50");
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2000).ok, 'add Khalda 2.00');
check(!S().setMerchantAreaPrice(mid, 'a-abdoun', 0).ok, 'zero fee rejected');
check(S().prices.filter((p) => p.merchantId === mid && p.areaId === 'a-khalda').length === 1, 'no duplicate merchant-zone row');
check(merchantZoneOptions(S(), mid).length === 3, 'merchant selector shows 3 zones');
check(S().authenticate('jubeiha', 'secret1').ok, 'new merchant can log in');

section('Order creation from the customer pin');
const o1 = S().createOrder(mid, { customerPhone: PHONE, location: at('a-khalda'), addressDescription: 'خلف سيتي مول', expectedFee: 2000 });
check(o1.ok, 'order to Khalda from pin');
const order1 = S().orders.find((o) => o1.ok && o.id === o1.value.id)!;
check(order1.deliveryPrice === 2000 && order1.areaName === 'خلدا', 'order stores JOD 2.00');
check(!!order1.pricingSnapshotAt, 'pricing snapshot timestamp');
check(order1.destination.position?.lat === at('a-khalda').lat && !order1.destination.approximate, 'order stores the exact customer pin');
check(!S().createOrder(mid, { customerPhone: PHONE, location: { lat: 31.5, lng: 36.5 }, addressDescription: 'x' }).ok, 'pin outside every zone rejected');
check(resolveLocationFee(S(), mid, { lat: 31.5, lng: 36.5 }).kind === 'outside', 'resolveLocationFee → outside');
check(!S().createOrder(mid, { customerPhone: PHONE, location: { lat: NaN, lng: 0 }, addressDescription: 'x' }).ok, 'missing/invalid pin rejected');
const named = S().createOrder(mid, { customerPhone: PHONE, location: at('a-tla'), placeName: 'سيتي مول', addressDescription: 'بوابة 2' });
check(named.ok && S().orders.find((o) => o.id === named.value.id)!.destination.address.includes('سيتي مول'), 'searched place name kept on the order');

section('Fee lock and re-confirmation');
check(S().setMerchantAreaPrice(mid, 'a-khalda', 2500).ok, 'Admin changes Khalda to 2.50');
const stale = S().createOrder(mid, { customerPhone: PHONE, location: at('a-khalda'), addressDescription: 'x', expectedFee: 2000 });
check(!stale.ok && stale.code === 'fee_changed' && stale.currentFee === 2500, 'stale displayed fee → fee_changed with new fee');
const o2 = S().createOrder(mid, { customerPhone: PHONE, location: at('a-khalda'), addressDescription: 'x', expectedFee: 2500 });
check(o2.ok && S().orders.find((o) => o.id === o2.value.id)!.deliveryPrice === 2500, 'second order uses 2.50');
check(S().orders.find((o) => o.id === order1.id)!.deliveryPrice === 2000, 'first order still 2.00');

section('Request validation');
check(!S().createOrder(mid, { customerPhone: PHONE, location: at('a-abdoun'), addressDescription: 'x' }).ok, 'zone not enabled for merchant rejected');
check(!S().createOrder(mid, { customerPhone: '', location: at('a-khalda'), addressDescription: 'x' }).ok, 'customer phone required');
check(!S().createOrder(mid, { customerPhone: PHONE, location: at('a-khalda'), addressDescription: '  ' }).ok, 'address description required');
S().setMerchantAreaPriceStatus(mid, 'a-tla', false);
check(!merchantZoneOptions(S(), mid).some((z) => z.area.id === 'a-tla'), 'disabled zone hidden from merchant');
S().setServiceAreaStatus('a-jubaiha', false);
check(!S().createOrder(mid, { customerPhone: PHONE, location: at('a-jubaiha'), addressDescription: 'x' }).ok, 'central zone deactivated → rejected');
S().setServiceAreaStatus('a-jubaiha', true);

section('Zones');
check(!S().createZone({ name: 'خلدا', aliases: [] }).ok, 'duplicate zone name rejected');
check(!S().createZone({ name: 'منطقة', aliases: ['Khalda'] }).ok, 'duplicate via alias rejected');
check(S().createZone({ name: 'ضاحية الرشيد', aliases: ['Rashid'] }).ok, 'new central zone');

section('Dispatch, delivery and wallet');
const o = S().orders.find((x) => o2.ok && x.id === o2.value.id)!;
check(o.status === 'awaiting_captain', `public dispatch still works (${o.status})`);
const offer = S().offers.find((x) => x.orderId === o.id && x.status === 'pending')!;
check(!!offer, 'offer created');
check(S().acceptOffer(offer.id, offer.captainId).ok, 'captain accepts');
for (let i = 0; i < 4; i++) S().advanceDelivery(o.id, offer.captainId);
check(S().orders.find((x) => x.id === o.id)!.status === 'delivered', 'delivered');
check(!captainEligibility(S(), S().captains.find((c) => c.id === 'c-yazan')!).eligible, 'wallet eligibility intact');

finish();
