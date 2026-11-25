import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Marker, Tooltip } from 'react-leaflet';
import { useAppStore } from '@/app/state';
import { useCaptainViews, useNow, OP_STATUS_LABEL, type CaptainView } from '@/shared/hooks/application';
import { isPinnedOnLiveMap } from '@/domain/location';
import { Card, OpenDecision, PageHeader, SimTag, SearchField } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { MapLegend } from '@/shared/components/map/MapLegend';
import { captainIcon } from '@/shared/components/map/markers';
import { formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { LiveMapStats } from './LiveMapStats';
import { CaptainDetailsPanel } from './CaptainDetailsPanel';

type Filter = 'all' | 'available' | 'delivering' | 'stale';

const FILTERS: Array<[Filter, string]> = [
  ['all', 'الكل'],
  ['available', OP_STATUS_LABEL.available],
  ['delivering', OP_STATUS_LABEL.busy],
  ['stale', 'GPS متأخر'],
];

/** Listed beside the map: pinned Captains plus delivering ones whose GPS stopped. Offline/suspended never. */
const isListed = (v: CaptainView) => v.presence !== 'hidden';
const matches = (v: CaptainView, f: Filter) =>
  f === 'all' ? isListed(v) : f === 'stale' ? v.presence === 'delivering_stale' : f === 'delivering' ? v.presence === 'delivering' || v.presence === 'delivering_stale' : v.presence === f;

/**
 * Captain operations map (owner, 2026-11-25): only Available Captains with a recent location report
 * and Captains on an active delivery with live GPS are pins (`liveMapPresence`). A delivering
 * Captain whose GPS stopped is listed, not pinned. Offline and suspended Captains are not shown.
 * Admin-only route; customer destinations are never drawn here.
 */
export function LiveMapPage() {
  const now = useNow(1000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');
  const [params] = useSearchParams();
  // «فتح الموقع على الخريطة» from the Captains table preselects that Captain (?captain=id).
  const [selectedId, setSelectedId] = useState<string | null>(() => params.get('captain'));

  const needle = q.trim();
  const listed = useMemo(() => views.filter((v) => matches(v, filter) && (!needle || v.captain.fullName.includes(needle))), [views, filter, needle]);
  const onMap = listed.filter((v) => isPinnedOnLiveMap(v.presence) && v.captain.lastLocation);
  const selected = views.find((v) => v.captain.id === selectedId && isListed(v)) ?? null;
  // Centre once on a Captain opened from the Captains table; later selections don't move the map.
  const [initialCenter] = useState(() => views.find((v) => v.captain.id === params.get('captain') && isPinnedOnLiveMap(v.presence))?.captain.lastLocation?.position);
  const orderOf = (v: CaptainView) => orders.find((o) => o.id === v.activeOrderId);

  return (
    <>
      <PageHeader
        title="الخريطة الحية"
        description="الكباتن المتاحون والكباتن في توصيل نشط فقط. الكابتن المتاح يرسل موقعه كل 60 ثانية، ويختفي إذا انقطع تحديثه أكثر من 90 ثانية أو أصبح غير متاح."
        actions={<SimTag>جميع المواقع محاكاة</SimTag>}
      />

      <LiveMapStats views={views} orders={orders} now={now} />

      <div className="grid gap-4 xl:grid-cols-[minmax(0,1fr)_340px]">
        <div className="relative self-start">
          <BaseMap className="h-[clamp(260px,55dvh,620px)]" zoom={13} center={initialCenter} label="خريطة الكباتن">
            {onMap.map((v) => {
              const loc = v.captain.lastLocation!;
              return (
                <Marker
                  key={v.captain.id}
                  position={[loc.position.lat, loc.position.lng]}
                  icon={captainIcon(v.opStatus, v.freshness, selectedId === v.captain.id)}
                  zIndexOffset={v.opStatus === 'busy' ? 500 : 0}
                  eventHandlers={{ click: () => setSelectedId(v.captain.id) }}
                  keyboard
                  title={v.captain.fullName}
                >
                  <Tooltip direction="top" offset={[0, -18]}>{v.captain.fullName} — {OP_STATUS_LABEL[v.opStatus]}</Tooltip>
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
            <SearchField label="بحث عن كابتن" placeholder="ابحث باسم الكابتن" value={q} onChange={(e) => setQ(e.target.value)} />
            <div className="flex flex-wrap gap-1.5" role="group" aria-label="تصفية الكباتن حسب الحالة">
              {FILTERS.map(([f, label]) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  aria-pressed={filter === f}
                  className={cn('inline-flex h-8 items-center rounded-full px-3 text-xs font-bold ring-1 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300', filter === f ? 'bg-primary text-white ring-primary' : 'bg-white text-ink-soft ring-cream-deep hover:bg-cream')}
                >
                  {label} ({views.filter((v) => matches(v, f)).length})
                </button>
              ))}
            </div>
          </Card>

          <Card className="max-h-[48vh] overflow-y-auto">
            <ul className="divide-y divide-cream-dark">
              {listed.map((v) => {
                const order = orderOf(v);
                return (
                  <li key={v.captain.id}>
                    <button onClick={() => setSelectedId(v.captain.id)} className={cn('w-full space-y-1.5 px-4 py-3 text-start hover:bg-cream', selectedId === v.captain.id && 'bg-primary-50')}>
                      <div className="flex items-center justify-between gap-2">
                        <span className="font-bold">{v.captain.fullName}</span>
                        <CaptainStatusBadge status={v.opStatus} />
                      </div>
                      <div className="flex flex-wrap items-center gap-2">
                        <FreshnessBadge freshness={v.freshness} />
                        {v.captain.lastLocation && <span className="text-xs text-ink-muted">آخر تحديث {formatRelative(v.captain.lastLocation.recordedAt, now)}</span>}
                      </div>
                      {v.presence === 'delivering_stale' && <p className="text-xs font-medium text-amber-800">لا يظهر على الخريطة حتى يعود تحديث الموقع</p>}
                      {order && (
                        <div className="flex flex-wrap items-center gap-2 text-xs text-ink-soft">
                          <span dir="ltr" className="font-mono font-bold">{order.reference}</span>
                          <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
                        </div>
                      )}
                    </button>
                  </li>
                );
              })}
              {listed.length === 0 && <li className="p-6 text-center text-sm text-ink-muted">لا يوجد كباتن متاحون أو في توصيل حالياً</li>}
            </ul>
          </Card>
          <OpenDecision id="تكامل">إرسال الموقع كل 60 ثانية يتم من تطبيق الكابتن عبر الخادم؛ هنا محاكاة داخل المتصفح. الخريطة تعرض ما يصلها فقط ولا تولّد مواقع.</OpenDecision>
          <div className="md:hidden">
            <MapLegend />
          </div>
        </div>
      </div>

      <CaptainDetailsPanel view={selected} now={now} onClose={() => setSelectedId(null)} />
    </>
  );
}
