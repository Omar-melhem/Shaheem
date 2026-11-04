import { useMemo, useState } from 'react';
import { Marker, Polygon, Polyline, Popup, Tooltip } from 'react-leaflet';
import { Search } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow, OP_STATUS_LABEL, type CaptainView } from '@/application/hooks';
import { isActiveDelivery } from '@/domain/orderStatus';
import { FRESHNESS_LABEL } from '@/domain/location';
import { formatMoney } from '@/domain/money';
import { Card, Input, OpenDecision, PageHeader, SimTag, Toggle } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { MapLegend } from '@/shared/components/map/MapLegend';
import { captainIcon, destinationIcon, merchantIcon } from '@/shared/components/map/markers';
import { formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

type Filter = 'all' | CaptainView['opStatus'] | 'stale';

export function LiveMapPage() {
  const now = useNow(1000);
  const views = useCaptainViews(now);
  const merchants = useAppStore((s) => s.merchants);
  const orders = useAppStore((s) => s.orders);
  const areas = useAppStore((s) => s.areas);
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');
  const [showAreas, setShowAreas] = useState(true);
  const [showMerchants, setShowMerchants] = useState(true);
  const [selected, setSelected] = useState<string | null>(null);

  const activeOrders = orders.filter((o) => isActiveDelivery(o.status));
  const needle = q.trim();
  const visibleCaptains = useMemo(
    () =>
      views
        .filter((v) => v.captain.lastLocation)
        .filter((v) => (filter === 'all' ? true : filter === 'stale' ? v.freshness === 'stale' : v.opStatus === filter))
        .filter((v) => !needle || v.captain.fullName.includes(needle)),
    [views, filter, needle],
  );
  const visibleMerchants = merchants.filter((m) => !needle || m.businessName.includes(needle));

  const counts: Record<Filter, number> = {
    all: views.length,
    available: views.filter((v) => v.opStatus === 'available').length,
    busy: views.filter((v) => v.opStatus === 'busy').length,
    offline: views.filter((v) => v.opStatus === 'offline').length,
    inactive: views.filter((v) => v.opStatus === 'inactive').length,
    stale: views.filter((v) => v.freshness === 'stale').length,
  };
  const filters: Array<[Filter, string]> = [
    ['all', 'الكل'],
    ['available', OP_STATUS_LABEL.available],
    ['busy', OP_STATUS_LABEL.busy],
    ['stale', 'GPS متأخر'],
    ['offline', OP_STATUS_LABEL.offline],
  ];

  return (
    <>
      <PageHeader
        title="الخريطة الحية"
        description="مواقع التجار والكباتن والتوصيلات النشطة. يُتتبع موقع الكابتن أثناء التوصيل النشط فقط؛ مواقع الكباتن الآخرين تجريبية أو آخر موقع معروف ولا تُعرض كمباشرة."
        actions={<SimTag>جميع المواقع محاكاة</SimTag>}
      />

      <div className="grid gap-4 xl:grid-cols-[1fr_340px]">
        <div className="relative self-start">
          <BaseMap className="h-[68vh] min-h-[480px]" zoom={13} label="خريطة العمليات الحية">
            {showAreas &&
              areas
                .filter((a) => a.status === 'active')
                .map((a) => (
                  <Polygon key={a.id} positions={a.polygon.map((p) => [p.lat, p.lng] as [number, number])} pathOptions={{ color: '#C8A98A', weight: 1.5, fillOpacity: 0.08 }}>
                    <Tooltip sticky>{a.name}</Tooltip>
                  </Polygon>
                ))}
            {showMerchants &&
              visibleMerchants.map((m) => (
                <Marker key={m.id} position={[m.pickup.lat, m.pickup.lng]} icon={merchantIcon(m.status !== 'active')}>
                  <Popup>
                    <b>{m.businessName}</b>
                    <br />
                    {m.address}
                    <br />
                    {m.status !== 'active' && <span style={{ color: '#b91c1c' }}>حساب غير مفعّل</span>}
                  </Popup>
                </Marker>
              ))}
            {activeOrders.map((o) => (
              <Marker key={o.id} position={[o.destination.position.lat, o.destination.position.lng]} icon={destinationIcon()}>
                <Popup>
                  <b dir="ltr">{o.reference}</b> — {o.destination.label}
                </Popup>
              </Marker>
            ))}
            {activeOrders.map((o) => {
              const v = views.find((x) => x.captain.id === o.captainId);
              const from = v?.captain.lastLocation?.position ?? o.pickup.position;
              const to = o.status === 'accepted' || o.status === 'heading_to_pickup' ? o.pickup.position : o.destination.position;
              return <Polyline key={`l-${o.id}`} positions={[[from.lat, from.lng], [to.lat, to.lng]]} pathOptions={{ color: '#8C2335', weight: 2, dashArray: '5 8' }} />;
            })}
            {visibleCaptains.map((v) => {
              const loc = v.captain.lastLocation!;
              const order = activeOrders.find((o) => o.id === v.activeOrderId);
              return (
                <Marker
                  key={v.captain.id}
                  position={[loc.position.lat, loc.position.lng]}
                  icon={captainIcon(v.opStatus, v.freshness, selected === v.captain.id)}
                  zIndexOffset={v.opStatus === 'busy' ? 500 : 0}
                  eventHandlers={{ click: () => setSelected(v.captain.id) }}
                >
                  <Popup>
                    <b>{v.captain.fullName}</b> — {OP_STATUS_LABEL[v.opStatus]}
                    <br />
                    {FRESHNESS_LABEL[v.freshness]} · آخر تحديث {formatRelative(loc.recordedAt, now)}
                    {order && (
                      <>
                        <br />
                        الطلب <span dir="ltr">{order.reference}</span>
                      </>
                    )}
                  </Popup>
                </Marker>
              );
            })}
          </BaseMap>
          <div className="pointer-events-none absolute bottom-3 left-3 z-[500] hidden md:block">
            <div className="pointer-events-auto">
              <MapLegend />
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <Card className="space-y-3 p-4">
            <div className="relative">
              <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted" />
              <Input className="ps-9" placeholder="ابحث عن كابتن أو تاجر" value={q} onChange={(e) => setQ(e.target.value)} aria-label="بحث في الخريطة" />
            </div>
            <div className="flex flex-wrap gap-1.5" role="group" aria-label="تصفية الكباتن حسب الحالة">
              {filters.map(([f, label]) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  aria-pressed={filter === f}
                  className={cn('rounded-full px-3 py-1 text-xs font-bold ring-1', filter === f ? 'bg-primary text-white ring-primary' : 'bg-white text-ink-soft ring-cream-deep hover:bg-cream')}
                >
                  {label} ({counts[f]})
                </button>
              ))}
            </div>
            <Toggle checked={showAreas} onChange={setShowAreas} label="إظهار مناطق الخدمة" />
            <Toggle checked={showMerchants} onChange={setShowMerchants} label="إظهار التجار" />
          </Card>

          <Card className="max-h-[48vh] overflow-y-auto">
            <ul className="divide-y divide-cream-dark">
              {visibleCaptains.map((v) => {
                const order = activeOrders.find((o) => o.id === v.activeOrderId);
                return (
                  <li key={v.captain.id}>
                    <button onClick={() => setSelected(v.captain.id)} className={cn('w-full space-y-1.5 px-4 py-3 text-start hover:bg-cream', selected === v.captain.id && 'bg-primary-50')}>
                      <div className="flex items-center justify-between gap-2">
                        <span className="font-bold">{v.captain.fullName}</span>
                        <CaptainStatusBadge status={v.opStatus} />
                      </div>
                      <div className="flex flex-wrap items-center gap-2">
                        <FreshnessBadge freshness={v.freshness} />
                        <span className="text-xs text-ink-muted">{formatRelative(v.captain.lastLocation!.recordedAt, now)}</span>
                      </div>
                      {order && (
                        <div className="flex flex-wrap items-center gap-2 text-xs text-ink-soft">
                          <span dir="ltr" className="font-mono font-bold">{order.reference}</span>
                          <OrderStatusBadge status={order.status} />
                          <span>{formatMoney(order.deliveryPrice)}</span>
                        </div>
                      )}
                    </button>
                  </li>
                );
              })}
              {visibleCaptains.length === 0 && <li className="p-6 text-center text-sm text-ink-muted">لا يوجد كباتن مطابقون</li>}
            </ul>
          </Card>
          <OpenDecision id="O-001">طريقة الحصول على موقع الكابتن قبل الرحلة غير محددة؛ لا يُعرض أي كابتن خامل كمتتبَّع بشكل مباشر.</OpenDecision>
          <div className="md:hidden">
            <MapLegend />
          </div>
        </div>
      </div>
    </>
  );
}
