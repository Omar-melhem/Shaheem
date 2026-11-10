import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Eye, MapPin, Pencil, Plus, Power, RotateCcw, Star, Users, Wallet } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow, type CaptainView } from '@/application/hooks';
import type { Captain } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { describeReasons } from '@/domain/eligibility';
import { Badge, Button, Card, DataTable, Dialog, EmptyState, IconAction, PageHeader, RowActions, SearchField, Select } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge } from '@/shared/components/StatusBadge';
import { formatRelative } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { RechargeDialog } from '../wallets/RechargeDialog';
import { CaptainFormDialog } from './CaptainFormDialog';
import { CaptainDetailDrawer } from './CaptainDetailDrawer';
import { CaptainRatingForm } from './CaptainRatingForm';
import { CaptainStatusDialog } from './CaptainStatusDialog';

type AccountFilter = '' | 'active' | 'inactive';
type AvailabilityFilter = '' | 'available' | 'busy' | 'offline';

/** Availability as shown to Admin: busy while delivering, otherwise the Captain's own switch. */
const availabilityOf = (v: CaptainView): Exclude<AvailabilityFilter, ''> => (v.activeOrderId ? 'busy' : v.captain.availability === 'available' ? 'available' : 'offline');
const AVAILABILITY_LABEL = { available: 'متاح', busy: 'في توصيل', offline: 'غير متاح' } as const;

const HEADERS = ['الكابتن', 'الحساب', 'التوفر', 'الأهلية للعروض', 'آخر موقع', 'المحفظة', 'التقييم', 'المكتملة'];
const LEGEND = [
  { icon: <Eye />, label: 'عرض التفاصيل' },
  { icon: <Pencil />, label: 'تعديل البيانات' },
  { icon: <Wallet />, label: 'شحن المحفظة' },
  { icon: <Star />, label: 'تقييم الكابتن' },
  { icon: <MapPin />, label: 'فتح الموقع على الخريطة' },
  { icon: <Power />, label: 'تفعيل / إيقاف الحساب' },
];

