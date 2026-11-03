import { Link, Navigate, useParams } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { PageHeader } from '@/shared/components/ui';
import { MerchantZonePricing } from './MerchantZonePricing';

/** Delivery Zones & Pricing within a Merchant's management details. */
export function MerchantZonesPage() {
  const { merchantId } = useParams();
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  if (!merchant) return <Navigate to="/admin/merchants" replace />;
  return (
    <>
      <Link to="/admin/merchants" className="mb-3 inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
        <ArrowRight className="h-4 w-4" /> التجار
      </Link>
      <PageHeader
        title={`مناطق التوصيل والأسعار — ${merchant.businessName}`}
        description="اختر المناطق التي يخدمها هذا التاجر من القائمة المركزية وحدد رسوم توصيل ثابتة لكل منطقة. التاجر يختار منطقة العميل فقط وتظهر له الرسوم تلقائياً."
      />
      <MerchantZonePricing merchant={merchant} />
    </>
  );
}
