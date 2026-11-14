import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Eye, ReceiptText } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useNow } from '@/shared/hooks/application';
import type { OrderStatus } from '@/domain/types';
import { ORDER_STATUS_LABEL } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { Card, DataTable, EmptyState, IconAction, PageHeader, RowActions, Select, SearchField } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { OrderDetailDrawer } from './OrderDetailDrawer';

const PAGE_SIZE = 12;
const HEADERS = ['الطلب', 'التاجر', 'هاتف العميل', 'الوجهة / المنطقة', 'السعر', 'الكابتن', 'الحالة', 'آخر تحديث'];
const LEGEND = [{ icon: <Eye />, label: 'عرض تفاصيل الطلب وسجله ومحاولات التوزيع (والإلغاء حسب السياسة)' }];

export function OrdersPage() {
  const now = useNow(10000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const areas = useAppStore((s) => s.areas);
  const [q, setQ] = useState('');
  const [status, setStatus] = useState<OrderStatus | ''>('');
  // «طلبات التاجر» / «سجل الكابتن» row actions open this page pre-filtered (?merchant= / ?captain=).
  const [params] = useSearchParams();
  const [merchantId, setMerchantId] = useState(() => params.get('merchant') ?? '');
  const [captainId, setCaptainId] = useState(() => params.get('captain') ?? '');
  const [areaId, setAreaId] = useState('');
  const [page, setPage] = useState(0);
  const [detailId, setDetailId] = useState<string | null>(null);

  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';
  const captainName = (id?: string) => (id ? captains.find((c) => c.id === id)?.fullName ?? '—' : '—');

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return orders
      .filter((o) => !status || o.status === status)
      .filter((o) => !merchantId || o.merchantId === merchantId)
      .filter((o) => !captainId || o.captainId === captainId)
      .filter((o) => !areaId || o.areaId === areaId)
      .filter(
        (o) =>
          !needle ||
          [o.reference, o.customerPhone, o.destination.label].some((v) => v?.toLowerCase().includes(needle)),
      )
      .sort((a, b) => b.createdAt - a.createdAt);
  }, [orders, q, status, merchantId, captainId, areaId]);

  const pages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const visible = filtered.slice(page * PAGE_SIZE, page * PAGE_SIZE + PAGE_SIZE);
  const resetPage = <T,>(fn: (v: T) => void) => (v: T) => {
    fn(v);
    setPage(0);
  };

  return (
    <>
      <PageHeader title="الطلبات" description="البحث في طلبات التوصيل ومتابعتها. اضغط على أي طلب لعرض التفاصيل والسجل ومحاولات التوزيع." />

      <Card className="mb-4 grid gap-3 p-4 md:grid-cols-3 xl:grid-cols-6">
        <SearchField label="بحث" className="md:col-span-3 xl:col-span-2" placeholder="رقم الطلب، هاتف العميل، الوجهة" value={q} onChange={(e) => resetPage(setQ)(e.target.value)} />
        <Select aria-label="الحالة" value={status} onChange={(e) => resetPage(setStatus)(e.target.value as OrderStatus | '')}>
          <option value="">كل الحالات</option>
          {(Object.keys(ORDER_STATUS_LABEL) as OrderStatus[]).map((s) => (
            <option key={s} value={s}>
              {ORDER_STATUS_LABEL[s]}
            </option>
          ))}
        </Select>
        <Select aria-label="التاجر" value={merchantId} onChange={(e) => resetPage(setMerchantId)(e.target.value)}>
          <option value="">كل التجار</option>
          {merchants.map((m) => (
            <option key={m.id} value={m.id}>
              {m.businessName}
            </option>
          ))}
        </Select>
        <Select aria-label="الكابتن" value={captainId} onChange={(e) => resetPage(setCaptainId)(e.target.value)}>
          <option value="">كل الكباتن</option>
          {captains.map((c) => (
            <option key={c.id} value={c.id}>
              {c.fullName}
            </option>
          ))}
        </Select>
        <Select aria-label="المنطقة" value={areaId} onChange={(e) => resetPage(setAreaId)(e.target.value)}>
          <option value="">كل المناطق</option>
          {areas.map((a) => (
            <option key={a.id} value={a.id}>
              {a.name}
            </option>
          ))}
        </Select>
      </Card>

      <Card className="overflow-hidden">
        {visible.length === 0 ? (
          <EmptyState icon={<ReceiptText className="h-6 w-6" />} title="لا توجد طلبات مطابقة" description="جرّب تعديل عوامل التصفية." />
        ) : (
          <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={1020}>
                {visible.map((o) => (
                  <tr key={o.id}>
                    <td className="px-4 py-3">
                      <p className="font-mono font-bold text-ink" dir="ltr" style={{ textAlign: 'right' }}>{o.reference}</p>
                      <p className="text-xs text-ink-muted">{formatDateTime(o.createdAt)}</p>
                    </td>
                    <td className="px-4 py-3 font-medium">{merchantName(o.merchantId)}</td>
                    <td className="px-4 py-3">
                      {o.customerPhone ? <span dir="ltr">{o.customerPhone}</span> : <span className="text-ink-muted">—</span>}
                    </td>
                    <td className="px-4 py-3">
                      {o.destination.label}
                      <p className="text-xs text-ink-muted">{o.areaName}</p>
                    </td>
                    <td className="whitespace-nowrap px-4 py-3 font-bold">{formatMoney(o.deliveryPrice)}</td>
                    <td className="px-4 py-3">{captainName(o.captainId)}</td>
                    <td className="px-4 py-3">
                      <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
                    </td>
                    <td className="px-4 py-3 text-xs text-ink-muted">{formatRelative(o.updatedAt, now)}</td>
                    <RowActions>
                      <IconAction icon={<Eye />} label="عرض التفاصيل والسجل" onClick={() => setDetailId(o.id)} />
                    </RowActions>
                  </tr>
                ))}
          </DataTable>
        )}
        <div className="flex items-center justify-between border-t border-cream-dark px-4 py-3 text-sm">
          <span className="text-ink-muted">{filtered.length} طلب</span>
          <div className="flex items-center gap-2">
            <button className="h-9 rounded-lg px-3 font-bold hover:bg-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 disabled:opacity-40" disabled={page === 0} onClick={() => setPage((p) => p - 1)}>
              السابق
            </button>
            <span className="text-ink-muted">
              {page + 1} / {pages}
            </span>
            <button className="h-9 rounded-lg px-3 font-bold hover:bg-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 disabled:opacity-40" disabled={page >= pages - 1} onClick={() => setPage((p) => p + 1)}>
              التالي
            </button>
          </div>
        </div>
      </Card>

      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
    </>
  );
}
