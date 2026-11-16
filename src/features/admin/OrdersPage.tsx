import { useEffect, useMemo, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Eye, ReceiptText, RotateCcw, SlidersHorizontal } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useNow } from '@/shared/hooks/application';
import { formatMoney } from '@/domain/money';
import { Button, Card, DataTable, EmptyState, IconAction, PageHeader, RowActions, SearchField } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { OrderDetailDrawer } from './OrderDetailDrawer';
import { ActiveFilterChips, activeFilterCount, EMPTY_ORDER_FILTERS, OrderFilterFields, OrderFiltersSheet, type OrderFilterValues } from './orders/OrderFilters';

const PAGE_SIZE = 12;
const HEADERS = ['الطلب', 'التاجر', 'هاتف العميل', 'الوجهة / المنطقة', 'السعر', 'الكابتن', 'الحالة', 'آخر تحديث'];
const LEGEND = [{ icon: <Eye />, label: 'عرض تفاصيل الطلب وسجله ومحاولات التوزيع (والإلغاء حسب السياسة)' }];
/** Same breakpoint as Tailwind `md`: from here the filters sit inline; below it they live in the sheet. */
const INLINE_FILTERS_QUERY = '(min-width: 768px)';
const PAGER_BUTTON = 'h-9 rounded-lg px-3 font-bold hover:bg-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 disabled:opacity-40';

export function OrdersPage() {
  const now = useNow(10000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const [q, setQ] = useState('');
  // «طلبات التاجر» / «سجل الكابتن» row actions open this page pre-filtered (?merchant= / ?captain=).
  const [params] = useSearchParams();
  const [filters, setFilters] = useState<OrderFilterValues>(() => ({
    ...EMPTY_ORDER_FILTERS,
    merchantId: params.get('merchant') ?? '',
    captainId: params.get('captain') ?? '',
  }));
  const [sheetOpen, setSheetOpen] = useState(false);
  const filterButtonRef = useRef<HTMLButtonElement>(null);
  const [page, setPage] = useState(0);
  const [detailId, setDetailId] = useState<string | null>(null);

  // Widening past the phone layout closes the sheet; the applied filters are untouched.
  useEffect(() => {
    const mq = typeof window.matchMedia === 'function' ? window.matchMedia(INLINE_FILTERS_QUERY) : null;
    if (!mq) return;
    const onChange = () => mq.matches && setSheetOpen(false);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';
  const captainName = (id?: string) => (id ? captains.find((c) => c.id === id)?.fullName ?? '—' : '—');

  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    const { status, merchantId, captainId, areaId } = filters;
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
  }, [orders, q, filters]);

  const pages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const current = Math.min(page, pages - 1);
  const visible = filtered.slice(current * PAGE_SIZE, current * PAGE_SIZE + PAGE_SIZE);
  const activeCount = activeFilterCount(filters);

  const applyFilters = (next: OrderFilterValues) => {
    setFilters(next);
    setPage(0);
  };
  const patchFilters = (patch: Partial<OrderFilterValues>) => applyFilters({ ...filters, ...patch });
  const clearAll = () => {
    setQ('');
    applyFilters(EMPTY_ORDER_FILTERS);
  };
  const closeSheet = () => {
    setSheetOpen(false);
    filterButtonRef.current?.focus();
  };

  return (
    <>
      <PageHeader title="الطلبات" description="البحث في طلبات التوصيل ومتابعتها. اضغط على رقم الطلب لعرض التفاصيل والسجل ومحاولات التوزيع." />

      <Card className="mb-4 space-y-3 p-4">
        <div className="grid gap-3 md:grid-cols-3 xl:grid-cols-6">
          <SearchField
            label="بحث"
            className="md:col-span-3 xl:col-span-2"
            placeholder="رقم الطلب، هاتف العميل، الوجهة"
            value={q}
            onChange={(e) => {
              setQ(e.target.value);
              setPage(0);
            }}
          />
          <OrderFilterFields value={filters} onChange={patchFilters} itemClassName="hidden md:block" />
          <div className="flex items-center gap-2 md:hidden">
            <Button
              ref={filterButtonRef}
              variant="outline"
              className="h-11"
              icon={<SlidersHorizontal className="h-4 w-4" aria-hidden />}
              onClick={() => setSheetOpen(true)}
              aria-haspopup="dialog"
              aria-expanded={sheetOpen}
              aria-label={activeCount ? `تصفية، ${activeCount} فلاتر مطبّقة` : 'تصفية'}
            >
              تصفية
              {activeCount > 0 && (
                <span className="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1.5 text-[11px] text-white" aria-hidden>
                  {activeCount}
                </span>
              )}
            </Button>
            <span className="ms-auto text-sm text-ink-muted" aria-live="polite">{filtered.length} طلب</span>
          </div>
        </div>
        <div className="empty:hidden md:hidden">
          <ActiveFilterChips value={filters} onRemove={(k) => patchFilters({ [k]: '' })} onClearAll={() => applyFilters(EMPTY_ORDER_FILTERS)} />
        </div>
      </Card>

      <Card className="overflow-hidden">
        {visible.length === 0 ? (
          <EmptyState
            icon={<ReceiptText className="h-6 w-6" />}
            title="لا توجد طلبات مطابقة"
            description="جرّب تعديل عوامل التصفية."
            action={(activeCount > 0 || q.trim()) && <Button variant="outline" icon={<RotateCcw className="h-4 w-4" />} onClick={clearAll}>مسح البحث والفلاتر</Button>}
          />
        ) : (
          <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={1020}>
            {visible.map((o) => (
              <tr key={o.id}>
                <td className="px-4 py-3">
                  <button type="button" onClick={() => setDetailId(o.id)} className="font-mono font-bold text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300" aria-label={`عرض تفاصيل الطلب ${o.reference}`}>
                    <span dir="ltr">{o.reference}</span>
                  </button>
                  <p className="text-xs text-ink-muted">{formatDateTime(o.createdAt)}</p>
                </td>
                <td className="px-4 py-3 font-medium">{merchantName(o.merchantId)}</td>
                <td className="whitespace-nowrap px-4 py-3">
                  {o.customerPhone ? <span dir="ltr">{o.customerPhone}</span> : <span className="text-ink-muted">غير مضاف</span>}
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
            <button className={PAGER_BUTTON} disabled={current === 0} onClick={() => setPage(current - 1)}>
              السابق
            </button>
            <span className="text-ink-muted">
              {current + 1} / {pages}
            </span>
            <button className={PAGER_BUTTON} disabled={current >= pages - 1} onClick={() => setPage(current + 1)}>
              التالي
            </button>
          </div>
        </div>
      </Card>

      <OrderFiltersSheet
        open={sheetOpen}
        applied={filters}
        onClose={closeSheet}
        onApply={(next) => {
          applyFilters(next);
          closeSheet();
        }}
      />
      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
    </>
  );
}
