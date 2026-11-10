import { Link } from 'react-router-dom';
import { ChevronLeft, MapPin, Store } from 'lucide-react';
import type { Merchant } from '@/domain/types';
import { Badge } from '@/shared/components/ui';
import { MerchantCategoryBadge } from '@/features/merchants/MerchantCategoryBadge';

/** One Merchant on the pricing landing grid: name, pickup location, category and coverage count. */
export function MerchantPricingCard({ merchant, activeZones }: { merchant: Merchant; activeZones: number }) {
  return (
    <Link
      to={`/admin/pricing/${merchant.id}`}
      className="group flex h-full flex-col gap-3 rounded-2xl bg-white p-4 shadow-card ring-1 ring-cream-deep transition-shadow hover:shadow-pop focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300"
      aria-label={`أسعار ${merchant.businessName}`}
    >
      <div className="flex items-start gap-3">
        <span className="rounded-xl bg-primary-50 p-2.5 text-primary">
          <Store className="h-5 w-5" aria-hidden />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate font-bold text-ink">{merchant.businessName}</p>
          <p className="mt-0.5 flex items-start gap-1 text-xs text-ink-muted">
            <MapPin className="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden />
            <span className="line-clamp-2">{merchant.address}</span>
          </p>
        </div>
        <ChevronLeft className="h-5 w-5 shrink-0 text-ink-muted transition-transform group-hover:-translate-x-0.5" aria-hidden />
      </div>
      <div className="mt-auto flex flex-wrap items-center gap-2">
        <MerchantCategoryBadge category={merchant.category} />
        <Badge tone={activeZones > 0 ? 'success' : 'warning'}>{activeZones > 0 ? `${activeZones} منطقة مفعّلة` : 'لا توجد أسعار'}</Badge>
        {merchant.status !== 'active' && <Badge tone="neutral">غير مفعّل</Badge>}
      </div>
    </Link>
  );
}
