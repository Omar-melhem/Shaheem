import { useState } from 'react';
import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { Button, Dialog, Field, Input, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { GovernorateSelect } from './GovernorateSelect';

const EMPTY = { governorateId: '', name: '', aliases: '', notes: '' };

/** Create / edit a central zone. The Governorate is chosen first (FU-1.2 §7.1); the boundary is drawn on the map afterwards. */
export function ZoneDialog({ zone, onClose }: { zone: ServiceArea | 'new' | null; onClose: () => void }) {
  const createZone = useAppStore((s) => s.createZone);
  const updateZone = useAppStore((s) => s.updateZone);
  const [form, setForm] = useState(EMPTY);
  const [lastKey, setLastKey] = useState<string | null>(null);
  const key = zone === 'new' ? 'new' : zone?.id ?? null;
  if (key !== lastKey) {
    setLastKey(key);
    setForm(zone && zone !== 'new' ? { governorateId: zone.governorateId, name: zone.name, aliases: zone.aliases.join('، '), notes: zone.notes ?? '' } : EMPTY);
  }

  const submit = () => {
    const input = { governorateId: form.governorateId, name: form.name, aliases: form.aliases.split(/[،,]/), notes: form.notes };
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
          <GovernorateSelect id="zone-gov" value={form.governorateId} onChange={(e) => setForm({ ...form, governorateId: e.target.value })} />
        </Field>
        <Field label="اسم المنطقة بالعربية" required>
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="مثال: ضاحية الرشيد" disabled={!form.governorateId} />
        </Field>
        <Field label="أسماء بديلة / تهجئات" optional hint="افصل بينها بفاصلة. تساعد في البحث وتمنع تكرار نفس المنطقة.">
          <Input value={form.aliases} onChange={(e) => setForm({ ...form, aliases: e.target.value })} placeholder="Rashid Suburb، الرشيد" disabled={!form.governorateId} />
        </Field>
        <Field label="ملاحظات داخلية" optional>
          <Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} disabled={!form.governorateId} />
        </Field>
        {zone === 'new' && <p className="text-xs text-ink-muted">بعد الحفظ ارسم حدود المنطقة من زر «الحدود» — لا يمكن مطابقة موقع العميل مع منطقة بلا حدود.</p>}
      </div>
    </Dialog>
  );
}