export function CaptainsPage() {
  const now = useNow(5000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [params, setParams] = useSearchParams();
  const [q, setQ] = useState('');
  const [account, setAccount] = useState<AccountFilter>('');
  const [availability, setAvailability] = useState<AvailabilityFilter>('');
  const [editing, setEditing] = useState<Captain | 'new' | null>(null);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [recharging, setRecharging] = useState<CaptainView | null>(null);
  const [rating, setRating] = useState<Captain | null>(null);
  const [toggling, setToggling] = useState<Captain | null>(null);

  useEffect(() => {
    if (params.get('new')) {
      setEditing('new');
      setParams({}, { replace: true });
    }
  }, [params, setParams]);

  const needle = q.trim();
  const filtered = views.filter(
    (v) =>
      (!needle || [v.captain.fullName, v.captain.phone].some((x) => x.includes(needle))) &&
      (!account || v.captain.status === account) &&
      (!availability || availabilityOf(v) === availability),
  );
  const filtering = !!(needle || account || availability);
  const reset = () => {
    setQ('');
    setAccount('');
    setAvailability('');
  };

  return (
    <>
      <PageHeader
        title="الكباتن"
        description="تسجيل الكباتن ومتابعة التوفر والأهلية والموقع والمحفظة."
        actions={<Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing('new')}>إضافة كابتن</Button>}
      />
      <Card className="mb-4 flex flex-wrap items-end gap-3 p-4">
        <SearchField label="بحث في الكباتن" className="min-w-[220px] max-w-md flex-1" placeholder="ابحث بالاسم أو الهاتف" value={q} onChange={(e) => setQ(e.target.value)} />
        <div className="w-full sm:w-44">
        <Select aria-label="حالة الحساب" value={account} onChange={(e) => setAccount(e.target.value as AccountFilter)}>
          <option value="">كل الحسابات</option>
          <option value="active">مفعّل</option>
          <option value="inactive">موقوف</option>
        </Select>
        </div>
        <div className="w-full sm:w-48">
        <Select aria-label="حالة التوفر" value={availability} onChange={(e) => setAvailability(e.target.value as AvailabilityFilter)}>
          <option value="">كل حالات التوفر</option>
          <option value="available">{AVAILABILITY_LABEL.available}</option>
          <option value="busy">{AVAILABILITY_LABEL.busy}</option>
          <option value="offline">{AVAILABILITY_LABEL.offline}</option>
        </Select>
        </div>
        {filtering && <Button variant="ghost" icon={<RotateCcw className="h-4 w-4" />} onClick={reset}>مسح الفلاتر</Button>}
        <p className="ms-auto text-sm text-ink-muted" aria-live="polite">{filtered.length} من {views.length} كابتن</p>
      </Card>
      <Card className="overflow-hidden">
        {filtered.length === 0 ? (
          <EmptyState icon={<Users className="h-6 w-6" />} title="لا يوجد كباتن مطابقون" />
        ) : (
          <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={1080}>
            {filtered.map((v) => {
              const c = v.captain;
              const avail = availabilityOf(v);
              return (
                <tr key={c.id}>
                  <td className="px-4 py-3">
                    <p className="whitespace-nowrap font-bold text-ink">{c.fullName}</p>
                    <p className="text-xs text-ink-muted" dir="ltr" style={{ textAlign: 'right' }}>{c.phone}</p>
                  </td>
                  <td className="px-4 py-3"><Badge tone={c.status === 'active' ? 'success' : 'danger'} dot>{c.status === 'active' ? 'مفعّل' : 'موقوف'}</Badge></td>
                  <td className="px-4 py-3">{c.status === 'active' ? <CaptainStatusBadge status={avail} /> : <span className="text-xs text-ink-muted">—</span>}</td>
                  <td className="max-w-[220px] px-4 py-3">
                    {v.eligibility.eligible ? <Badge tone="success">مؤهل</Badge> : <span className="text-xs text-red-700">{describeReasons(v.eligibility.reasons)}</span>}
                  </td>
                  <td className="px-4 py-3">
                    <FreshnessBadge freshness={v.freshness} />
                    {c.lastLocation && <p className="mt-0.5 text-[11px] text-ink-muted">{formatRelative(c.lastLocation.recordedAt, now)}</p>}
                  </td>
                  <td className={cn('whitespace-nowrap px-4 py-3 font-bold', v.balance < threshold && 'text-red-700')}>{formatMoney(v.balance)}</td>
                  <td className="whitespace-nowrap px-4 py-3 text-xs">{c.rating ? `${'★'.repeat(c.rating)}${'☆'.repeat(5 - c.rating)}` : <span className="text-ink-muted">—</span>}</td>
                  <td className="px-4 py-3">{orders.filter((o) => o.captainId === c.id && o.status === 'delivered').length}</td>
                  <RowActions>
                    <IconAction icon={<Eye />} label="عرض التفاصيل" onClick={() => setDetailId(c.id)} />
                    <IconAction icon={<Pencil />} label="تعديل البيانات" onClick={() => setEditing(c)} />
                    <IconAction icon={<Wallet />} label="شحن المحفظة" tone="secondary" onClick={() => setRecharging(v)} />
                    <IconAction icon={<Star />} label="تقييم الكابتن" onClick={() => setRating(c)} />
                    <IconAction icon={<MapPin />} label="فتح الموقع على الخريطة" to={`/admin/map?captain=${c.id}`} disabled={!c.lastLocation} />
                    <IconAction icon={<Power />} label={c.status === 'active' ? 'إيقاف الحساب' : 'تفعيل الحساب'} tone={c.status === 'active' ? 'danger' : 'secondary'} onClick={() => setToggling(c)} />
                  </RowActions>
                </tr>
              );
            })}
          </DataTable>
        )}
      </Card>

      <CaptainFormDialog captain={editing} onClose={() => setEditing(null)} />
      <CaptainDetailDrawer
        captainId={detailId}
        onClose={() => setDetailId(null)}
        onEdit={(c) => { setDetailId(null); setEditing(c); }}
        onRecharge={(view) => setRecharging(view)}
      />
      <RechargeDialog view={recharging} onClose={() => setRecharging(null)} />
      <CaptainStatusDialog captain={toggling} onClose={() => setToggling(null)} />
      <Dialog open={!!rating} onClose={() => setRating(null)} size="sm" title={`تقييم ${rating?.fullName ?? ''}`}>
        {rating && <CaptainRatingForm key={rating.id} captain={rating} onSaved={() => setRating(null)} />}
      </Dialog>
    </>
  );
}
