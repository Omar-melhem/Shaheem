import { useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { governorateName } from '@/domain/governorates';
import { Button, Dialog, Field, OpenDecision } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { GovernorateSelect } from './GovernorateSelect';
import { AreaSelect } from './AreaSelect';

const EMPTY = { governorateId: '', originAreaId: '', destinationAreaId: '' };

/**
 * Governorate → origin area → destination area → review → save (FU-1.2 §7.1).
 * Saves a route record only; Merchant + destination-zone pricing is untouched.
 */
export function DeliveryRouteDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const areas = useAppStore((s) => s.areas);
  const createRoute = useAppStore((s) => s.createRoute);
  const [form, setForm] = useState(EMPTY);
  const [step, setStep] = useState<'form' | 'review'>('form');

  const close = () => {
    setForm(EMPTY);
    setStep('form');
    onClose();
  };
  // Changing a parent selection resets the now-invalid child selections.
  const setGovernorate = (governorateId: string) => setForm({ governorateId, originAreaId: '', destinationAreaId: '' });
  const setOrigin = (originAreaId: string) =>
    setForm((f) => ({ ...f, originAreaId, destinationAreaId: f.destinationAreaId === originAreaId ? '' : f.destinationAreaId }));

  const origin = areas.find((a) => a.id === form.originAreaId);
  const destination = areas.find((a) => a.id === form.destinationAreaId);
  const complete = !!form.governorateId && !!origin && !!destination;
  const save = () => {
    if (reportResult(createRoute(form), `تم حفظ مسار التوصيل من «${origin?.name}» إلى «${destination?.name}»`)) close();
  };

  return (
    <Dialog
      open={open}
      onClose={close}
      title="مسار توصيل جديد"
      description="حدّد المحافظة، ثم منطقة الانطلاق، ثم منطقة الوصول."
      footer={
        step === 'form' ? (
          <>
            <Button variant="outline" onClick={close}>إلغاء</Button>
            <Button onClick={() => setStep('review')} disabled={!complete}>مراجعة</Button>
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
        <div className="space-y-4">
          <Field label="1. المحافظة" required htmlFor="route-gov">
            <GovernorateSelect id="route-gov" value={form.governorateId} onChange={(e) => setGovernorate(e.target.value)} />
          </Field>
          <Field label="2. من منطقة" required htmlFor="route-origin" hint="منطقة الانطلاق داخل المحافظة المختارة">
            <AreaSelect id="route-origin" areas={areas} scope={{ by: 'governorate', id: form.governorateId }} placeholder="اختر منطقة الانطلاق" value={form.originAreaId} onChange={(e) => setOrigin(e.target.value)} />
          </Field>
          <Field label="3. إلى منطقة" required htmlFor="route-dest" hint="منطقة الوصول — مختلفة عن منطقة الانطلاق">
            <AreaSelect
              id="route-dest"
              areas={areas}
              scope={{ by: 'governorate', id: form.governorateId }}
              excludeId={form.originAreaId}
              placeholder="اختر منطقة الوصول"
              value={form.destinationAreaId}
              onChange={(e) => setForm({ ...form, destinationAreaId: e.target.value })}
              disabled={!form.originAreaId}
            />
          </Field>
          <OpenDecision id="FU-14.5 / 14.6">
            المسار سجل تغطية فقط ولا يغيّر رسوم التوصيل (التسعير يبقى: التاجر + منطقة العميل). اعتماد التسعير حسب المسار، وهل منطقة الانطلاق تُختار يدوياً أم من موقع استلام التاجر، قرارات مفتوحة.
          </OpenDecision>
        </div>
      ) : (
        <div className="space-y-3 text-sm">
          <p className="font-bold">4. مراجعة المسار</p>
          <div className="rounded-xl bg-cream p-4">
            <p className="text-xs text-ink-muted">المحافظة: {governorateName(form.governorateId)}</p>
            <p className="mt-2 flex items-center gap-2 text-base font-bold">
              {origin?.name} <ArrowLeft className="h-4 w-4 text-primary" aria-label="إلى" /> {destination?.name}
            </p>
          </div>
          <p className="text-xs text-ink-muted">لن تتغير أسعار التجار ولا رسوم الطلبات السابقة.</p>
        </div>
      )}
    </Dialog>
  );
}
