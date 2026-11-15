import { Navigate } from 'react-router-dom';
import { Marker } from 'react-leaflet';
import { LogOut, Store, UserCog } from 'lucide-react';
import { useSession } from '@/app/session';
import { useAppStore } from '@/app/state';
import { Badge, PageHeader, SettingsRow, SettingsSection } from '@/shared/components/ui';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';
import { MerchantCategoryBadge } from '@/features/merchants/MerchantCategoryBadge';
import { SignOutSection } from '@/features/auth/SignOutSection';

/**
 * Merchant settings: the Merchant's own store and account, read-only — profile, category, pickup
 * location and prices are managed by SHAHM Admin (FE-CR FR-SET-M-003). Areas & prices and support
 * have their own sidebar destinations, so they are not repeated here. Sign-out is the last section.
 */
export function MerchantSettingsPage() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  if (!merchant) return <Navigate to="/login" replace />;

  return (
    <div className="mx-auto max-w-4xl">
      <PageHeader title="الإعدادات" description="بيانات متجرك وحسابك. يديرها فريق شهم؛ للتعديل تواصل مع الدعم." />
      <div className="space-y-6">
        <SettingsSection title="معلومات المتجر" icon={<Store className="h-5 w-5" />}>
          <SettingsRow label="اسم النشاط التجاري" readOnly>{merchant.businessName}</SettingsRow>
          <SettingsRow label="فئة النشاط" readOnly>
            <MerchantCategoryBadge category={merchant.category} />
          </SettingsRow>
          <SettingsRow label="رقم هاتف المتجر" readOnly>
            <span dir="ltr">{merchant.phone}</span>
          </SettingsRow>
          <SettingsRow label="حالة الحساب" readOnly>
            <Badge tone={merchant.status === 'active' ? 'success' : 'danger'} dot>
              {merchant.status === 'active' ? 'مفعّل' : 'غير مفعّل'}
            </Badge>
          </SettingsRow>
          <SettingsRow label="موقع الاستلام" description="يُستخدم تلقائياً في كل طلب." readOnly>
            {merchant.address}
          </SettingsRow>
          <div className="px-5 pb-5 pt-1">
            <BaseMap className="h-44" center={merchant.pickup} zoom={15} label="موقع الاستلام">
              <Marker position={[merchant.pickup.lat, merchant.pickup.lng]} icon={merchantIcon()} title="موقع الاستلام" />
            </BaseMap>
          </div>
        </SettingsSection>

        <SettingsSection title="الحساب والأمان" icon={<UserCog className="h-5 w-5" />}>
          <SettingsRow label="اسم المستخدم" readOnly>
            <span dir="ltr">{merchant.username}</span>
          </SettingsRow>
        </SettingsSection>

        <SignOutSection icon={<LogOut className="h-5 w-5" />} />
      </div>
    </div>
  );
}
