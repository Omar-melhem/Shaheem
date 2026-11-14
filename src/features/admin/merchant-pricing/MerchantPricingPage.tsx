import { useMemo, useState } from 'react';
import { RotateCcw, Tags } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { merchantZoneOptions, pricedAreaIds } from '@/application/queries';
import { areaLabel } from '@/domain/regions';
import { Button, Card, EmptyState, Field, Input, PageHeader, SearchField, Select } from '@/shared/components/ui';
import { MerchantPricingCard } from './MerchantPricingCard';

/** Whole, non-negative number from a filter box; empty or invalid means "no limit". */
const parseBound = (v: string): number | null => (/^\d+$/.test(v.trim()) ? Number(v.trim()) : null);

/**
 * Merchant Pricing landing (FU-1.2 §8.1): a card per Merchant; a card opens that Merchant's price list.
 * Filters (Master Prompt §16) combine: name, a destination the Merchant has a price for, and
 * how many distinct destinations are priced (min / max).
 */
export function MerchantPricingPage() {
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const [q, setQ] = useState('');
  const [areaId, setAreaId] = useState('');
  const [min, setMin] = useState('');
  const [max, setMax] = useState('');

  const areaOptions = useMemo(() => areas.map((a) => ({ id: a.id, label: areaLabel(a, areas) })).sort((a, b) => a.label.localeCompare(b.label, 'ar')), [areas]);
  const needle = q.trim();
  const lo = parseBound(min);
  const hi = parseBound(max);
  const rangeError = lo !== null && hi !== null && lo > hi ? 'الحد الأدنى أكبر من الحد الأعلى' : undefined;

  const visible = merchants.filter((m) => {
    if (needle && !m.businessName.includes(needle) && !m.address.includes(needle)) return false;
    const priced = pricedAreaIds({ prices }, m.id);
    if (areaId && !priced.has(areaId)) return false;
    if (lo !== null && priced.size < lo) return false;
    if (hi !== null && priced.size > hi) return false;
    return true;
  });
  const filtering = !!(needle || areaId || min || max);
  const reset = () => {
    setQ('');
    setAreaId('');
    setMin('');
    setMax('');
  };

  return (
    <>
      <PageHeader title="أسعار التجار حسب المنطقة" description="اختر تاجراً لعرض رسوم التوصيل الخاصة به لكل منطقة. لكل تاجر جدول رسوم مستقل." />
      <Card className="mb-4 flex flex-wrap items-end gap-3 p-4">
        <SearchField label="بحث عن تاجر" className="min-w-0 w-full sm:w-auto sm:min-w-[200px] max-w-sm flex-1" placeholder="ابحث باسم التاجر أو موقعه" value={q} onChange={(e) => setQ(e.target.value)} />
        <Field label="له سعر في منطقة" className="w-56">
          <Select aria-label="له سعر في منطقة" value={areaId} onChange={(e) => setAreaId(e.target.value)}>
            <option value="">كل المناطق</option>
            {areaOptions.map((a) => <option key={a.id} value={a.id}>{a.label}</option>)}
          </Select>
        </Field>
        <Field label="مناطق مسعّرة: من" className="w-36" error={rangeError}>
          <Input type="number" min={0} inputMode="numeric" dir="ltr" aria-label="أقل عدد مناطق مسعّرة" value={min} onChange={(e) => setMin(e.target.value)} placeholder="0" />
        </Field>
        <Field label="إلى" className="w-36">
          <Input type="number" min={0} inputMode="numeric" dir="ltr" aria-label="أعلى عدد مناطق مسعّرة" value={max} onChange={(e) => setMax(e.target.value)} placeholder="∞" />
        </Field>
        {filtering && <Button variant="ghost" icon={<RotateCcw className="h-4 w-4" />} onClick={reset}>مسح الفلاتر</Button>}
        <p className="ms-auto text-sm text-ink-muted" aria-live="polite">{visible.length} من {merchants.length} تاجر</p>
      </Card>
      {visible.length === 0 ? (
        <Card>
          <EmptyState icon={<Tags className="h-6 w-6" />} title={merchants.length === 0 ? 'لا يوجد تجار' : 'لا يوجد تجار مطابقون'} />
        </Card>
      ) : (
        <ul className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {visible.map((m) => (
            <li key={m.id}>
              <MerchantPricingCard merchant={m} activeZones={merchantZoneOptions({ areas, prices, coverage }, m.id).length} />
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
