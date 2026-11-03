import { useSearchParams } from 'react-router-dom';
import { Tags } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Card, EmptyState, Field, PageHeader, Select } from '@/shared/components/ui';
import { MerchantZonePricing } from './MerchantZonePricing';

/** Quick access to any Merchant's zone pricing (Merchant ID + Zone ID → fee). */
export function PricingPage() {
  const merchants = useAppStore((s) => s.merchants);
  const [params, setParams] = useSearchParams();
  const merchantId = params.get('merchant') ?? merchants[0]?.id ?? '';
  const merchant = merchants.find((m) => m.id === merchantId);

  return (
    <>
      <PageHeader title="أسعار التجار حسب المنطقة" description="لكل تاجر جدول رسوم مستقل. رسوم المنطقة لا يلزم أن تكون نفسها لكل التجار." />
      <Card className="mb-4 p-4">
        <Field label="التاجر" htmlFor="pricing-merchant" className="max-w-sm">
          <Select id="pricing-merchant" value={merchantId} onChange={(e) => setParams({ merchant: e.target.value })}>
            {merchants.map((m) => (
              <option key={m.id} value={m.id}>
                {m.businessName}
                {m.status !== 'active' ? ' (غير مفعّل)' : ''}
              </option>
            ))}
          </Select>
        </Field>
      </Card>
      {merchant ? <MerchantZonePricing merchant={merchant} /> : <Card><EmptyState icon={<Tags className="h-6 w-6" />} title="لا يوجد تجار" /></Card>}
    </>
  );
}
