import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Wallet, PlusCircle } from 'lucide-react';
import { useAppStore, captainHeldCommission } from '@/app/state';
import type { WalletTransaction } from '@/domain/types';
import { useCaptainViews, useNow, type CaptainView } from '@/shared/hooks/application';
import { formatMoney } from '@/domain/money';
import { formatPercentBp } from '@/domain/commission';
import { MAX_TOPUP_FILS } from '@/domain/wallet';
import { describeReasons } from '@/domain/eligibility';
import { Badge, Card, CardHeader, DataTable, EmptyState, IconAction, OpenDecision, PageHeader, RowActions, Select, SimTag } from '@/shared/components/ui';
import { formatDateTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { RechargeDialog } from './wallets/RechargeDialog';

const BALANCE_HEADERS = ['الكابتن', 'الرصيد', 'عمولة محجوزة', 'أهلية المحفظة', 'الأهلية العامة'];
const BALANCE_LEGEND = [{ icon: <PlusCircle />, label: 'شحن المحفظة (نفس نافذة الشحن في صفحة الكباتن، مع تأكيد)' }];
const TX_HEADERS = ['التاريخ', 'الكابتن', 'المبلغ', 'الحركة', 'بواسطة'];

export function WalletsPage() {
  const now = useNow(10000);
  const views = useCaptainViews(now);
  const walletTx = useAppStore((s) => s.walletTx);
  const orders = useAppStore((s) => s.orders);
  const commissionBp = useAppStore((s) => s.settings.commissionBp);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [params, setParams] = useSearchParams();
  const [filterCaptain, setFilterCaptain] = useState('');
  const [rechargeFor, setRechargeFor] = useState<CaptainView | null>(null);

  useEffect(() => {
    const id = params.get('captain');
    if (id) {
      const v = views.find((x) => x.captain.id === id);
      if (v) setRechargeFor(v);
      setParams({}, { replace: true });
    }
  }, [params, setParams, views]);

  const captainName = (id: string) => views.find((v) => v.captain.id === id)?.captain.fullName ?? '—';
  const describeTx = (t: WalletTransaction) => {
    if (t.type === 'recharge') return t.reason ?? 'شحن رصيد';
    const order = orders.find((o) => o.id === t.orderId);
    return `عمولة شهم${t.commissionBp !== undefined ? ` ${formatPercentBp(t.commissionBp)}` : ''} — الطلب ${order?.reference ?? '—'}${order ? ` (رسوم ${formatMoney(order.deliveryPrice)})` : ''}`;
  };
  const tx = walletTx.filter((t) => !filterCaptain || t.captainId === filterCaptain).sort((a, b) => b.createdAt - a.createdAt);

  return (
    <>
      <PageHeader
        title="محافظ الكباتن"
        description="شحن محافظ الكباتن ومراجعة سجل الحركات. الرصيد محسوب من سجل الحركات (دفتر قيود إلحاقي): الشحن مضاف، وعمولة كل طلب مسلَّم مخصومة مرة واحدة."
        actions={<SimTag>دفتر قيود تجريبي — ليس تحويلاً بنكياً</SimTag>}
      />
      <div className="mb-4 space-y-2">
        <p className="rounded-xl border border-cream-deep bg-white px-4 py-3 text-sm text-ink-soft" role="status">
          عمولة شهم الحالية <b className="text-ink" dir="ltr">{formatPercentBp(commissionBp)}</b> من رسوم التوصيل: تُحجز عند قبول الكابتن للطلب، وتُخصم مرة واحدة عند التسليم. الإلغاء قبل التسليم لا يخصم شيئاً. الطلبات المقبولة قبل تفعيل العمولة لا تُخصم.
        </p>
        <OpenDecision id="بانتظار التأكيد">
          حد الشحن {formatMoney(MAX_TOPUP_FILS)} مفهوم كحد للعملية الواحدة وليس حداً للرصيد. حد الأهلية التجريبي {formatMoney(threshold)} (O-020). هذا الدفتر في المتصفح للعرض فقط؛ الخصم الآمن والمعاملة الواحدة يحتاجان الخادم.
        </OpenDecision>
      </div>

      <div className="space-y-6">
        <Card className="overflow-hidden">
          <CardHeader title="الأرصدة والأهلية" />
            <DataTable headers={BALANCE_HEADERS} actionsLegend={BALANCE_LEGEND} minWidth={720}>
                {views.map((v) => {
                  const walletOk = v.balance > 0 && v.balance >= threshold;
                  return (
                    <tr key={v.captain.id}>
                      <td className="whitespace-nowrap px-4 py-3 font-bold">{v.captain.fullName}</td>
                      <td className={cn('whitespace-nowrap px-4 py-3 text-base font-extrabold', !walletOk && 'text-red-700')}>{formatMoney(v.balance)}</td>
                      <td className="whitespace-nowrap px-4 py-3 text-sm text-ink-soft">{formatMoney(captainHeldCommission({ orders }, v.captain.id))}</td>
                      <td className="px-4 py-3">{walletOk ? <Badge tone="success">كافٍ</Badge> : <Badge tone="danger">غير كافٍ</Badge>}</td>
                      <td className="max-w-[260px] px-4 py-3 text-xs">{v.eligibility.eligible ? <Badge tone="success">مؤهل</Badge> : <span className="text-ink-muted">{describeReasons(v.eligibility.reasons)}</span>}</td>
                      <RowActions>
                        <IconAction icon={<PlusCircle />} label={`شحن محفظة ${v.captain.fullName}`} tone="secondary" onClick={() => setRechargeFor(v)} />
                      </RowActions>
                    </tr>
                  );
                })}
            </DataTable>
        </Card>

        <Card className="overflow-hidden">
          <CardHeader
            title="سجل الحركات"
            actions={
              <Select className="w-44" value={filterCaptain} onChange={(e) => setFilterCaptain(e.target.value)} aria-label="تصفية حسب الكابتن">
                <option value="">كل الكباتن</option>
                {views.map((v) => <option key={v.captain.id} value={v.captain.id}>{v.captain.fullName}</option>)}
              </Select>
            }
          />
          {tx.length === 0 ? (
            <EmptyState icon={<Wallet className="h-6 w-6" />} title="لا توجد حركات" />
          ) : (
            <DataTable headers={TX_HEADERS} minWidth={640}>
              {tx.map((t) => (
                <tr key={t.id}>
                  <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-soft">{formatDateTime(t.createdAt)}</td>
                  <td className="whitespace-nowrap px-4 py-3 font-bold">{captainName(t.captainId)}</td>
                  <td className={cn('whitespace-nowrap px-4 py-3 font-extrabold', t.amount < 0 ? 'text-primary' : 'text-secondary')}><span dir="ltr">{t.amount < 0 ? '−' : '+'}{formatMoney(Math.abs(t.amount))}</span></td>
                  <td className="px-4 py-3 text-xs">{describeTx(t)}</td>
                  <td className="px-4 py-3 text-xs text-ink-muted">{t.actor.name}</td>
                </tr>
              ))}
            </DataTable>
          )}
        </Card>
      </div>

      <RechargeDialog view={rechargeFor} onClose={() => setRechargeFor(null)} />
    </>
  );
}
