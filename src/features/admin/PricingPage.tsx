import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Tags } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { MerchantAreaPrice, ServiceArea } from '@/domain/types';
import { filsToJod, formatMoney, parseJodInput } from '@/domain/money';
import { Badge, Button, Card, CardHeader, EmptyState, Field, Input, PageHeader, Select, Toggle } from '@/shared/components/ui';
import { reportResult, toast } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';

/** Merchant ID + Service Area ID → Delivery Price (SRS §7.3). */
export function PricingPage() {
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const [params, setParams] = useSearchParams();
  const merchantId = params.get('merchant') ?? merchants[0]?.id ?? '';
  const merchant = merchants.find((m) => m.id === merchantId);

  const merchantPrices = prices.filter((p) => p.merchantId === merchantId);

  return (
    <>
      <PageHeader
        title="أسعار التجار حسب المنطقة"
        description="لكل تاجر سعر توصيل مستقل لكل منطقة خدمة. تغيير السعر يؤثر على الطلبات الجديدة فقط — الطلبات القائمة تحتفظ بلقطة السعر."
      />
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

      {!merchant ? (
        <Card><EmptyState icon={<Tags className="h-6 w-6" />} title="لا يوجد تجار" /></Card>
      ) : (
        <Card>
          <CardHeader
            title={merchant.businessName}
            description={`${merchantPrices.length} من ${areas.length} منطقة مسعّرة. المنطقة غير المسعّرة تمنع الطلب برسالة واضحة للتاجر.`}
          />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="bg-cream text-xs text-ink-muted">
                <tr>
                  {['المنطقة', 'السعر الحالي', 'سعر جديد (د.أ)', 'السعر مفعّل', 'آخر تحديث'].map((h) => (
                    <th key={h} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-cream-dark">
                {areas.map((a) => (
                  <PriceRow key={`${merchantId}-${a.id}`} merchantId={merchantId} area={a} price={merchantPrices.find((p) => p.areaId === a.id)} />
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </>
  );
}

function PriceRow({ merchantId, area, price }: { merchantId: string; area: ServiceArea; price?: MerchantAreaPrice }) {
  const setMerchantAreaPrice = useAppStore((s) => s.setMerchantAreaPrice);
  const setMerchantAreaPriceStatus = useAppStore((s) => s.setMerchantAreaPriceStatus);
  const [value, setValue] = useState(price ? String(filsToJod(price.price)) : '');
  useEffect(() => setValue(price ? String(filsToJod(price.price)) : ''), [price?.price]); // eslint-disable-line react-hooks/exhaustive-deps

  const dirty = value !== (price ? String(filsToJod(price.price)) : '');
  const save = () => {
    if (value.trim() === '') {
      reportResult(setMerchantAreaPrice(merchantId, area.id, null), 'تمت إزالة السعر');
      return;
    }
    const fils = parseJodInput(value);
    if (fils === null || fils <= 0) return toast.error('أدخل سعراً موجباً، مثل 1.75');
    reportResult(setMerchantAreaPrice(merchantId, area.id, fils), `تم حفظ سعر ${area.name}: ${formatMoney(fils)}`);
  };

  return (
    <tr className={area.status !== 'active' ? 'opacity-60' : undefined}>
      <td className="px-4 py-3 font-bold">
        {area.name}
        {area.status !== 'active' && <Badge className="ms-2">منطقة متوقفة</Badge>}
      </td>
      <td className="px-4 py-3">{price ? <span className="font-bold">{formatMoney(price.price)}</span> : <Badge tone="warning">غير مسعّر</Badge>}</td>
      <td className="px-4 py-3">
        <form
          className="flex gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            save();
          }}
        >
          <Input className="h-9 w-28" value={value} onChange={(e) => setValue(e.target.value)} inputMode="decimal" placeholder="—" aria-label={`سعر ${area.name}`} dir="ltr" />
          <Button size="sm" type="submit" variant={dirty ? 'primary' : 'outline'} disabled={!dirty}>حفظ</Button>
        </form>
      </td>
      <td className="px-4 py-3">
        {price ? (
          <Toggle checked={price.status === 'active'} onChange={(v) => reportResult(setMerchantAreaPriceStatus(merchantId, area.id, v), v ? 'تم تفعيل السعر' : 'تم إيقاف السعر')} label={<span className="sr-only">تفعيل السعر</span>} />
        ) : (
          <span className="text-xs text-ink-muted">—</span>
        )}
      </td>
      <td className="px-4 py-3 text-xs text-ink-muted">{price ? formatDateTime(price.updatedAt) : '—'}</td>
    </tr>
  );
}
