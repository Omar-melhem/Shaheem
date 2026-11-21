import { useEffect, useState } from 'react';
import { X } from 'lucide-react';
import { useAppStore } from '@/app/state';
import type { OrderStatus } from '@/domain/types';
import { ORDER_STATUS_LABEL } from '@/domain/orderStatus';
import { Button, Drawer, Select } from '@/shared/components/ui';

/** The applied order filters (search is separate and always visible). One state for every layout. */
export interface OrderFilterValues {
  status: OrderStatus | '';
  merchantId: string;
  captainId: string;
  areaId: string;
}

export const EMPTY_ORDER_FILTERS: OrderFilterValues = { status: '', merchantId: '', captainId: '', areaId: '' };

const KEYS = ['status', 'merchantId', 'captainId', 'areaId'] as const;

export const activeFilterCount = (f: OrderFilterValues) => KEYS.filter((k) => f[k]).length;

/** The four selects, shared by the desktop toolbar and the phone sheet. */
export function OrderFilterFields({
  value,
  onChange,
  itemClassName,
}: {
  value: OrderFilterValues;
  onChange: (patch: Partial<OrderFilterValues>) => void;
  itemClassName?: string;
}) {
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const areas = useAppStore((s) => s.areas);
  return (
    <>
      <div className={itemClassName}>
        <Select aria-label="الحالة" value={value.status} onChange={(e) => onChange({ status: e.target.value as OrderStatus | '' })}>
          <option value="">كل الحالات</option>
          {(Object.keys(ORDER_STATUS_LABEL) as OrderStatus[]).map((s) => <option key={s} value={s}>{ORDER_STATUS_LABEL[s]}</option>)}
        </Select>
      </div>
      <div className={itemClassName}>
        <Select aria-label="التاجر" value={value.merchantId} onChange={(e) => onChange({ merchantId: e.target.value })}>
          <option value="">كل التجار</option>
          {merchants.map((m) => <option key={m.id} value={m.id}>{m.businessName}</option>)}
        </Select>
      </div>
      <div className={itemClassName}>
        <Select aria-label="الكابتن" value={value.captainId} onChange={(e) => onChange({ captainId: e.target.value })}>
          <option value="">كل الكباتن</option>
          {captains.map((c) => <option key={c.id} value={c.id}>{c.fullName}</option>)}
        </Select>
      </div>
      <div className={itemClassName}>
        <Select aria-label="المنطقة" value={value.areaId} onChange={(e) => onChange({ areaId: e.target.value })}>
          <option value="">كل المناطق</option>
          {areas.map((a) => <option key={a.id} value={a.id}>{a.name}</option>)}
        </Select>
      </div>
    </>
  );
}

/**
 * Phone filter sheet. Policy: edits are a draft — nothing changes until «تطبيق الفلاتر»;
 * closing discards the draft. «إعادة ضبط» clears the draft only.
 */
export function OrderFiltersSheet({
  open,
  applied,
  onApply,
  onClose,
}: {
  open: boolean;
  applied: OrderFilterValues;
  onApply: (next: OrderFilterValues) => void;
  onClose: () => void;
}) {
  const [draft, setDraft] = useState(applied);
  useEffect(() => {
    if (open) setDraft(applied);
  }, [open, applied]);
  return (
    <Drawer
      open={open}
      onClose={onClose}
      title="تصفية الطلبات"
      subtitle="لا تتغير النتائج حتى تضغط «تطبيق الفلاتر»."
      footer={
        <>
          <Button variant="ghost" onClick={() => setDraft(EMPTY_ORDER_FILTERS)} disabled={activeFilterCount(draft) === 0}>إعادة ضبط</Button>
          <Button onClick={() => onApply(draft)}>تطبيق الفلاتر</Button>
        </>
      }
    >
      <div className="space-y-3 rounded-xl bg-white p-4">
        <OrderFilterFields value={draft} onChange={(patch) => setDraft((d) => ({ ...d, ...patch }))} />
      </div>
    </Drawer>
  );
}

/** Removable chips for the applied filters (phones), so the active filters stay visible while the sheet is closed. */
export function ActiveFilterChips({
  value,
  onRemove,
  onClearAll,
}: {
  value: OrderFilterValues;
  onRemove: (key: keyof OrderFilterValues) => void;
  onClearAll: () => void;
}) {
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const areas = useAppStore((s) => s.areas);
  const label: Record<keyof OrderFilterValues, string | undefined> = {
    status: value.status ? ORDER_STATUS_LABEL[value.status] : undefined,
    merchantId: merchants.find((m) => m.id === value.merchantId)?.businessName,
    captainId: captains.find((c) => c.id === value.captainId)?.fullName,
    areaId: areas.find((a) => a.id === value.areaId)?.name,
  };
  const active = KEYS.filter((k) => value[k]);
  if (active.length === 0) return null;
  return (
    <ul className="flex flex-wrap items-center gap-2" aria-label="الفلاتر المطبّقة">
      {active.map((k) => (
        <li key={k}>
          <span className="inline-flex h-9 items-center gap-1 rounded-full bg-primary-50 ps-3 pe-1 text-xs font-bold text-primary">
            {label[k] ?? value[k]}
            <button type="button" aria-label={`إزالة فلتر ${label[k] ?? ''}`} onClick={() => onRemove(k)} className="inline-flex h-7 w-7 items-center justify-center rounded-full hover:bg-primary-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300">
              <X className="h-3.5 w-3.5" aria-hidden />
            </button>
          </span>
        </li>
      ))}
      <li>
        <button type="button" onClick={onClearAll} className="h-9 rounded-lg px-2 text-xs font-bold text-ink-soft underline-offset-4 hover:underline">مسح الكل</button>
      </li>
    </ul>
  );
}
