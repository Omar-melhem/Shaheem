import { useState } from 'react';
import { useAppStore } from '@/application/store';
import { Button, Dialog, Field, OpenDecision, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { GovernorateSelect } from './GovernorateSelect';
import { CitySelect } from './CitySelect';

const EXAMPLE = 'خلدا\nخلدا / الحي الشرقي\nتلاع العلي';

/**
 * Fills the catalogue from a list typed or pasted by Admin (CR v1.4 §1.2). Names only: SHAHM
 * has no approved official dataset to import from, so nothing is pre-filled or invented.
 */
export function AreaImportDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const importAreas = useAppStore((s) => s.importAreas);
  const [governorateId, setGovernorateId] = useState('');
  const [cityId, setCityId] = useState('');
  const [lines, setLines] = useState('');
  const count = lines.split('\n').filter((l) => l.trim()).length;

  const close = () => {
    setLines('');
    onClose();
  };
  const submit = () => {
    const result = importAreas({ governorateId, cityId, lines });
    if (reportResult(result, result.ok ? `أُضيف ${result.value.created}، وتُخطّي ${result.value.skipped} موجود مسبقاً` : undefined)) close();
  };

  return (
    <Dialog
      open={open}
      onClose={close}
      title="استيراد مناطق وأقسام"
      description="سطر لكل منطقة، أو «منطقة / قسم» لإضافة قسم تحتها."
      footer={
        <>
          <Button variant="outline" onClick={close}>إلغاء</Button>
          <Button onClick={submit} disabled={!cityId || count === 0}>استيراد ({count})</Button>
        </>
      }
    >
      <div className="space-y-4">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="المحافظة" required htmlFor="import-gov">
            <GovernorateSelect id="import-gov" value={governorateId} onChange={(e) => { setGovernorateId(e.target.value); setCityId(''); }} />
          </Field>
          <Field label="المدينة" required htmlFor="import-city">
            <CitySelect id="import-city" governorateId={governorateId} value={cityId} onChange={(e) => setCityId(e.target.value)} />
          </Field>
        </div>
        <Field label="القائمة" required hint="الأسماء الموجودة تُتخطّى تلقائياً ولا تتكرر.">
          <Textarea className="min-h-[160px]" value={lines} onChange={(e) => setLines(e.target.value)} placeholder={EXAMPLE} />
        </Field>
        <OpenDecision id="CR-1.4 §1.2">لا توجد قائمة رسمية معتمدة لمناطق الأردن في المشروع؛ أدخل الأسماء من المصدر الذي تعتمده الإدارة.</OpenDecision>
      </div>
    </Dialog>
  );
}
