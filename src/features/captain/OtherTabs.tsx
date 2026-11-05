import { useMemo, useState } from 'react';
import { History, Wallet } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { CaptainView } from '@/application/hooks';
import type { Captain } from '@/domain/types';
import { formatMoney, formatMoneyExact } from '@/domain/money';
import { FINAL_STATUSES } from '@/domain/orderStatus';
import { EmptyState, SimTag, Tabs } from '@/shared/components/ui';
import { CAPTAIN_COMMISSION_APPROVED_FILS } from '@/domain/commission';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDateTime } from '@/shared/lib/format';
import { SupportContactList } from '@/features/support/SupportContacts';
import { VEHICLE_LABEL } from '@/features/admin/CaptainsPage';

export function HistoryTab({ captainId }: { captainId: string }) {
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const [filter, setFilter] = useState<'all' | 'delivered' | 'cancelled'>('all');
  const mine = useMemo(
    () =>
      orders
        .filter((o) => o.captainId === captainId && FINAL_STATUSES.includes(o.status))
        .filter((o) => filter === 'all' || o.status === filter)
        .sort((a, b) => (b.deliveredAt ?? b.updatedAt) - (a.deliveredAt ?? a.updatedAt)),
    [orders, captainId, filter],
  );
  return (
    <div className="space-y-3 p-4">
      <h2 className="font-extrabold">الطلبات السابقة</h2>
      <Tabs value={filter} onChange={setFilter} items={[{ value: 'all', label: 'الكل' }, { value: 'delivered', label: 'مُسلّمة' }, { value: 'cancelled', label: 'ملغاة' }]} />
      {mine.length === 0 ? (
        <EmptyState icon={<History className="h-6 w-6" />} title="لا توجد طلبات سابقة" />
      ) : (
        <ul className="space-y-2">
          {mine.map((o) => (
            <li key={o.id} className="rounded-2xl bg-white p-3 shadow-card">
              <div className="flex items-center justify-between">
                <span className="font-mono text-sm font-bold" dir="ltr">{o.reference}</span>
                <OrderStatusBadge status={o.status} />
              </div>
              <p className="mt-1 text-sm">{merchants.find((m) => m.id === o.merchantId)?.businessName} ← {o.areaName}</p>
              <div className="mt-1 flex items-center justify-between text-xs text-ink-muted">
                <span>{formatDateTime(o.deliveredAt ?? o.updatedAt)}</span>
                <span className="font-bold text-ink">{formatMoney(o.deliveryPrice)}</span>
              </div>
            </li>
          ))}
        </ul>
      )}
      <p className="text-center text-[11px] text-ink-muted">المبلغ المعروض هو سعر التوصيل للطلب؛ مستحقات الكابتن لم تُحدد بعد (O-025).</p>
    </div>
  );
}

export function WalletTab({ view }: { view: CaptainView }) {
  const walletTx = useAppStore((s) => s.walletTx);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const tx = walletTx.filter((t) => t.captainId === view.captain.id).sort((a, b) => b.createdAt - a.createdAt);
  const sufficient = view.balance > 0 && view.balance >= threshold;
  return (
    <div className="space-y-3 p-4">
      <div className="rounded-2xl bg-secondary p-5 text-white shadow-card">
        <p className="flex items-center gap-2 text-sm text-white/80"><Wallet className="h-4 w-4" /> رصيد المحفظة</p>
        <p className="mt-1 text-4xl font-extrabold">{formatMoney(view.balance)}</p>
        <p className="mt-2 text-xs text-white/80">{sufficient ? 'الرصيد كافٍ لاستقبال العروض' : `الرصيد أقل من الحد المطلوب (${formatMoney(threshold)}) — لن تصلك عروض`}</p>
      </div>
      <p className="text-center text-xs text-ink-muted">شحن المحفظة يتم من إدارة شهم فقط.</p>
      <h3 className="pt-1 font-bold">سجل الحركات</h3>
      {tx.length === 0 ? (
        <EmptyState title="لا توجد حركات بعد" />
      ) : (
        <ul className="space-y-2">
          {tx.map((t) => (
            <li key={t.id} className="flex items-center gap-3 rounded-xl bg-white p-3 shadow-card">
              <div className="flex-1">
                <p className="text-sm font-bold">شحن رصيد</p>
                <p className="text-xs text-ink-muted">{formatDateTime(t.createdAt)}{t.reason ? ` · ${t.reason}` : ''}</p>
              </div>
              <span className="font-extrabold text-secondary" dir="ltr">+{formatMoney(t.amount)}</span>
            </li>
          ))}
        </ul>
      )}
      <div className="flex justify-center"><SimTag>حركات المحفظة محاكاة</SimTag></div>
      <p className="rounded-xl bg-amber-50 p-3 text-xs text-amber-900">عمولة شهم {formatMoneyExact(CAPTAIN_COMMISSION_APPROVED_FILS)} تُخصم بعد تأكيد تسليم كل طلب عند تفعيلها من الخادم. لا يتم خصم أي مبلغ في هذا النموذج.</p>
    </div>
  );
}

export function ProfileTab({ captain }: { captain: Captain }) {
  return (
    <div className="space-y-4 p-4">
      <section className="space-y-1 rounded-2xl bg-white p-4 shadow-card text-sm">
        <h2 className="mb-2 font-extrabold">حسابي</h2>
        <p><span className="text-ink-muted">الاسم:</span> {captain.fullName}</p>
        <p><span className="text-ink-muted">الهاتف:</span> <span dir="ltr">{captain.phone}</span></p>
        <p><span className="text-ink-muted">المركبة:</span> {VEHICLE_LABEL[captain.vehicleType]}{captain.vehicleDescription && ` — ${captain.vehicleDescription}`}</p>
        <p className="pt-2 text-xs text-ink-muted">تعديل البيانات يتم من خلال إدارة شهم.</p>
      </section>
      <section className="space-y-3">
        <h2 className="font-extrabold">الدعم والتواصل مع شهم</h2>
        <SupportContactList compact />
      </section>
    </div>
  );
}
