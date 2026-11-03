import { useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle2, Pencil, Plus } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions } from '@/application/queries';
import type { Merchant, MerchantAreaPrice, ServiceArea } from '@/domain/types';
import { filsToJod, formatMoney, parseJodInput } from '@/domain/money';
import { Badge, Button, Card, Dialog, EmptyState, Field, Input, Toggle, SearchField } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';

type Editing = { area: ServiceArea; price?: MerchantAreaPrice };

/**
 * Merchant "Delivery Zones & Pricing" (Zone-Based Pricing Spec §5): central
 * zones, the Merchant's coverage, and a fixed fee per zone.
 */
export function MerchantZonePricing({ merchant }: { merchant: Merchant }) {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const orders = useAppStore((s) => s.orders);
  const setPriceStatus = useAppStore((s) => s.setMerchantAreaPriceStatus);
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Editing | null>(null);
  const [toggling, setToggling] = useState<{ area: ServiceArea; next: boolean } | null>(null);

  const merchantPrices = prices.filter((p) => p.merchantId === merchant.id);
  const enabled = merchantZoneOptions({ areas, prices }, merchant.id);
  const needle = q.trim();
  const rows = useMemo(
    () => areas.filter((a) => !needle || [a.name, ...a.aliases].some((n) => n.toLowerCase().includes(needle.toLowerCase()))),
    [areas, needle],
  );
  const notAdded = areas.filter((a) => a.status === 'active' && !merchantPrices.some((p) => p.areaId === a.id)).length;

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-3">
        <Card className="flex items-center gap-3 p-4">
          {enabled.length > 0 ? <CheckCircle2 className="h-6 w-6 text-secondary" /> : <AlertTriangle className="h-6 w-6 text-red-700" />}
          <div>
            <p className="text-xs text-ink-muted">حالة التسعير</p>
            <p className="font-bold">{enabled.length > 0 ? `جاهز — ${enabled.length} منطقة مفعّلة` : 'غير جاهز — لا يستطيع التاجر إنشاء طلبات'}</p>
          </div>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-ink-muted">مناطق غير مضافة لهذا التاجر</p>
          <p className="text-2xl font-extrabold">{notAdded}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-ink-muted">قاعدة التسعير</p>
          <p className="text-sm">رسوم ثابتة كاملة لكل منطقة. تغيير الرسوم لا يغيّر الطلبات السابقة.</p>
        </Card>
      </div>

      <Card className="overflow-hidden">
        <div className="border-b border-cream-dark p-4">
          <SearchField label="بحث في المناطق" className="max-w-sm" placeholder="ابحث عن منطقة" value={q} onChange={(e) => setQ(e.target.value)} />
        </div>
        {rows.length === 0 ? (
          <EmptyState title="لا توجد مناطق مطابقة" description="أضف المناطق من صفحة «مناطق التوصيل» المركزية." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-sm">
              <thead className="bg-cream text-xs text-ink-muted">
                <tr>
                  {['المنطقة', 'رسوم التوصيل', 'الحالة', 'مفعّلة للتاجر', 'آخر تعديل', 'إجراء'].map((h) => (
                    <th key={h} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-cream-dark">
                {rows.map((a) => {
                  const price = merchantPrices.find((p) => p.areaId === a.id);
                  const centralOff = a.status !== 'active';
                  return (
                    <tr key={a.id} className={!price ? 'bg-amber-50/40' : undefined}>
                      <td className="px-4 py-3">
                        <p className="font-bold">{a.name}</p>
                        {a.aliases.length > 0 && <p className="text-xs text-ink-muted">{a.aliases.join('، ')}</p>}
                      </td>
                      <td className="px-4 py-3 font-bold">{price ? formatMoney(price.price) : <span className="text-ink-muted">—</span>}</td>
                      <td className="px-4 py-3">
                        {centralOff ? (
                          <Badge tone="neutral">المنطقة المركزية متوقفة</Badge>
                        ) : !price ? (
                          <Badge tone="warning">غير مضافة</Badge>
                        ) : price.status === 'active' ? (
                          <Badge tone="success" dot>مفعّلة</Badge>
                        ) : (
                          <Badge tone="neutral" dot>معطّلة</Badge>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        {price ? (
                          <Toggle checked={price.status === 'active'} onChange={(next) => setToggling({ area: a, next })} label={<span className="sr-only">تفعيل {a.name}</span>} />
                        ) : (
                          <span className="text-xs text-ink-muted">—</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-xs text-ink-muted">{price ? `${formatDateTime(price.updatedAt)} · ${price.updatedBy}` : '—'}</td>
                      <td className="px-4 py-3">
                        {price ? (
                          <Button size="sm" variant="outline" icon={<Pencil className="h-3.5 w-3.5" />} onClick={() => setEditing({ area: a, price })}>تعديل</Button>
                        ) : (
                          <Button size="sm" icon={<Plus className="h-3.5 w-3.5" />} disabled={centralOff} onClick={() => setEditing({ area: a })}>إضافة</Button>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <FeeDialog merchant={merchant} editing={editing} onClose={() => setEditing(null)} />

      <Dialog
        open={!!toggling}
        onClose={() => setToggling(null)}
        size="sm"
        title={toggling?.next ? `تفعيل ${toggling?.area.name}؟` : `تعطيل ${toggling?.area.name}؟`}
        footer={
          <>
            <Button variant="outline" onClick={() => setToggling(null)}>تراجع</Button>
            <Button
              variant={toggling?.next ? 'secondary' : 'danger'}
              onClick={() => {
                if (toggling && reportResult(setPriceStatus(merchant.id, toggling.area.id, toggling.next), toggling.next ? 'تم تفعيل المنطقة للتاجر' : 'تم تعطيل المنطقة للتاجر')) setToggling(null);
              }}
            >
              {toggling?.next ? 'تفعيل' : 'تعطيل'}
            </Button>
          </>
        }
      >
        <p className="text-sm text-ink-soft">
          {toggling?.next
            ? 'ستظهر المنطقة في قائمة مناطق العميل لدى التاجر بالرسوم المحفوظة.'
            : `لن تظهر المنطقة للتاجر في الطلبات الجديدة. الطلبات القائمة لا تتأثر${toggling ? ` (${orders.filter((o) => o.merchantId === merchant.id && o.areaId === toggling.area.id).length} طلب سابق لهذه المنطقة)` : ''}.`}
        </p>
      </Dialog>
    </div>
  );
}

function FeeDialog({ merchant, editing, onClose }: { merchant: Merchant; editing: Editing | null; onClose: () => void }) {
  const setPrice = useAppStore((s) => s.setMerchantAreaPrice);
  const [value, setValue] = useState('');
  const [step, setStep] = useState<'form' | 'confirm'>('form');
  const [error, setError] = useState<string | null>(null);
  const [lastKey, setLastKey] = useState<string | null>(null);

  const key = editing ? `${editing.area.id}-${editing.price?.price ?? 'new'}` : null;
  if (key !== lastKey) {
    setLastKey(key);
    setValue(editing?.price ? String(filsToJod(editing.price.price)) : '');
    setStep('form');
    setError(null);
  }
  if (!editing) return null;
  const fils = parseJodInput(value);

  const review = () => {
    if (fils === null || fils <= 0) return setError('أدخل رسوماً صالحة أكبر من صفر، مثل 1.50');
    if (editing.price && fils === editing.price.price) return setError('الرسوم لم تتغير');
    setError(null);
    setStep('confirm');
  };
  const save = () => {
    if (fils === null) return;
    if (reportResult(setPrice(merchant.id, editing.area.id, fils), `تم حفظ رسوم ${editing.area.name}: ${formatMoney(fils)}`)) onClose();
  };

  return (
    <Dialog
      open
      onClose={onClose}
      size="sm"
      title={`${editing.price ? 'تعديل' : 'إضافة'} ${editing.area.name} — ${merchant.businessName}`}
      footer={
        step === 'form' ? (
          <>
            <Button variant="outline" onClick={onClose}>إلغاء</Button>
            <Button onClick={review}>متابعة</Button>
          </>
        ) : (
          <>
            <Button variant="outline" onClick={() => setStep('form')}>رجوع</Button>
            <Button variant="secondary" onClick={save}>تأكيد وحفظ</Button>
          </>
        )
      }
    >
      {step === 'form' ? (
        <Field label="رسوم التوصيل الكاملة (د.أ)" required error={error} hint="رسوم ثابتة لأي عنوان داخل هذه المنطقة لهذا التاجر.">
          <Input value={value} onChange={(e) => setValue(e.target.value)} inputMode="decimal" dir="ltr" placeholder="1.50" autoFocus onKeyDown={(e) => e.key === 'Enter' && review()} aria-invalid={!!error} />
        </Field>
      ) : (
        <div className="space-y-3 text-sm">
          <div className="rounded-xl bg-cream p-4">
            <p>المنطقة: <b>{editing.area.name}</b></p>
            {editing.price && <p>الرسوم الحالية: <b>{formatMoney(editing.price.price)}</b></p>}
            <p>الرسوم الجديدة: <b className="text-secondary">{formatMoney(fils!)}</b></p>
          </div>
          <p className="text-xs text-ink-muted">تنطبق على الطلبات الجديدة فقط. الطلبات السابقة والنشطة تحتفظ برسومها المحفوظة.</p>
        </div>
      )}
    </Dialog>
  );
}
