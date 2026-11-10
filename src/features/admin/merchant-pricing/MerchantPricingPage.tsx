import { useState } from 'react';
import { Tags } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions } from '@/application/queries';
import { Card, EmptyState, PageHeader, SearchField } from '@/shared/components/ui';
import { MerchantPricingCard } from './MerchantPricingCard';

/** Merchant Pricing landing (FU-1.2 §8.1): a card per Merchant; a card opens that Merchant's price list. */
export function MerchantPricingPage() {
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const [q, setQ] = useState('');
  const needle = q.trim();
  const visible = merchants.filter((m) => !needle || m.businessName.includes(needle) || m.address.includes(needle));

  return (
    <>
      <PageHeader title="أسعار التجار حسب المنطقة" description="اختر تاجراً لعرض رسوم التوصيل الخاصة به لكل منطقة. لكل تاجر جدول رسوم مستقل." />
      <SearchField label="بحث عن تاجر" className="mb-4 max-w-sm" placeholder="ابحث باسم التاجر أو موقعه" value={q} onChange={(e) => setQ(e.target.value)} />
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
