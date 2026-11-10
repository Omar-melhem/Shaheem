import { useState } from 'react';
import { NO_EXACT_LOCATION, isAreaOnly } from '@/domain/destination';
import { BellOff, Check, MapPin, Store, Timer, X, AlertCircle, Lock } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { CaptainView } from '@/application/hooks';
import { describeReasons } from '@/domain/eligibility';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { formatDistance } from '@/domain/geo';
import { Badge, Button, EmptyState } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { formatCountdown, formatTime } from '@/shared/lib/format';

/** Eligible offers visible to this Captain only (SRS §6.5). */
export function OffersTab({ view, now }: { view: CaptainView; now: number }) {
  const offers = useAppStore((s) => s.offers);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const acceptOffer = useAppStore((s) => s.acceptOffer);
  const rejectOffer = useAppStore((s) => s.rejectOffer);
  const [busy, setBusy] = useState<string | null>(null);

  const mine = offers
    .filter((o) => o.captainId === view.captain.id && o.status === 'pending' && o.expiresAt > now)
    .sort((a, b) => a.expiresAt - b.expiresAt);

  const notEligible = view.eligibility.reasons.filter((r) => r !== 'busy');

  return (
    <div className="space-y-3 p-4">
      {notEligible.length > 0 && (
        <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900" role="status">
          <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
          <div>
            <p className="font-bold">لن تصلك عروض جديدة حالياً</p>
            <p className="text-xs">{describeReasons(notEligible, threshold)}</p>
            {notEligible.includes('insufficient_wallet') && <p className="mt-1 text-xs">يتم شحن المحفظة من إدارة شهم.</p>}
          </div>
        </div>
      )}

      {mine.length === 0 ? (
        <EmptyState
          icon={<BellOff className="h-6 w-6" />}
          title="لا توجد عروض حالياً"
          description={view.eligibility.eligible ? 'ستظهر هنا العروض القريبة منك فور توفرها.' : 'تأكد من أنك متاح ومن كفاية رصيد المحفظة.'}
        />
      ) : (
        mine.map((offer) => {
          const order = orders.find((o) => o.id === offer.orderId);
          const merchant = merchants.find((m) => m.id === order?.merchantId);
          if (!order || !merchant) return null;
          const remaining = offer.expiresAt - now;
          const total = offer.expiresAt - offer.offeredAt;
          return (
            <article key={offer.id} className="overflow-hidden rounded-2xl bg-white shadow-card ring-1 ring-cream-deep">
              <div className="h-1 bg-cream-dark">
                <div className="h-full bg-primary transition-all" style={{ width: `${Math.max(0, (remaining / total) * 100)}%` }} />
              </div>
              <div className="space-y-3 p-4">
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-2">
                    {offer.mode === 'private' ? (
                      <Badge tone="info"><Lock className="h-3 w-3" /> عرض خاص لك</Badge>
                    ) : (
                      <Badge tone="warning">عرض جديد</Badge>
                    )}
                    <span className="text-xs text-ink-muted">{formatTime(offer.offeredAt)}</span>
                  </div>
                  <span className="inline-flex items-center gap-1 font-mono text-sm font-bold text-primary" dir="ltr">
                    <Timer className="h-4 w-4" /> {formatCountdown(remaining)}
                  </span>
                </div>

                <div className="rounded-xl bg-secondary-50 py-3 text-center">
                  <p className="text-xs text-ink-muted">سعر التوصيل</p>
                  <p className="text-3xl font-extrabold text-secondary">{formatMoney(order.deliveryPrice)}</p>
                </div>

                <ol className="space-y-2 text-sm">
                  <li className="flex items-start gap-2">
                    <Store className="mt-0.5 h-4 w-4 shrink-0 text-ink" />
                    <div>
                      <p className="font-bold">{merchant.businessName}</p>
                      <p className="text-xs text-ink-muted">{merchant.address}</p>
                      {offer.distanceMeters !== undefined && <p className="text-xs text-ink-muted">≈ {formatDistance(offer.distanceMeters)} منك (خط مستقيم)</p>}
                      {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && (
                        <p className="text-xs font-bold text-primary">طلب مؤجل — الاستلام {formatAmmanDateTime(order.scheduledPickupAt)}</p>
                      )}
                    </div>
                  </li>
                  <li className="flex items-start gap-2">
                    <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
                    <div>
                      <p className="font-bold">{order.destination.label}</p>
                      <p className="text-xs text-ink-muted">{order.destination.address} · منطقة {order.areaName}</p>
                      {isAreaOnly(order.destination) && <p className="text-xs font-medium text-amber-800">{NO_EXACT_LOCATION}</p>}
                      {order.destination.note && <p className="text-xs text-ink-soft">{order.destination.note}</p>}
                    </div>
                  </li>
                </ol>
                {order.customerPhone && (
                  <p className="text-xs text-ink-muted">
                    هاتف العميل: <span dir="ltr">{order.customerPhone}</span>
                  </p>
                )}

                <div className="grid grid-cols-[1fr_2fr] gap-2 pt-1">
                  <Button
                    variant="outline"
                    size="lg"
                    icon={<X className="h-4 w-4" />}
                    disabled={busy === offer.id}
                    onClick={() => {
                      setBusy(offer.id);
                      reportResult(rejectOffer(offer.id, view.captain.id), 'تم رفض العرض');
                      setBusy(null);
                    }}
                  >
                    رفض
                  </Button>
                  <Button
                    variant="secondary"
                    size="lg"
                    icon={<Check className="h-5 w-5" />}
                    loading={busy === offer.id}
                    onClick={() => {
                      setBusy(offer.id);
                      reportResult(acceptOffer(offer.id, view.captain.id), 'تم قبول الطلب — توجّه إلى التاجر');
                      setBusy(null);
                    }}
                  >
                    قبول الطلب
                  </Button>
                </div>
              </div>
            </article>
          );
        })
      )}
    </div>
  );
}
