import { useEffect, useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { Plus, Users, Pencil, Star, Wallet } from 'lucide-react';
import { useAppStore, type CaptainInput } from '@/application/store';
import { useCaptainViews, useNow } from '@/application/hooks';
import type { Captain, VehicleType } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { describeReasons } from '@/domain/eligibility';
import { Badge, Button, Card, ConfirmDialog, DetailRow, Dialog, Drawer, EmptyState, Field, Input, OpenDecision, PageHeader, PhoneField, PHONE_HINT, Select, Textarea, Toggle, SearchField } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { reportResult } from '@/shared/components/toast';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { CaptainTripHistory } from './captains/CaptainTripHistory';
import { formatDate, formatDateTime, formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

export const VEHICLE_LABEL: Record<VehicleType, string> = { motorcycle: 'دراجة نارية', car: 'سيارة', bicycle: 'دراجة هوائية' };

export function CaptainsPage() {
  const now = useNow(5000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [params, setParams] = useSearchParams();
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Captain | 'new' | null>(null);
  const [detailId, setDetailId] = useState<string | null>(null);

  useEffect(() => {
    if (params.get('new')) {
      setEditing('new');
      setParams({}, { replace: true });
    }
  }, [params, setParams]);

  const filtered = views.filter((v) => !q.trim() || [v.captain.fullName, v.captain.phone].some((x) => x.includes(q.trim())));

  return (
    <>
      <PageHeader
        title="الكباتن"
        description="تسجيل الكباتن ومتابعة التوفر والأهلية والموقع والمحفظة."
        actions={<Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing('new')}>إضافة كابتن</Button>}
      />
      <Card className="mb-4 p-4">
        <SearchField label="بحث في الكباتن" className="max-w-md" placeholder="ابحث بالاسم أو الهاتف" value={q} onChange={(e) => setQ(e.target.value)} />
      </Card>
      <Card className="overflow-hidden">
        {filtered.length === 0 ? (
          <EmptyState icon={<Users className="h-6 w-6" />} title="لا يوجد كباتن مطابقون" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[980px] text-sm">
              <thead className="bg-cream text-xs text-ink-muted">
                <tr>
                  {['الكابتن', 'المركبة', 'الحالة', 'الأهلية للعروض', 'الموقع', 'المحفظة', 'توصيلات مكتملة', ''].map((h, i) => (
                    <th key={i} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-cream-dark">
                {filtered.map((v) => (
                  <tr key={v.captain.id} className="hover:bg-cream/60">
                    <td className="px-4 py-3">
                      <button className="font-bold text-primary hover:underline" onClick={() => setDetailId(v.captain.id)}>{v.captain.fullName}</button>
                      <p className="text-xs text-ink-muted" dir="ltr" style={{ textAlign: 'right' }}>{v.captain.phone}</p>
                    </td>
                    <td className="px-4 py-3">{VEHICLE_LABEL[v.captain.vehicleType]}</td>
                    <td className="px-4 py-3"><CaptainStatusBadge status={v.opStatus} /></td>
                    <td className="max-w-[220px] px-4 py-3">
                      {v.eligibility.eligible ? <Badge tone="success">مؤهل</Badge> : <span className="text-xs text-red-700">{describeReasons(v.eligibility.reasons)}</span>}
                    </td>
                    <td className="px-4 py-3">
                      <FreshnessBadge freshness={v.freshness} />
                      {v.captain.lastLocation && <p className="mt-0.5 text-[11px] text-ink-muted">{formatRelative(v.captain.lastLocation.recordedAt, now)}</p>}
                    </td>
                    <td className={cn('px-4 py-3 font-bold', v.balance < threshold && 'text-red-700')}>{formatMoney(v.balance)}</td>
                    <td className="px-4 py-3">{orders.filter((o) => o.captainId === v.captain.id && o.status === 'delivered').length}</td>
                    <td className="px-4 py-3">
                      <Button size="sm" variant="ghost" icon={<Pencil className="h-4 w-4" />} onClick={() => setEditing(v.captain)}>تعديل</Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      <CaptainFormDialog captain={editing} onClose={() => setEditing(null)} />
      <CaptainDetailDrawer captainId={detailId} onClose={() => setDetailId(null)} onEdit={(c) => { setDetailId(null); setEditing(c); }} />
    </>
  );
}

const EMPTY: CaptainInput = { fullName: '', phone: '', vehicleType: 'motorcycle', vehicleDescription: '', username: '', password: '' };

function CaptainFormDialog({ captain, onClose }: { captain: Captain | 'new' | null; onClose: () => void }) {
  const createCaptain = useAppStore((s) => s.createCaptain);
  const updateCaptain = useAppStore((s) => s.updateCaptain);
  const [form, setForm] = useState<CaptainInput>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const setField = (k: 'username' | 'password', v: string) => setForm((f) => ({ ...f, [k]: v }));

  useEffect(() => {
    setForm(captain === 'new' || !captain ? EMPTY : { fullName: captain.fullName, phone: captain.phone, vehicleType: captain.vehicleType, vehicleDescription: captain.vehicleDescription, username: captain.username, password: captain.password });
    setErrors({});
  }, [captain]);

  const submit = () => {
    const e: Record<string, string> = {};
    if (!form.fullName.trim()) e.fullName = 'الاسم الكامل مطلوب';
    if (!form.phone.trim()) e.phone = 'رقم الهاتف مطلوب';
    else if (!isValidPhone(form.phone)) e.phone = PHONE_ERROR;
    if (!form.username.trim()) e.username = 'اسم المستخدم مطلوب';
    if (form.password.length < 6) e.password = 'كلمة المرور 6 أحرف على الأقل';
    setErrors(e);
    if (Object.keys(e).length) return;
    const result = captain === 'new' ? createCaptain(form) : updateCaptain((captain as Captain).id, form);
    if (reportResult(result, captain === 'new' ? 'تم إنشاء حساب الكابتن (تجريبي) — يبدأ بحالة غير متاح ورصيد صفر' : 'تم حفظ بيانات الكابتن')) onClose();
  };

  return (
    <Dialog
      open={!!captain}
      onClose={onClose}
      title={captain === 'new' ? 'إضافة كابتن' : 'تعديل بيانات الكابتن'}
      description={captain === 'new' ? 'التسجيل الذاتي غير متاح؛ الإدارة تنشئ حسابات الكباتن. طريقة الدخول للتطبيق قرار مفتوح.' : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit}>{captain === 'new' ? 'إنشاء الكابتن' : 'حفظ'}</Button>
        </>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="الاسم الكامل" required error={errors.fullName}>
          <Input value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} aria-invalid={!!errors.fullName} />
        </Field>
        <Field label="رقم الهاتف" required error={errors.phone} hint={PHONE_HINT}>
          <PhoneField value={form.phone} onChange={(v) => setForm({ ...form, phone: v })} aria-invalid={!!errors.phone} />
        </Field>
        <Field label="نوع المركبة" required>
          <Select value={form.vehicleType} onChange={(e) => setForm({ ...form, vehicleType: e.target.value as VehicleType })}>
            {(Object.keys(VEHICLE_LABEL) as VehicleType[]).map((v) => <option key={v} value={v}>{VEHICLE_LABEL[v]}</option>)}
          </Select>
        </Field>
        <Field label="وصف المركبة" optional>
          <Input value={form.vehicleDescription} onChange={(e) => setForm({ ...form, vehicleDescription: e.target.value })} placeholder="اللون / رقم اللوحة" />
        </Field>
        <div className="rounded-xl border border-dashed border-sand-dark/50 bg-sand-light/20 p-4 md:col-span-2">
          <p className="mb-3 text-sm font-bold text-ink">بيانات الدخول (تجريبية)</p>
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="اسم المستخدم" required error={errors.username}>
              <Input value={form.username} onChange={(e) => setField('username', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.username} />
            </Field>
            <Field label="كلمة المرور" required error={errors.password} hint="6 أحرف على الأقل">
              <Input value={form.password} onChange={(e) => setField('password', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.password} />
            </Field>
          </div>
        </div>
      </div>
    </Dialog>
  );
}

function CaptainDetailDrawer({ captainId, onClose, onEdit }: { captainId: string | null; onClose: () => void; onEdit: (c: Captain) => void }) {
  const now = useNow(2000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const setCaptainStatus = useAppStore((s) => s.setCaptainStatus);
  const rateCaptain = useAppStore((s) => s.rateCaptain);
  const [confirm, setConfirm] = useState(false);
  const [rating, setRating] = useState<number | undefined>();
  const [notes, setNotes] = useState('');

  const view = views.find((v) => v.captain.id === captainId);
  useEffect(() => {
    if (view) {
      setRating(view.captain.rating);
      setNotes(view.captain.adminNotes ?? '');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [captainId]);
  const captainOrders = useMemo(() => orders.filter((o) => o.captainId === captainId).sort((a, b) => b.createdAt - a.createdAt), [orders, captainId]);
  if (!view) return null;
  const c = view.captain;

  return (
    <Drawer
      open={!!captainId}
      onClose={onClose}
      title={c.fullName}
      subtitle={<div className="flex flex-wrap gap-2"><CaptainStatusBadge status={view.opStatus} /><FreshnessBadge freshness={view.freshness} /></div>}
      footer={
        <>
          <Link to={`/admin/wallets?captain=${c.id}`} className="inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream">
            <Wallet className="h-4 w-4" /> شحن المحفظة
          </Link>
          <Button variant="outline" icon={<Pencil className="h-4 w-4" />} onClick={() => onEdit(c)}>تعديل</Button>
        </>
      }
    >
      <Card className="p-4">
        <Toggle checked={c.status === 'active'} onChange={() => setConfirm(true)} label="حساب الكابتن مفعّل" description="الكابتن الموقوف لا يستقبل أي عروض" />
      </Card>
      <Card className="px-4 py-2">
        <dl className="divide-y divide-cream-dark">
          <DetailRow label="الهاتف"><span dir="ltr">{c.phone}</span></DetailRow>
          <DetailRow label="المركبة">{VEHICLE_LABEL[c.vehicleType]}{c.vehicleDescription && ` — ${c.vehicleDescription}`}</DetailRow>
          <DetailRow label="رصيد المحفظة">{formatMoney(view.balance)}</DetailRow>
          <DetailRow label="الأهلية">{view.eligibility.eligible ? 'مؤهل لاستقبال العروض' : describeReasons(view.eligibility.reasons, threshold)}</DetailRow>
          <DetailRow label="آخر موقع">{c.lastLocation ? `${formatRelative(c.lastLocation.recordedAt, now)} (محاكاة)` : '—'}</DetailRow>
          <DetailRow label="تاريخ التسجيل">{formatDate(c.createdAt)}</DetailRow>
          <DetailRow label="بيانات الدخول"><span dir="ltr">{c.username}</span></DetailRow>
        </dl>
      </Card>

      <CaptainTripHistory captainId={c.id} now={now} />

      <Card className="space-y-3 p-4">
        <h3 className="text-sm font-bold">التقييم الداخلي</h3>
        <div className="flex items-center gap-1" role="radiogroup" aria-label="التقييم من 5">
          {[1, 2, 3, 4, 5].map((n) => (
            <button key={n} role="radio" aria-checked={rating === n} aria-label={`${n} من 5`} onClick={() => setRating(rating === n ? undefined : n)}>
              <Star className={cn('h-6 w-6', rating && n <= rating ? 'fill-sand text-sand-dark' : 'text-cream-deep')} />
            </button>
          ))}
        </div>
        <Textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="ملاحظات إدارية داخلية" aria-label="ملاحظات إدارية" />
        <Button size="sm" variant="outline" onClick={() => reportResult(rateCaptain(c.id, rating, notes), 'تم حفظ التقييم')}>حفظ التقييم</Button>
        <OpenDecision id="O-033">ميزة التقييم موروثة من المتطلبات السابقة؛ مقياس الخمس نجوم والملاحظات مقترحان. التقييم داخلي ولا يظهر للكابتن أو التاجر.</OpenDecision>
      </Card>

      <Card className="p-4">
        <h3 className="mb-2 text-sm font-bold">التوصيلات ({captainOrders.length})</h3>
        <ul className="divide-y divide-cream-dark">
          {captainOrders.slice(0, 10).map((o) => (
            <li key={o.id} className="flex flex-wrap items-center gap-2 py-2 text-sm">
              <span className="font-mono font-bold" dir="ltr">{o.reference}</span>
              <span className="flex-1 text-ink-muted">{o.areaName} · {formatDateTime(o.createdAt)}</span>
              <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
            </li>
          ))}
          {captainOrders.length === 0 && <li className="py-4 text-center text-sm text-ink-muted">لا توجد توصيلات</li>}
        </ul>
      </Card>

      <ConfirmDialog
        open={confirm}
        onClose={() => setConfirm(false)}
        onConfirm={() => reportResult(setCaptainStatus(c.id, c.status !== 'active'), c.status === 'active' ? 'تم إيقاف الكابتن' : 'تم تفعيل الكابتن')}
        title={c.status === 'active' ? 'إيقاف حساب الكابتن؟' : 'تفعيل حساب الكابتن؟'}
        description={c.status === 'active' ? 'ستُسحب أي عروض قائمة له ولن يستقبل عروضاً جديدة.' : 'سيتمكن الكابتن من التحول إلى متاح واستقبال العروض.'}
        variant={c.status === 'active' ? 'danger' : 'secondary'}
      />
    </Drawer>
  );
}
