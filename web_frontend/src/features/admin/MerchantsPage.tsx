import { useEffect, useMemo, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { Marker } from 'react-leaflet';
import { Eye, History, Plus, Power, Store, Pencil, Tags } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { MERCHANT_CATEGORIES, type Merchant, type MerchantCategory } from '@/domain/types';
import { cityName } from '@/domain/cities';
import { formatMoney } from '@/domain/money';
import { isActiveDelivery } from '@/domain/orderStatus';
import { Badge, Button, Card, ConfirmDialog, DataTable, DetailRow, Drawer, EmptyState, IconAction, PageHeader, RowActions, Select, Toggle, SearchField } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { formatDate, formatDateTime } from '@/shared/lib/format';
import { MerchantCategoryBadge } from '@/features/merchants/MerchantCategoryBadge';
import { CATEGORY_LABEL, UNCATEGORIZED_LABEL } from '@/features/merchants/categories';
import { MerchantFormDialog } from './merchants/MerchantFormDialog';

const HEADERS = ['النشاط التجاري', 'الفئة', 'الهاتف', 'العنوان', 'الطلبات', 'الحالة'];
const LEGEND = [
  { icon: <Eye />, label: 'عرض التفاصيل' },
  { icon: <Tags />, label: 'مناطق التوصيل والأسعار' },
  { icon: <History />, label: 'طلبات التاجر' },
  { icon: <Pencil />, label: 'تعديل البيانات' },
  { icon: <Power />, label: 'تفعيل / إيقاف الحساب' },
];

export function MerchantsPage() {
  const merchants = useAppStore((s) => s.merchants);
  const orders = useAppStore((s) => s.orders);
  const [params, setParams] = useSearchParams();
  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<Merchant | 'new' | null>(null);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [category, setCategory] = useState<MerchantCategory | 'none' | ''>('');
  const [toggling, setToggling] = useState<Merchant | null>(null);

  useEffect(() => {
    if (params.get('new')) {
      setEditing('new');
      setParams({}, { replace: true });
    }
  }, [params, setParams]);

  const filtered = merchants
    .filter((m) => !category || (category === 'none' ? !m.category : m.category === category))
    .filter((m) => !q.trim() || [m.businessName, m.phone, m.address].some((v) => v.includes(q.trim())));

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
          <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={900}>
            {filtered.map((m) => (
              <tr key={m.id}>
                <td className="px-4 py-3">
                  <p className="font-bold text-ink">{m.businessName}</p>
                  <p className="text-xs text-ink-muted">منذ {formatDate(m.createdAt)}</p>
                </td>
                <td className="px-4 py-3"><MerchantCategoryBadge category={m.category} /></td>
                <td className="whitespace-nowrap px-4 py-3" dir="ltr" style={{ textAlign: 'right' }}>{m.phone}</td>
                <td className="max-w-[220px] truncate px-4 py-3">{m.address}</td>
                <td className="px-4 py-3">{orders.filter((o) => o.merchantId === m.id).length}</td>
                <td className="px-4 py-3">
                  <Badge tone={m.status === 'active' ? 'success' : 'danger'} dot>{m.status === 'active' ? 'مفعّل' : 'غير مفعّل'}</Badge>
                </td>
                <RowActions>
                  <IconAction icon={<Eye />} label="عرض التفاصيل" onClick={() => setDetailId(m.id)} />
                  <IconAction icon={<Tags />} label="المناطق والأسعار" tone="primary" to={`/admin/merchants/${m.id}/zones`} />
                  <IconAction icon={<History />} label="طلبات التاجر" to={`/admin/orders?merchant=${m.id}`} />
                  <IconAction icon={<Pencil />} label="تعديل البيانات" onClick={() => setEditing(m)} />
                  <IconAction icon={<Power />} label={m.status === 'active' ? 'إيقاف الحساب' : 'تفعيل الحساب'} tone={m.status === 'active' ? 'danger' : 'secondary'} onClick={() => setToggling(m)} />
                </RowActions>
              </tr>
            ))}
          </DataTable>
        )}
      </Card>

      <MerchantFormDialog merchant={editing} onClose={() => setEditing(null)} />
      <MerchantDetailDrawer merchantId={detailId} onClose={() => setDetailId(null)} onEdit={(m) => { setDetailId(null); setEditing(m); }} />
      <MerchantStatusDialog merchant={toggling} onClose={() => setToggling(null)} />
    </>
  );
}

/** Confirms activating / deactivating a Merchant account (row action and drawer toggle). */
function MerchantStatusDialog({ merchant, onClose }: { merchant: Merchant | null; onClose: () => void }) {
  const setMerchantStatus = useAppStore((s) => s.setMerchantStatus);
  const active = merchant?.status === 'active';
  return (
    <ConfirmDialog
      open={!!merchant}
      onClose={onClose}
      onConfirm={() => merchant && reportResult(setMerchantStatus(merchant.id, !active), active ? 'تم إيقاف حساب التاجر' : 'تم تفعيل حساب التاجر')}
      title={active ? `إيقاف حساب ${merchant?.businessName ?? ''}؟` : `تفعيل حساب ${merchant?.businessName ?? ''}؟`}
      description={active ? 'لن يتمكن التاجر من إنشاء طلبات جديدة. الطلبات القائمة لا تتأثر.' : 'سيتمكن التاجر من طلب الكباتن مجدداً.'}
      variant={active ? 'danger' : 'secondary'}
    />
  );
}

function MerchantDetailDrawer({ merchantId, onClose, onEdit }: { merchantId: string | null; onClose: () => void; onEdit: (m: Merchant) => void }) {
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const orders = useAppStore((s) => s.orders);
  const prices = useAppStore((s) => s.prices);
  const areas = useAppStore((s) => s.areas);
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
          <DetailRow label="الهاتف"><span dir="ltr">{merchant.phone}</span></DetailRow>
          <DetailRow label="المدينة">{merchant.cityId ? cityName(merchant.cityId) : <span className="text-ink-muted">غير محددة (سجل قديم)</span>}</DetailRow>
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
              <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
            </li>
          ))}
          {merchantOrders.length === 0 && <li className="py-4 text-center text-sm text-ink-muted">لا توجد طلبات بعد</li>}
        </ul>
      </Card>
      <MerchantStatusDialog merchant={confirm ? merchant : null} onClose={() => setConfirm(false)} />
    </Drawer>
  );
}
