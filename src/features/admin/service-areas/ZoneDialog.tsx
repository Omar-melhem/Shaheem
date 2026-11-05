import { useState } from 'react';
import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { Button, Dialog, Field, Input, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { GovernorateSelect } from './GovernorateSelect';
import { CitySelect } from './CitySelect';

const EMPTY = { governorateId: '', cityId: '', name: '', aliases: '', notes: '' };

/** Create / edit a central zone. Governorate, then City (FU-1.2 §7.1, CR v1.3 §3.1); the boundary is drawn afterwards. */
export function ZoneDialog({ zone, onClose }: { zone: ServiceArea | 'new' | null; onClose: () => void }) {
  const createZone = useAppStore((s) => s.createZone);
  const updateZone = useAppStore((s) => s.updateZone);
  const [form, setForm] = useState(EMPTY);
  const [lastKey, setLastKey] = useState<string | null>(null);
  const key = zone === 'new' ? 'new' : zone?.id ?? null;
  if (key !== lastKey) {
    setLastKey(key);
    setForm(zone && zone !== 'new' ? { governorateId: zone.governorateId, cityId: zone.cityId, name: zone.name, aliases: zone.aliases.join('، '), notes: zone.notes ?? '' } : EMPTY);
  }

  const submit = () => {
    const input = { governorateId: form.governorateId, cityId: form.cityId, name: form.name, aliases: form.aliases.split(/[،,]/), notes: form.notes };
    const result = zone === 'new' ? createZone(input) : zone ? updateZone(zone.id, input) : null;
    if (result && reportResult(result, zone === 'new' ? 'تمت إضافة المنطقة — ارسم حدودها على الخريطة' : 'تم حفظ المنطقة')) onClose();
  };

  return (
    <Dialog
      open={!!zone}
      onClose={onClose}
      title={zone === 'new' ? 'منطقة توصيل جديدة' : 'تعديل المنطقة'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit}>حفظ</Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="المحافظة" required htmlFor="zone-gov">
          <GovernorateSelect id="zone-gov" value={form.governorateId} onChange={(e) => setForm({ ...form, governorateId: e.target.value, cityId: '' })} />
        </Field>
        <Field label="المدينة" required htmlFor="zone-city">
          <CitySelect id="zone-city" governorateId={form.governorateId} value={form.cityId} onChange={(e) => setForm({ ...form, cityId: e.target.value })} />
        </Field>
        <Field label="اسم المنطقة بالعربية" required>
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="مثال: ضاحية الرشيد" disabled={!form.cityId} />
        </Field>
        <Field label="أسماء بديلة / تهجئات" optional hint="افصل بينها بفاصلة. تساعد في البحث وتمنع تكرار نفس المنطقة.">
          <Input value={form.aliases} onChange={(e) => setForm({ ...form, aliases: e.target.value })} placeholder="Rashid Suburb، الرشيد" disabled={!form.cityId} />
        </Field>
        <Field label="ملاحظات داخلية" optional>
          <Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} disabled={!form.cityId} />
        </Field>
        {zone === 'new' && <p className="text-xs text-ink-muted">بعد الحفظ ارسم حدود المنطقة من زر «تعديل الحدود» — لا يمكن مطابقة موقع العميل مع منطقة بلا حدود.</p>}
      </div>
    </Dialog>
  );
}
