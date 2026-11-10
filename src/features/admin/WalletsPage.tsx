import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Wallet, PlusCircle } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow, type CaptainView } from '@/application/hooks';
import { formatMoney, parseJodInput } from '@/domain/money';
import { COMMISSION_BP_PROPOSED, formatPercentBp } from '@/domain/commission';
import { describeReasons } from '@/domain/eligibility';
import { Badge, Button, Card, CardHeader, Dialog, EmptyState, Field, Input, OpenDecision, PageHeader, Select, SimTag } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

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

      <div className="grid gap-6 xl:grid-cols-5">
        <Card className="xl:col-span-3">
          <CardHeader title="الأرصدة والأهلية" />
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <thead className="bg-cream text-xs text-ink-muted">
                <tr>
                  {['الكابتن', 'الرصيد', 'أهلية المحفظة', 'الأهلية العامة', ''].map((h, i) => (
                    <th key={i} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-cream-dark">
                {views.map((v) => {
                  const walletOk = v.balance > 0 && v.balance >= threshold;
                  return (
                    <tr key={v.captain.id} className="hover:bg-cream/60">
                      <td className="px-4 py-3 font-bold">{v.captain.fullName}</td>
                      <td className={cn('px-4 py-3 text-base font-extrabold', !walletOk && 'text-red-700')}>{formatMoney(v.balance)}</td>
                      <td className="px-4 py-3">{walletOk ? <Badge tone="success">كافٍ</Badge> : <Badge tone="danger">غير كافٍ</Badge>}</td>
                      <td className="max-w-[200px] px-4 py-3 text-xs">{v.eligibility.eligible ? <Badge tone="success">مؤهل</Badge> : <span className="text-ink-muted">{describeReasons(v.eligibility.reasons)}</span>}</td>
                      <td className="px-4 py-3">
                        <Button size="sm" variant="secondary" icon={<PlusCircle className="h-4 w-4" />} onClick={() => setRechargeFor(v)}>شحن</Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </Card>

        <Card className="xl:col-span-2">
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
            <ul className="max-h-[520px] divide-y divide-cream-dark overflow-y-auto">
              {tx.map((t) => (
                <li key={t.id} className="flex items-start gap-3 px-5 py-3">
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-bold">{captainName(t.captainId)}</p>
                    <p className="text-xs text-ink-muted">{t.reason} · بواسطة {t.actor.name}</p>
                    <p className="text-xs text-ink-muted">{formatDateTime(t.createdAt)}</p>
                  </div>
                  <span className="font-extrabold text-secondary" dir="ltr">+{formatMoney(t.amount)}</span>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      <RechargeDialog view={rechargeFor} onClose={() => setRechargeFor(null)} />
    </>
  );
}

function RechargeDialog({ view, onClose }: { view: CaptainView | null; onClose: () => void }) {
  const rechargeWallet = useAppStore((s) => s.rechargeWallet);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [amount, setAmount] = useState('');
  const [reason, setReason] = useState('');
  const [step, setStep] = useState<'form' | 'review'>('form');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setAmount('');
    setReason('');
    setStep('form');
    setError(null);
  }, [view?.captain.id]);

  if (!view) return null;
  const fils = parseJodInput(amount);

  const review = () => {
    if (fils === null || fils <= 0) return setError('أدخل مبلغاً موجباً، مثل 5 أو 2.5');
    setError(null);
    setStep('review');
  };
  const confirm = () => {
    if (submitting || fils === null) return;
    setSubmitting(true);
    const ok = reportResult(rechargeWallet(view.captain.id, fils, reason), `تم شحن محفظة ${view.captain.fullName} بمبلغ ${formatMoney(fils)} (محاكاة)`);
    setSubmitting(false);
    if (ok) onClose();
  };

  return (
    <Dialog
      open
      onClose={onClose}
      size="sm"
      title={`شحن محفظة ${view.captain.fullName}`}
      description={`الرصيد الحالي ${formatMoney(view.balance)}`}
      footer={
        step === 'form' ? (
          <>
            <Button variant="outline" onClick={onClose}>إلغاء</Button>
            <Button onClick={review}>مراجعة</Button>
          </>
        ) : (
          <>
            <Button variant="outline" onClick={() => setStep('form')}>رجوع</Button>
            <Button variant="secondary" onClick={confirm} loading={submitting}>تأكيد الشحن</Button>
          </>
        )
      }
    >
      {step === 'form' ? (
        <div className="space-y-4">
          <Field label="المبلغ (د.أ)" required error={error}>
            <Input value={amount} onChange={(e) => setAmount(e.target.value)} inputMode="decimal" dir="ltr" placeholder="5.000" aria-invalid={!!error} onKeyDown={(e) => e.key === 'Enter' && review()} />
          </Field>
          <Field label="المرجع / السبب" optional>
            <Input value={reason} onChange={(e) => setReason(e.target.value)} placeholder="مثال: إيصال نقدي رقم 1024" />
          </Field>
        </div>
      ) : (
        <div className="space-y-3 text-sm">
          <div className="rounded-xl bg-cream p-4">
            <p>الكابتن: <b>{view.captain.fullName}</b></p>
            <p>مبلغ الشحن: <b className="text-secondary">{formatMoney(fils!)}</b></p>
            <p>الرصيد بعد الشحن: <b>{formatMoney(view.balance + fils!)}</b></p>
            {view.balance + fils! >= threshold && view.balance < threshold && <p className="mt-2 text-secondary">سيصبح رصيد الكابتن كافياً للأهلية التجريبية.</p>}
          </div>
          <p className="text-xs text-ink-muted">بالتأكيد أنت تُقرّ باستلام المبلغ من الكابتن خارج النظام. سيُسجَّل قيد شحن باسم المدير الحالي. هذه عملية محاكاة وليست تحويلاً إلكترونياً.</p>
        </div>
      )}
    </Dialog>
  );
}
