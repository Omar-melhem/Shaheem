import { Link, Navigate, useParams } from 'react-router-dom';
import { ArrowRight, MapPin } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { PageHeader } from '@/shared/components/ui';
import { MerchantAreaPriceTable } from './MerchantAreaPriceTable';

/**
 * One Merchant's delivery-area prices (FU-1.2 §8.2), opened from the pricing cards
 * or from Merchant management. Only this Merchant's records are shown and edited.
 */
export function MerchantPricingDetails({ backTo }: { backTo: { path: string; label: string } }) {
  const { merchantId } = useParams();
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  if (!merchant) return <Navigate to={backTo.path} replace />;
  return (
    <>
      <Link to={backTo.path} className="mb-3 inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
        <ArrowRight className="h-4 w-4" /> {backTo.label}
      </Link>
      <PageHeader
        title={`مناطق التوصيل والأسعار — ${merchant.businessName}`}
        description={
          <span className="flex items-start gap-1">
            <MapPin className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> موقع الاستلام: {merchant.address}
          </span>
        }
      />
      <MerchantAreaPriceTable merchant={merchant} />
    </>
  );
}
