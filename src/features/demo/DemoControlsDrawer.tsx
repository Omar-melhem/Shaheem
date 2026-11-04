import { useState } from 'react';
import { RotateCcw, SatelliteDish, WifiOff, MapPin } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Button, ConfirmDialog, Drawer, Field, Input, OpenDecision, Select, SimTag, Toggle } from '@/shared/components/ui';
import { reportResult, toast } from '@/shared/components/toast';
import { formatMoney, parseJodInput, filsToJod } from '@/domain/money';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';

/** Presenter-only controls (SRS §19.8). Never shown as production functionality. */
export function DemoControlsDrawer({ open, onClose }: { open: boolean; onClose: () => void }) {
  const s = useAppStore();
  const [captainId, setCaptainId] = useState(s.captains[0]?.id ?? '');
  const [confirmReset, setConfirmReset] = useState(false);
  const [thresholdInput, setThresholdInput] = useState(String(filsToJod(s.demo.walletThreshold)));
  const captain = s.captains.find((c) => c.id === captainId);

  const saveThreshold = () => {
    const fils = parseJodInput(thresholdInput);
    if (fils === null) return toast.error('أدخل مبلغاً صالحاً');
    s.updateDemoSettings({ walletThreshold: fils });
    toast.success(`الحد التجريبي للمحفظة: ${formatMoney(fils)}`);
  };

  return (
    <Drawer open={open} onClose={onClose} title="أدوات العرض التجريبي" subtitle={<SimTag>للمقدّم فقط — ليست ميزة إنتاجية</SimTag>}>
      <section className="space-y-3 rounded-2xl bg-white p-4 shadow-card">
        <h3 className="font-bold">البيانات</h3>
        <Button variant="danger" icon={<RotateCcw className="h-4 w-4" />} onClick={() => setConfirmReset(true)}>
          إعادة ضبط بيانات العرض
        </Button>
        <p className="text-xs text-ink-muted">تُحفظ البيانات في هذا المتصفح فقط (localStorage). يمكن فتح الإدارة والتاجر والكابتن في تبويبات منفصلة في نفس المتصفح وستتزامن تلقائياً، لكنها لا تتزامن بين أجهزة مختلفة.</p>
      </section>

      <section className="space-y-4 rounded-2xl bg-white p-4 shadow-card">
        <h3 className="font-bold">التوزيع</h3>
        <Toggle
          checked={s.settings.publicBroadcast}
          onChange={(v) => reportResult(s.setPublicBroadcast(v), v ? 'تم تفعيل البث العام' : 'تم إيقاف البث العام')}
          label="البث العام للطلبات"
          description="نفس مفتاح لوحة الإدارة"
        />
        <Field label="سياسة إرسال العروض (افتراض تجريبي)">
          <Select value={s.demo.offerPolicy} onChange={(e) => s.updateDemoSettings({ offerPolicy: e.target.value as 'sequential' | 'group' })}>
            <option value="group">مجموعة من الأقرب في آن واحد — أول قبول يفوز</option>
            <option value="sequential">تسلسلي — الأقرب أولاً ثم التالي</option>
          </Select>
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="حجم المجموعة">
            <Input type="number" min={1} max={8} value={s.demo.groupSize} disabled={s.demo.offerPolicy === 'sequential'} onChange={(e) => s.updateDemoSettings({ groupSize: Math.max(1, Math.min(8, Number(e.target.value) || 1)) })} />
          </Field>
          <Field label="مهلة العرض الخاص (ثانية)" hint={`العرض العام ثابت: ${MAX_DISPATCH_ROUNDS} جولات × ${DISPATCH_ROUND_SEC} ث`}>
            <Input type="number" min={15} max={600} value={s.demo.offerTimeoutSec} onChange={(e) => s.updateDemoSettings({ offerTimeoutSec: Math.max(15, Math.min(600, Number(e.target.value) || DISPATCH_ROUND_SEC)) })} />
          </Field>
        </div>
        <OpenDecision id="O-005 / O-006">اختيار الكباتن في كل جولة ومهلة العرض الخاص قرارات مفتوحة؛ القيم هنا لأغراض العرض فقط.</OpenDecision>
      </section>

      <section className="space-y-3 rounded-2xl bg-white p-4 shadow-card">
        <h3 className="font-bold">المحفظة</h3>
        <Field label="الحد التجريبي لأهلية المحفظة (د.أ)">
          <div className="flex gap-2">
            <Input value={thresholdInput} onChange={(e) => setThresholdInput(e.target.value)} inputMode="decimal" />
            <Button variant="outline" onClick={saveThreshold}>
              حفظ
            </Button>
          </div>
        </Field>
        <OpenDecision id="O-020">المبلغ الذي يجب أن يغطيه رصيد الكابتن غير محدد. لا يتم أي خصم من المحفظة في هذا النموذج.</OpenDecision>
      </section>

      <section className="space-y-3 rounded-2xl bg-white p-4 shadow-card">
        <h3 className="font-bold">الكابتن والموقع</h3>
        <Field label="اختر كابتن">
          <Select value={captainId} onChange={(e) => setCaptainId(e.target.value)}>
            {s.captains.map((c) => (
              <option key={c.id} value={c.id}>
                {c.fullName}
              </option>
            ))}
          </Select>
        </Field>
        {captain && (
          <>
            <Toggle
              checked={captain.availability === 'available'}
              onChange={(v) => reportResult(s.setCaptainAvailability(captain.id, v))}
              label="متاح لاستقبال الطلبات"
            />
            <div className="flex flex-wrap gap-2">
              {captain.gpsSignal === 'ok' ? (
                <Button variant="outline" icon={<WifiOff className="h-4 w-4" />} onClick={() => { s.setGpsSignal(captain.id, 'lost'); toast.info('تمت محاكاة فقدان إشارة GPS'); }}>
                  محاكاة فقدان GPS
                </Button>
              ) : (
                <Button variant="secondary" icon={<SatelliteDish className="h-4 w-4" />} onClick={() => { s.setGpsSignal(captain.id, 'ok'); toast.success('تمت استعادة إشارة GPS'); }}>
                  استعادة GPS
                </Button>
              )}
            </div>
            <Field label="نقل الموقع التجريبي (للكابتن غير المشغول)" hint="يغيّر ترتيب القرب في التوزيع">
              <Select
                value=""
                onChange={(e) => {
                  const m = s.merchants.find((x) => x.id === e.target.value);
                  if (!m) return;
                  const pos = { lat: m.pickup.lat + 0.0025, lng: m.pickup.lng - 0.002 };
                  reportResult(s.setCaptainDemoLocation(captain.id, pos), `نُقل ${captain.fullName} قرب ${m.businessName}`);
                }}
              >
                <option value="">قرب تاجر…</option>
                {s.merchants.map((m) => (
                  <option key={m.id} value={m.id}>
                    {m.businessName}
                  </option>
                ))}
              </Select>
            </Field>
          </>
        )}
        <Field label="ثواني حتى اعتبار الموقع متأخراً">
          <Input type="number" min={5} max={300} value={s.demo.staleAfterSec} onChange={(e) => s.updateDemoSettings({ staleAfterSec: Math.max(5, Math.min(300, Number(e.target.value) || 20)) })} />
        </Field>
        <OpenDecision id="O-001">مصدر موقع الكابتن قبل الرحلة غير محدد؛ المواقع خارج الرحلة هنا تجريبية وتُعرض كذلك.</OpenDecision>
      </section>

      <section className="space-y-2 rounded-2xl bg-white p-4 shadow-card">
        <h3 className="font-bold">سيناريوهات العرض (SRS §19.7)</h3>
        <ol className="list-decimal space-y-2 ps-5 text-sm text-ink-soft">
          <li>
            <b>توصيل قياسي:</b> ادخل كتاجر «مطعم السنابل»، اختر منطقة «الجبيهة» واكتب وصف العنوان، ثم في تبويب آخر ادخل كالكابتن «أحمد العمري» لقبول العرض.
          </li>
          <li>
            <b>محفظة غير كافية:</b> ادخل كالكابتن «يزن الحسن» (رصيد 0)، ثم كمدير اشحن محفظته من صفحة المحافظ.
          </li>
          <li>
            <b>إسناد خاص:</b> أوقف البث العام، أنشئ طلباً، ثم أسنده من مركز التوزيع.
          </li>
          <li>
            <b>انقطاع GPS:</b> أثناء توصيل نشط، اختر الكابتن أعلاه واضغط «محاكاة فقدان GPS» وراقب الخريطة الحية في لوحة الإدارة.
          </li>
          <li>
            <b>تسعير حسب المنطقة:</b> غيّر رسوم «خلدا» لمقهى الهيل من صفحة المناطق والأسعار، ثم أنشئ طلباً جديداً — الطلبات السابقة تحتفظ برسومها.
          </li>
        </ol>
        <p className="flex items-center gap-1 pt-1 text-xs text-ink-muted">
          <MapPin className="h-3.5 w-3.5" /> مواقع الكباتن ومراكز المناطق محاكاة لأغراض العرض.
        </p>
      </section>

      <ConfirmDialog
        open={confirmReset}
        onClose={() => setConfirmReset(false)}
        onConfirm={() => {
          s.resetDemo();
          setThresholdInput('2');
          toast.success('تمت إعادة ضبط بيانات العرض');
        }}
        title="إعادة ضبط بيانات العرض؟"
        description="ستُحذف جميع التغييرات وتعود البيانات التجريبية الأصلية."
        confirmLabel="إعادة الضبط"
        variant="danger"
      />
    </Drawer>
  );
}
