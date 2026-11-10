import { useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle2, CheckSquare, Pencil, Plus, XSquare } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions, resolveZoneFee } from '@/application/queries';
import type { Merchant, ServiceArea } from '@/domain/types';
import { areaLabel, childrenOf, isDestinationActive, topLevelAreas } from '@/domain/regions';
import { cityName } from '@/domain/cities';
import { formatMoney } from '@/domain/money';
import { Badge, Button, Card, ConfirmDialog, DataTable, EmptyState, IconAction, RowActions, SearchField } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { FeeDialog, type Editing } from './FeeDialog';

type Bulk = 'select' | 'clear' | null;

const HEADERS = ['مفعّلة للتاجر', 'المنطقة', 'رسوم التوصيل', 'الحالة', 'آخر تعديل للسعر'];
const LEGEND = [
  { icon: <Plus />, label: 'إضافة سعر لمنطقة بلا سعر' },
  { icon: <Pencil />, label: 'تعديل السعر أو إيقافه' },
];

/**
 * A Merchant's coverage and prices (CR v1.4 §2). Coverage (served or not) and price are
 * separate: a destination is orderable only when it is active, covered AND priced.
 * «تحديد جميع المناطق» always means every active destination in the catalogue, not the search results.
 */
export function MerchantAreaPriceTable({ merchant }: { merchant: Merchant }) {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const setCoverage = useAppStore((s) => s.setMerchantCoverage);
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Editing | null>(null);
  const [bulk, setBulk] = useState<Bulk>(null);

  const data = { areas, prices, coverage };
  const orderable = merchantZoneOptions(data, merchant.id);
  const covered = new Set(coverage.filter((c) => c.merchantId === merchant.id).map((c) => c.areaId));
  const activeIds = areas.filter((a) => isDestinationActive(a, areas)).map((a) => a.id);
  const toEnable = activeIds.filter((id) => !covered.has(id));
  const coveredUnpriced = [...covered].filter((id) => resolveZoneFee(data, merchant.id, id).kind === 'no_price').length;

  // Areas in name order, each followed by its sections.
  const needle = q.trim().toLowerCase();
  const rows = useMemo(() => {
    const ordered = topLevelAreas(areas)
      .sort((a, b) => a.name.localeCompare(b.name, 'ar'))
      .flatMap((root) => [root, ...childrenOf(areas, root.id)]);
    return ordered.filter((a) => !needle || [a.name, ...a.aliases, areaLabel(a, areas)].some((n) => n.toLowerCase().includes(needle)));
  }, [areas, needle]);

  const toggleOne = (area: ServiceArea, enabled: boolean) => reportResult(setCoverage(merchant.id, [area.id], enabled), enabled ? `فُعّلت «${area.name}» للتاجر` : `أُلغي تفعيل «${area.name}»`);
  const applyBulk = () => {
    if (bulk === 'select') reportResult(setCoverage(merchant.id, toEnable, true), `تم التفعيل — عدد المناطق: ${toEnable.length}`);
    if (bulk === 'clear') reportResult(setCoverage(merchant.id, [...covered], false), 'أُلغي تفعيل جميع المناطق للتاجر');
  };

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-3">
        <Card className="flex items-center gap-3 p-4">
          {orderable.length > 0 ? <CheckCircle2 className="h-6 w-6 text-secondary" /> : <AlertTriangle className="h-6 w-6 text-red-700" />}
          <div>
            <p className="text-xs text-ink-muted">متاحة للطلب</p>
            <p className="font-bold">{orderable.length > 0 ? `${orderable.length} منطقة مفعّلة ومسعّرة` : 'لا شيء — لا يستطيع التاجر إنشاء طلبات'}</p>
          </div>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-ink-muted">مفعّلة للتاجر</p>
          <p className="text-2xl font-extrabold">{covered.size} <span className="text-sm font-medium text-ink-muted">من {activeIds.length} نشطة</span></p>
        </Card>
        <Card className={cn('p-4', coveredUnpriced > 0 && 'ring-1 ring-amber-300')}>
          <p className="text-xs text-ink-muted">مفعّلة بلا سعر</p>
          <p className="text-2xl font-extrabold">{coveredUnpriced}</p>
          <p className="text-xs text-ink-muted">لا تظهر للتاجر حتى تحدد لها سعراً.</p>
        </Card>
      </div>

      <Card className="overflow-hidden">
        <div className="flex flex-wrap items-center gap-3 border-b border-cream-dark p-4">
          <SearchField label="بحث في المناطق" className="min-w-[200px] max-w-sm flex-1" placeholder="ابحث عن منطقة أو قسم" value={q} onChange={(e) => setQ(e.target.value)} />
          <div className="flex flex-wrap items-center gap-2">
            <Button variant="outline" icon={<CheckSquare className="h-4 w-4" />} disabled={toEnable.length === 0} onClick={() => setBulk('select')}>
              تحديد جميع المناطق
            </Button>
            <Button variant="ghost" icon={<XSquare className="h-4 w-4" />} disabled={covered.size === 0} onClick={() => setBulk('clear')}>
              إلغاء تحديد الكل
            </Button>
          </div>
          <p className="w-full text-xs text-ink-muted">«تحديد جميع المناطق» يفعّل كل المناطق والأقسام النشطة في الكتالوج ({activeIds.length})، بغض النظر عن البحث. لا يضيف أي سعر.</p>
        </div>
        {rows.length === 0 ? (
          <EmptyState title="لا توجد مناطق مطابقة" description="أضف المناطق من صفحة «مناطق التوصيل»." />
        ) : (
          <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={820}>
                {rows.map((a) => {
                  const price = prices.find((p) => p.merchantId === merchant.id && p.areaId === a.id);
                  const active = isDestinationActive(a, areas);
                  const isCovered = covered.has(a.id);
                  const status = resolveZoneFee(data, merchant.id, a.id).kind;
                  return (
                    <tr key={a.id} className={cn(!active && 'opacity-70')}>
                      <td className="px-4 py-3">
                        <input
                          type="checkbox"
                          className="h-4 w-4 accent-[#8C2335]"
                          checked={isCovered}
                          disabled={!active && !isCovered}
                          onChange={(e) => toggleOne(a, e.target.checked)}
                          aria-label={`تفعيل ${areaLabel(a, areas)} للتاجر`}
                        />
                      </td>
                      <td className="px-4 py-3">
                        <p className={cn('font-bold', a.parentId && 'ps-4')}>{areaLabel(a, areas)}</p>
                        <p className={cn('text-xs text-ink-muted', a.parentId && 'ps-4')}>{cityName(a.cityId)}</p>
                      </td>
                      <td className="px-4 py-3 font-bold">{price ? formatMoney(price.price) : <span className="text-ink-muted">—</span>}</td>
                      <td className="px-4 py-3">
                        {status === 'ok' ? <Badge tone="success" dot>متاحة للطلب</Badge>
                          : status === 'zone_unavailable' ? <Badge tone="neutral">المنطقة متوقفة</Badge>
                          : status === 'not_covered' ? <Badge tone="neutral">غير مفعّلة</Badge>
                          : price ? <Badge tone="warning">السعر معطّل</Badge>
                          : <Badge tone="warning">مفعّلة — بلا سعر</Badge>}
                      </td>
                      <td className="px-4 py-3 text-xs text-ink-muted">{price ? `${formatDateTime(price.updatedAt)} · ${price.updatedBy}` : '—'}</td>
                      <RowActions>
                        {price ? (
                          <IconAction icon={<Pencil />} label={`تعديل سعر ${a.name}`} onClick={() => setEditing({ area: a, price })} />
                        ) : (
                          <IconAction icon={<Plus />} label={active ? `إضافة سعر ${a.name}` : 'المنطقة متوقفة'} tone="primary" disabled={!active} onClick={() => setEditing({ area: a })} />
                        )}
                      </RowActions>
                    </tr>
                  );
                })}
          </DataTable>
        )}
      </Card>

      <FeeDialog merchant={merchant} editing={editing} onClose={() => setEditing(null)} />
      <ConfirmDialog
        open={bulk !== null}
        onClose={() => setBulk(null)}
        onConfirm={applyBulk}
        title={bulk === 'select' ? `تفعيل جميع المناطق غير المفعّلة (${toEnable.length})؟` : 'إلغاء تفعيل جميع المناطق؟'}
        description={
          bulk === 'select'
            ? `سيُفعَّل كل ما هو نشط في الكتالوج وغير مفعّل بعد (${toEnable.length}). المناطق بلا سعر لن تظهر للتاجر حتى تحدد سعرها. المناطق التي تُضاف لاحقاً لا تُفعَّل تلقائياً.`
            : `سيُلغى تفعيل جميع المناطق (${covered.size})، فلن يستطيع التاجر الطلب إليها. الأسعار تبقى محفوظة والطلبات السابقة لا تتأثر.`
        }
        confirmLabel={bulk === 'select' ? 'تفعيل الكل' : 'إلغاء التفعيل'}
        variant={bulk === 'select' ? 'secondary' : 'danger'}
      />
    </div>
  );
}
