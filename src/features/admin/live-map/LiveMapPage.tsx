import { useMemo, useState } from 'react';
import { Marker, Tooltip } from 'react-leaflet';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow, OP_STATUS_LABEL, type CaptainView } from '@/application/hooks';
import { Card, OpenDecision, PageHeader, SimTag, SearchField } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { MapLegend } from '@/shared/components/map/MapLegend';
import { captainIcon } from '@/shared/components/map/markers';
import { formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { LiveMapStats } from './LiveMapStats';
import { CaptainDetailsPanel } from './CaptainDetailsPanel';

type Filter = 'all' | 'online' | CaptainView['opStatus'] | 'stale';

const FILTERS: Array<[Filter, string]> = [
  ['all', 'الكل'],
  ['online', 'المتصلون'],
  ['busy', OP_STATUS_LABEL.busy],
  ['available', OP_STATUS_LABEL.available],
  ['stale', 'GPS متأخر'],
  ['offline', OP_STATUS_LABEL.offline],
];

const matches = (v: CaptainView, f: Filter) =>
  f === 'all' ? true : f === 'online' ? v.opStatus === 'available' || v.opStatus === 'busy' : f === 'stale' ? v.freshness === 'stale' : v.opStatus === f;

/** Captain-focused operations map (FU-1.2 §6): Captain markers only, counts, and a details panel. */
export function LiveMapPage() {
  const now = useNow(1000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const [filter, setFilter] = useState<Filter>('all');
  const [q, setQ] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const needle = q.trim();
  const listed = useMemo(() => views.filter((v) => matches(v, filter) && (!needle || v.captain.fullName.includes(needle))), [views, filter, needle]);
  const onMap = listed.filter((v) => v.captain.lastLocation);
  const selected = views.find((v) => v.captain.id === selectedId) ?? null;
  const orderOf = (v: CaptainView) => orders.find((o) => o.id === v.activeOrderId);

  return (
    <>
      <PageHeader
        title="الخريطة الحية"
        description="مواقع الكباتن وحالة توصيلاتهم. يُتتبع موقع الكابتن أثناء التوصيل النشط فقط؛ مواقع الكباتن الآخرين تجريبية أو آخر موقع معروف ولا تُعرض كمباشرة."
        actions={<SimTag>جميع المواقع محاكاة</SimTag>}
      />

      <LiveMapStats views={views} />

      <div className="grid gap-4 xl:grid-cols-[1fr_340px]">
        <div className="relative self-start">
          <BaseMap className="h-[64vh] min-h-[460px]" zoom={13} label="خريطة الكباتن">
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
                  className={cn('rounded-full px-3 py-1 text-xs font-bold ring-1', filter === f ? 'bg-primary text-white ring-primary' : 'bg-white text-ink-soft ring-cream-deep hover:bg-cream')}
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
                        {v.captain.lastLocation && <span className="text-xs text-ink-muted">{formatRelative(v.captain.lastLocation.recordedAt, now)}</span>}
                      </div>
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
              {listed.length === 0 && <li className="p-6 text-center text-sm text-ink-muted">لا يوجد كباتن مطابقون</li>}
            </ul>
          </Card>
          <OpenDecision id="O-001">طريقة الحصول على موقع الكابتن قبل الرحلة غير محددة؛ لا يُعرض أي كابتن خامل كمتتبَّع بشكل مباشر.</OpenDecision>
          <div className="md:hidden">
            <MapLegend />
          </div>
        </div>
      </div>

      <CaptainDetailsPanel view={selected} now={now} onClose={() => setSelectedId(null)} />
    </>
  );
}
