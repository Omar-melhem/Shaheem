import { useState } from 'react';
import { ArrowDown, ArrowUp, Headphones, Pencil, Plus, Trash2 } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { SupportChannel, SupportContact } from '@/domain/types';
import { Badge, Button, Card, CardHeader, ConfirmDialog, Dialog, EmptyState, Field, Input, PageHeader, Select, Toggle } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { CHANNEL_LABEL, SupportContactList } from '@/features/support/SupportContacts';

type Draft = Omit<SupportContact, 'id' | 'order'> & { id?: string };
const EMPTY: Draft = { channel: 'phone', label: '', value: '', enabled: true };

/** Central SHAHM support contacts consumed by Merchant Portal and Captain App (SRS §4.11, §12). */
export function SupportSettingsPage() {
  const contacts = useAppStore((s) => s.supportContacts);
  const save = useAppStore((s) => s.saveSupportContact);
  const remove = useAppStore((s) => s.removeSupportContact);
  const move = useAppStore((s) => s.moveSupportContact);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [deleting, setDeleting] = useState<SupportContact | null>(null);
  const sorted = [...contacts].sort((a, b) => a.order - b.order);

  return (
    <>
      <PageHeader
        title="بيانات الدعم والتواصل"
        description="مكان واحد لإدارة قنوات تواصل شهم الرسمية، وتظهر تلقائياً في بوابة التاجر وتطبيق الكابتن."
        actions={<Button icon={<Plus className="h-4 w-4" />} onClick={() => setDraft(EMPTY)}>إضافة قناة</Button>}
      />
      <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900">
        بيانات التواصل الرسمية لم تُعتمد بعد من مالك المنتج. لا تُدخل أرقاماً أو روابط غير رسمية في العرض أمام العميل.
      </div>
      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader title="القنوات المُعدّة" />
          {sorted.length === 0 ? (
            <EmptyState icon={<Headphones className="h-6 w-6" />} title="لا توجد قنوات بعد" description="أضف القنوات الرسمية عند توفرها." />
          ) : (
            <ul className="divide-y divide-cream-dark">
              {sorted.map((c, i) => (
                <li key={c.id} className="flex flex-wrap items-center gap-2 px-5 py-3">
                  <div className="min-w-0 flex-1">
                    <p className="font-bold">{c.label}</p>
                    <p className="text-xs text-ink-muted">
                      {CHANNEL_LABEL[c.channel]} · <span dir="ltr">{c.value}</span>
                    </p>
                  </div>
                  {!c.enabled && <Badge>مخفية</Badge>}
                  <Button size="sm" variant="ghost" aria-label="تحريك للأعلى" disabled={i === 0} onClick={() => move(c.id, -1)}><ArrowUp className="h-4 w-4" /></Button>
                  <Button size="sm" variant="ghost" aria-label="تحريك للأسفل" disabled={i === sorted.length - 1} onClick={() => move(c.id, 1)}><ArrowDown className="h-4 w-4" /></Button>
                  <Button size="sm" variant="ghost" aria-label="تعديل" onClick={() => setDraft(c)}><Pencil className="h-4 w-4" /></Button>
                  <Button size="sm" variant="ghost" aria-label="حذف" onClick={() => setDeleting(c)}><Trash2 className="h-4 w-4 text-red-700" /></Button>
                </li>
              ))}
            </ul>
          )}
        </Card>
        <Card>
          <CardHeader title="معاينة كما يراها التاجر والكابتن" />
          <div className="p-5">
            <SupportContactList />
          </div>
        </Card>
      </div>

      <Dialog
        open={!!draft}
        onClose={() => setDraft(null)}
        size="sm"
        title={draft?.id ? 'تعديل قناة التواصل' : 'إضافة قناة تواصل'}
        footer={
          <>
            <Button variant="outline" onClick={() => setDraft(null)}>إلغاء</Button>
            <Button onClick={() => draft && reportResult(save(draft), 'تم حفظ قناة التواصل') && setDraft(null)}>حفظ</Button>
          </>
        }
      >
        {draft && (
          <div className="space-y-4">
            <Field label="نوع القناة" required>
              <Select value={draft.channel} onChange={(e) => setDraft({ ...draft, channel: e.target.value as SupportChannel })}>
                {(Object.keys(CHANNEL_LABEL) as SupportChannel[]).map((c) => <option key={c} value={c}>{CHANNEL_LABEL[c]}</option>)}
              </Select>
            </Field>
            <Field label="العنوان الظاهر" required>
              <Input value={draft.label} onChange={(e) => setDraft({ ...draft, label: e.target.value })} placeholder="مثال: خدمة العملاء" />
            </Field>
            <Field label="بيانات التواصل" required hint="رقم الهاتف أو البريد أو الرابط الرسمي">
              <Input value={draft.value} onChange={(e) => setDraft({ ...draft, value: e.target.value })} dir="ltr" />
            </Field>
            <Toggle checked={draft.enabled} onChange={(v) => setDraft({ ...draft, enabled: v })} label="ظاهرة للتجار والكباتن" />
          </div>
        )}
      </Dialog>

      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        onConfirm={() => deleting && remove(deleting.id)}
        title="حذف قناة التواصل؟"
        description={deleting ? `سيتم حذف «${deleting.label}» من بوابة التاجر وتطبيق الكابتن.` : undefined}
        confirmLabel="حذف"
        variant="danger"
      />
    </>
  );
}
