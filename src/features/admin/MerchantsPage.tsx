import { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Marker } from 'react-leaflet';
import { Plus, Store, Pencil, Tags } from 'lucide-react';
import { useAppStore, type MerchantInput } from '@/application/store';
import { MERCHANT_CATEGORIES, type LatLng, type Merchant, type MerchantCategory } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { isActiveDelivery } from '@/domain/orderStatus';
import { Badge, Button, Card, ConfirmDialog, DetailRow, Dialog, Drawer, EmptyState, Field, Input, PageHeader, Select, Toggle, SearchField } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { formatDate, formatDateTime, isPlausiblePhone } from '@/shared/lib/format';
import { BusinessCategorySelect } from '@/features/merchants/BusinessCategorySelect';
import { MerchantCategoryBadge } from '@/features/merchants/MerchantCategoryBadge';
import { CATEGORY_LABEL, UNCATEGORIZED_LABEL } from '@/features/merchants/categories';
import { LocationPicker } from './LocationPicker';

export function MerchantsPage() {
  const merchants = useAppStore((s) => s.merchants);
  const orders = useAppStore((s) => s.orders);
  const [params, setParams] = useSearchParams();
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Merchant | 'new' | null>(null);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [category, setCategory] = useState<MerchantCategory | 'none' | ''>('');

  useEffect(() => {
    if (params.get('new')) {
      setEditing('new');
      setParams({}, { replace: true });
    }
  }, [params, setParams]);

  const filtered = merchants
    .filter((m) => !category || (category === 'none' ? !m.category : m.category === category))
    .filter((m) => !q.trim() || [m.businessName, m.contactName, m.phone, m.address].some((v) => v.includes(q.trim())));

  return (
    <>
      <PageHeader
        title="التجار"
        description="تسجيل التجار وإدارتهم. موقع الاستلام يُحفظ في ملف التاجر فلا يحتاج لإدخاله مع كل طلب."
        actions={<Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing('new')}>إضافة تاجر</Button>}
      />
      <Card className="mb-4 flex flex-wrap gap-3 p-4">
        <SearchField label="بحث في التجار" className="min-w-[220px] max-w-md flex-1" placeholder="ابحث بالاسم أو الهاتف أو العنوان" value={q} onChange={(e) => setQ(e.target.value)} />
        <div className="w-full sm:w-56">
          <Select aria-label="تصفية حسب فئة النشاط" value={category} onChange={(e) => setCategory(e.target.value as MerchantCategory | 'none' | '')}>
          <option value="">كل الفئات</option>
          {MERCHANT_CATEGORIES.map((c) => <option key={c} value={c}>{CATEGORY_LABEL[c]}</option>)}
          <option value="none">{UNCATEGORIZED_LABEL}</option>
          </Select>
        </div>
      </Card>
      <Card className="overflow-hidden">
        {filtered.length === 0 ? (
          <EmptyState icon={<Store className="h-6 w-6" />} title="لا يوجد تجار مطابقون" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[820px] text-sm">
              <thead className="bg-cream text-xs text-ink-muted">
                <tr>
                  {['النشاط التجاري', 'الفئة', 'جهة الاتصال', 'العنوان', 'الطلبات', 'الحالة', ''].map((h, i) => (
                    <th key={i} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-cream-dark">
                {filtered.map((m) => (
                  <tr key={m.id} className="hover:bg-cream/60">
                    <td className="px-4 py-3">
                      <button className="font-bold text-primary hover:underline" onClick={() => setDetailId(m.id)}>{m.businessName}</button>
                      <p className="text-xs text-ink-muted">منذ {formatDate(m.createdAt)}</p>
                    </td>
                    <td className="px-4 py-3"><MerchantCategoryBadge category={m.category} /></td>
                    <td className="px-4 py-3">
                      {m.contactName}
                      <p className="text-xs text-ink-muted" dir="ltr" style={{ textAlign: 'right' }}>{m.phone}</p>
                    </td>
                    <td className="max-w-[220px] truncate px-4 py-3">{m.address}</td>
                    <td className="px-4 py-3">{orders.filter((o) => o.merchantId === m.id).length}</td>
                    <td className="px-4 py-3">
                      <Badge tone={m.status === 'active' ? 'success' : 'danger'} dot>{m.status === 'active' ? 'مفعّل' : 'غير مفعّل'}</Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        <Link to={`/admin/merchants/${m.id}/zones`} className="inline-flex h-8 items-center gap-1.5 rounded-lg px-3 text-sm font-bold text-primary hover:bg-primary-50"><Tags className="h-4 w-4" /> المناطق والأسعار</Link>
                        <Button size="sm" variant="ghost" icon={<Pencil className="h-4 w-4" />} onClick={() => setEditing(m)}>تعديل</Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <MerchantFormDialog merchant={editing} onClose={() => setEditing(null)} />
      <MerchantDetailDrawer merchantId={detailId} onClose={() => setDetailId(null)} onEdit={(m) => { setDetailId(null); setEditing(m); }} />
    </>
  );
}

const EMPTY: MerchantInput = { businessName: '', category: null, contactName: '', phone: '', address: '', pickup: null as unknown as LatLng, username: '', password: '' };

function MerchantFormDialog({ merchant, onClose }: { merchant: Merchant | 'new' | null; onClose: () => void }) {
  const createMerchant = useAppStore((s) => s.createMerchant);
  const updateMerchant = useAppStore((s) => s.updateMerchant);
  const [form, setForm] = useState<MerchantInput>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    if (merchant === 'new') setForm(EMPTY);
    else if (merchant) {
      const { id: _id, createdAt: _c, status: _s, ...rest } = merchant;
      setForm(rest);
    }
    setErrors({});
  }, [merchant]);

  const set = <K extends keyof MerchantInput>(k: K, v: MerchantInput[K]) => setForm((f) => ({ ...f, [k]: v }));

  const submit = () => {
    const e: Record<string, string> = {};
    if (!form.businessName.trim()) e.businessName = 'اسم النشاط التجاري مطلوب';
    if (!form.category) e.category = 'اختر فئة النشاط التجاري';
    if (!form.contactName.trim()) e.contactName = 'اسم جهة الاتصال مطلوب';
    if (!isPlausiblePhone(form.phone)) e.phone = 'أدخل رقم هاتف صالحاً';
    if (!form.address.trim()) e.address = 'العنوان مطلوب';
    if (!form.pickup) e.pickup = 'حدد موقع الاستلام على الخريطة';
    if (!form.username.trim()) e.username = 'اسم المستخدم مطلوب';
    if (form.password.length < 6) e.password = 'كلمة المرور 6 أحرف على الأقل';
    setErrors(e);
    if (Object.keys(e).length) return;
    setSubmitting(true);
    const result = merchant === 'new' ? createMerchant(form) : updateMerchant((merchant as Merchant).id, form);
    setSubmitting(false);
    if (!reportResult(result, merchant === 'new' ? 'تم إنشاء التاجر — حدّد الآن مناطق التوصيل والأسعار' : 'تم حفظ بيانات التاجر')) return;
    onClose();
    // Spec §3: after registering a merchant, Admin configures its zones & pricing.
    if (merchant === 'new' && result.ok && typeof result.value === 'string') navigate(`/admin/merchants/${result.value}/zones`);
  };

  return (
    <Dialog
      open={!!merchant}
      onClose={onClose}
      size="lg"
      title={merchant === 'new' ? 'إضافة تاجر' : 'تعديل بيانات التاجر'}
      description={merchant === 'new' ? 'في النسخة الإنتاجية تُرسل بيانات الدخول أو دعوة للتاجر — غير مفعّل في هذا النموذج.' : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit} loading={submitting}>{merchant === 'new' ? 'إنشاء التاجر' : 'حفظ'}</Button>
        </>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="اسم النشاط التجاري" required error={errors.businessName}>
          <Input value={form.businessName} onChange={(e) => set('businessName', e.target.value)} aria-invalid={!!errors.businessName} />
        </Field>
        <Field label="فئة النشاط التجاري" required error={errors.category} htmlFor="merchant-category">
          <BusinessCategorySelect id="merchant-category" value={form.category} onChange={(c) => set('category', c)} aria-invalid={!!errors.category} />
        </Field>
        <Field label="المالك / جهة الاتصال" required error={errors.contactName}>
          <Input value={form.contactName} onChange={(e) => set('contactName', e.target.value)} aria-invalid={!!errors.contactName} />
        </Field>
        <Field label="رقم الهاتف" required error={errors.phone}>
          <Input value={form.phone} onChange={(e) => set('phone', e.target.value)} dir="ltr" inputMode="tel" aria-invalid={!!errors.phone} />
        </Field>
        <Field label="العنوان" required error={errors.address} className="md:col-span-2">
          <Input value={form.address} onChange={(e) => set('address', e.target.value)} aria-invalid={!!errors.address} />
        </Field>
        <Field label="موقع الاستلام" required error={errors.pickup} className="md:col-span-2">
          <LocationPicker value={form.pickup ?? null} onChange={(p) => set('pickup', p)} />
        </Field>
        <div className="rounded-xl border border-dashed border-sand-dark/50 bg-sand-light/20 p-4 md:col-span-2">
          <p className="mb-3 text-sm font-bold text-ink">بيانات الدخول (تجريبية)</p>
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="اسم المستخدم" required error={errors.username}>
              <Input value={form.username} onChange={(e) => set('username', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.username} />
            </Field>
            <Field label="كلمة المرور" required error={errors.password} hint="6 أحرف على الأقل">
              <Input value={form.password} onChange={(e) => set('password', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.password} />
            </Field>
          </div>
        </div>
      </div>
    </Dialog>
  );
}

function MerchantDetailDrawer({ merchantId, onClose, onEdit }: { merchantId: string | null; onClose: () => void; onEdit: (m: Merchant) => void }) {
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const orders = useAppStore((s) => s.orders);
  const prices = useAppStore((s) => s.prices);
  const areas = useAppStore((s) => s.areas);
  const setMerchantStatus = useAppStore((s) => s.setMerchantStatus);
  const [confirm, setConfirm] = useState(false);

  const merchantOrders = useMemo(() => orders.filter((o) => o.merchantId === merchantId).sort((a, b) => b.createdAt - a.createdAt), [orders, merchantId]);
  if (!merchant) return null;
  const merchantPrices = prices.filter((p) => p.merchantId === merchant.id);

  return (
    <Drawer
      open={!!merchantId}
      onClose={onClose}
      title={merchant.businessName}
      subtitle={<Badge tone={merchant.status === 'active' ? 'success' : 'danger'} dot>{merchant.status === 'active' ? 'مفعّل' : 'غير مفعّل'}</Badge>}
      footer={
        <>
          <Link to={`/admin/merchants/${merchant.id}/zones`} className="inline-flex h-10 items-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-white hover:bg-primary-600">
            <Tags className="h-4 w-4" /> مناطق التوصيل والأسعار
          </Link>
          <Button variant="outline" icon={<Pencil className="h-4 w-4" />} onClick={() => onEdit(merchant)}>تعديل</Button>
        </>
      }
    >
      <Card className="p-4">
        <Toggle checked={merchant.status === 'active'} onChange={() => setConfirm(true)} label="حساب التاجر مفعّل" description="التاجر غير المفعّل لا يستطيع طلب كابتن" />
      </Card>
      <BaseMap className="h-48" center={merchant.pickup} zoom={15} label="موقع الاستلام">
        <Marker position={[merchant.pickup.lat, merchant.pickup.lng]} icon={merchantIcon()} />
      </BaseMap>
      <Card className="px-4 py-2">
        <dl className="divide-y divide-cream-dark">
          <DetailRow label="فئة النشاط"><MerchantCategoryBadge category={merchant.category} /></DetailRow>
          <DetailRow label="جهة الاتصال">{merchant.contactName}</DetailRow>
          <DetailRow label="الهاتف"><span dir="ltr">{merchant.phone}</span></DetailRow>
          <DetailRow label="العنوان">{merchant.address}</DetailRow>
          <DetailRow label="تاريخ الإنشاء">{formatDate(merchant.createdAt)}</DetailRow>
          <DetailRow label="مناطق مفعّلة">{merchantPrices.filter((p) => p.status === 'active').length} من {areas.length}</DetailRow>
          <DetailRow label="بيانات الدخول"><span dir="ltr">{merchant.username}</span></DetailRow>
          <DetailRow label="طلبات نشطة">{merchantOrders.filter((o) => isActiveDelivery(o.status)).length}</DetailRow>
        </dl>
      </Card>
      <Card className="p-4">
        <h3 className="mb-2 text-sm font-bold">طلبات التاجر ({merchantOrders.length})</h3>
        <ul className="divide-y divide-cream-dark">
          {merchantOrders.slice(0, 10).map((o) => (
            <li key={o.id} className="flex flex-wrap items-center gap-2 py-2 text-sm">
              <span className="font-mono font-bold" dir="ltr">{o.reference}</span>
              <span className="flex-1 text-ink-muted">{o.areaName} · {formatDateTime(o.createdAt)}</span>
              <span className="font-bold">{formatMoney(o.deliveryPrice)}</span>
              <OrderStatusBadge status={o.status} />
            </li>
          ))}
          {merchantOrders.length === 0 && <li className="py-4 text-center text-sm text-ink-muted">لا توجد طلبات بعد</li>}
        </ul>
      </Card>
      <ConfirmDialog
        open={confirm}
        onClose={() => setConfirm(false)}
        onConfirm={() => reportResult(setMerchantStatus(merchant.id, merchant.status !== 'active'), merchant.status === 'active' ? 'تم إيقاف حساب التاجر' : 'تم تفعيل حساب التاجر')}
        title={merchant.status === 'active' ? 'إيقاف حساب التاجر؟' : 'تفعيل حساب التاجر؟'}
        description={merchant.status === 'active' ? 'لن يتمكن التاجر من إنشاء طلبات جديدة. الطلبات القائمة لا تتأثر.' : 'سيتمكن التاجر من طلب الكباتن مجدداً.'}
        variant={merchant.status === 'active' ? 'danger' : 'secondary'}
      />
    </Drawer>
  );
}
