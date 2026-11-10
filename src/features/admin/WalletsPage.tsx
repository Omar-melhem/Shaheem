import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Wallet, PlusCircle } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow, type CaptainView } from '@/application/hooks';
import { formatMoney } from '@/domain/money';
import { COMMISSION_BP_PROPOSED, formatPercentBp } from '@/domain/commission';
import { describeReasons } from '@/domain/eligibility';
import { Badge, Card, CardHeader, DataTable, EmptyState, IconAction, OpenDecision, PageHeader, RowActions, Select, SimTag } from '@/shared/components/ui';
import { formatDateTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { RechargeDialog } from './wallets/RechargeDialog';

const BALANCE_HEADERS = ['الكابتن', 'الرصيد', 'أهلية المحفظة', 'الأهلية العامة'];
const BALANCE_LEGEND = [{ icon: <PlusCircle />, label: 'شحن المحفظة (نفس نافذة الشحن في صفحة الكباتن، مع تأكيد)' }];
const TX_HEADERS = ['التاريخ', 'الكابتن', 'المبلغ', 'السبب', 'بواسطة'];

export function WalletsPage() {
  const now = useNow(10000);
  const views = useCaptainViews(now);
  const walletTx = useAppStore((s) => s.walletTx);
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
  const tx = walletTx.filter((t) => !filterCaptain || t.captainId === filterCaptain).sort((a, b) => b.createdAt - a.createdAt);

  return (
    <>
      <PageHeader
        title="محافظ الكباتن"
        description="شحن محافظ الكباتن ومراجعة سجل الحركات. الرصيد محسوب من سجل الحركات (دفتر قيود إلحاقي)."
        actions={<SimTag>الشحن محاكاة — ليس تحويلاً بنكياً</SimTag>}
      />
      <div className="mb-4 space-y-2">
        <p className="rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-900" role="status">
          <b>عمولة شهم {formatPercentBp(COMMISSION_BP_PROPOSED)} من رسوم توصيل كل طلب مكتمل معتمدة لكنها غير مفعّلة:</b> الخصم يحتاج خادماً يضمن خصماً واحداً لكل طلب، ولا يُنفَّذ من المتصفح. لن تُخصم أي عمولة في هذا النموذج.
        </p>
        <OpenDecision id="O-020">
          يطبق هذا النموذج حداً تجريبياً للأهلية قدره {formatMoney(threshold)}. حجز العمولة عند القبول بانتظار تنفيذ الخادم وقرار مالك المنتج.
        </OpenDecision>
      </div>

      <div className="space-y-6">
        <Card className="overflow-hidden">
          <CardHeader title="الأرصدة والأهلية" />
            <DataTable headers={BALANCE_HEADERS} actionsLegend={BALANCE_LEGEND} minWidth={640}>
                {views.map((v) => {
                  const walletOk = v.balance > 0 && v.balance >= threshold;
                  return (
                    <tr key={v.captain.id}>
                      <td className="px-4 py-3 font-bold">{v.captain.fullName}</td>
                      <td className={cn('whitespace-nowrap px-4 py-3 text-base font-extrabold', !walletOk && 'text-red-700')}>{formatMoney(v.balance)}</td>
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
              <Select className="h-9 w-44" value={filterCaptain} onChange={(e) => setFilterCaptain(e.target.value)} aria-label="تصفية حسب الكابتن">
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
                  <td className="px-4 py-3 font-bold">{captainName(t.captainId)}</td>
                  <td className="whitespace-nowrap px-4 py-3 font-extrabold text-secondary" dir="ltr" style={{ textAlign: 'right' }}>+{formatMoney(t.amount)}</td>
                  <td className="px-4 py-3 text-xs">{t.reason}</td>
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
