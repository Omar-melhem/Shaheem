import { useState } from 'react';
import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { areaFullPath } from '@/domain/regions';
import { Button, Dialog, Field, Input, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { GovernorateSelect } from './GovernorateSelect';
import { CitySelect } from './CitySelect';

export type ZoneEditing = { mode: 'new' } | { mode: 'section'; parent: ServiceArea } | { mode: 'edit'; zone: ServiceArea };

const EMPTY = { governorateId: '', cityId: '', name: '', aliases: '', notes: '' };

/**
 * Create / edit an area or a sub-area (قسم). Areas take Governorate then City; a section inherits
 * both from its parent. Names only — no map or boundary (CR v1.4 §1.1).
 */
export function ZoneDialog({ editing, onClose }: { editing: ZoneEditing | null; onClose: () => void }) {
  const areas = useAppStore((s) => s.areas);
  const createZone = useAppStore((s) => s.createZone);
  const updateZone = useAppStore((s) => s.updateZone);
  const [form, setForm] = useState(EMPTY);
  const [lastKey, setLastKey] = useState<string | null>(null);

  const key = !editing ? null : editing.mode === 'edit' ? editing.zone.id : editing.mode === 'section' ? `s-${editing.parent.id}` : 'new';
  if (key !== lastKey) {
    setLastKey(key);
    const z = editing?.mode === 'edit' ? editing.zone : null;
    setForm(z ? { governorateId: z.governorateId, cityId: z.cityId, name: z.name, aliases: z.aliases.join('، '), notes: z.notes ?? '' } : EMPTY);
  }
  if (!editing) return null;

  const parent = editing.mode === 'section' ? editing.parent : editing.mode === 'edit' && editing.zone.parentId ? areas.find((a) => a.id === editing.zone.parentId) ?? null : null;
  const isSection = !!parent;
  const ready = isSection || !!form.cityId;

  const submit = () => {
    const base = { governorateId: form.governorateId, cityId: form.cityId, name: form.name, aliases: form.aliases.split(/[،,]/), notes: form.notes };
    const result =
      editing.mode === 'edit'
        ? updateZone(editing.zone.id, isSection ? { name: base.name, aliases: base.aliases, notes: base.notes } : base)
        : createZone({ ...base, parentId: parent?.id ?? null });
    if (reportResult(result, editing.mode === 'edit' ? 'تم الحفظ' : isSection ? 'تمت إضافة القسم' : 'تمت إضافة المنطقة')) onClose();
  };

  const title = editing.mode === 'edit' ? (isSection ? 'تعديل القسم' : 'تعديل المنطقة') : isSection ? 'قسم جديد' : 'منطقة توصيل جديدة';

  return (
    <Dialog
      open
      onClose={onClose}
      title={title}
      description={parent ? `ضمن: ${areaFullPath(parent, areas)}` : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit}>حفظ</Button>
        </>
      }
    >
      <div className="space-y-4">
        {!isSection && (
          <div className="grid gap-4 sm:grid-cols-2">
            <Field label="المحافظة" required htmlFor="zone-gov">
              <GovernorateSelect id="zone-gov" value={form.governorateId} onChange={(e) => setForm({ ...form, governorateId: e.target.value, cityId: '' })} />
            </Field>
            <Field label="المدينة" required htmlFor="zone-city">
              <CitySelect id="zone-city" governorateId={form.governorateId} value={form.cityId} onChange={(e) => setForm({ ...form, cityId: e.target.value })} />
            </Field>
          </div>
        )}
        <Field label={isSection ? 'اسم القسم' : 'اسم المنطقة بالعربية'} required>
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder={isSection ? 'مثال: الحي الشرقي' : 'مثال: ضاحية الرشيد'} disabled={!ready} />
        </Field>
        <Field label="أسماء بديلة / تهجئات" optional hint="افصل بينها بفاصلة. تساعد في البحث وتمنع التكرار.">
          <Input value={form.aliases} onChange={(e) => setForm({ ...form, aliases: e.target.value })} placeholder="Rashid Suburb، الرشيد" disabled={!ready} />
        </Field>
        <Field label="ملاحظات داخلية" optional>
          <Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} disabled={!ready} />
        </Field>
        {editing.mode !== 'edit' && <p className="text-xs text-ink-muted">بعد الحفظ فعّلها للتجار وحدّد لها سعراً من «أسعار التجار». كل منطقة وقسم لهما سعر مستقل.</p>}
      </div>
    </Dialog>
  );
}
