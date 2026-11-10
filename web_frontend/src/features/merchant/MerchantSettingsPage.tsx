import { useMemo } from 'react';
import { Navigate } from 'react-router-dom';
import { Marker } from 'react-leaflet';
import { Headphones, Languages, LogOut, MapPin, Store, Tags, UserCog } from 'lucide-react';
import { useSession } from '@/application/session';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions } from '@/application/queries';
import { formatMoney } from '@/domain/money';
import { Badge, Button, SettingsRow, SettingsSection } from '@/shared/components/ui';
import { BaseMap } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';
import { SupportContactList } from '@/features/support/SupportContacts';
import { MerchantCategoryBadge } from '@/features/merchants/MerchantCategoryBadge';
import { useSignOut } from '@/features/auth/hooks/useSignOut';
import { MerchantHeader } from './MerchantHeader';

/**
 * Merchant settings: the Merchant's own account, read-only. Profile, category,
 * pickup location and prices are managed by SHAHM Admin (FE-CR FR-SET-M-003).
 */
export function MerchantSettingsPage() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const signOut = useSignOut();
  const zones = useMemo(() => (merchantId ? merchantZoneOptions({ areas, prices, coverage }, merchantId) : []), [areas, prices, coverage, merchantId]);
  if (!merchant) return <Navigate to="/login" replace />;

  return (
    <div className="min-h-screen">
      <MerchantHeader merchant={merchant} page="settings" />
      <main className="mx-auto max-w-3xl space-y-6 px-4 py-6">
        <h1 className="text-2xl font-extrabold text-ink">الإعدادات</h1>

        <SettingsSection title="الملف التجاري" description="يديره فريق شهم. للتعديل تواصل مع الدعم." icon={<Store className="h-5 w-5" />}>
          <SettingsRow label="اسم النشاط التجاري" readOnly>{merchant.businessName}</SettingsRow>
          <SettingsRow label="فئة النشاط" readOnly>
            <MerchantCategoryBadge category={merchant.category} />
          </SettingsRow>
          <SettingsRow label="رقم الهاتف" readOnly>
            <span dir="ltr">{merchant.phone}</span>
          </SettingsRow>
          <SettingsRow label="حالة الحساب" readOnly>
            <Badge tone={merchant.status === 'active' ? 'success' : 'danger'} dot>
              {merchant.status === 'active' ? 'مفعّل' : 'غير مفعّل'}
            </Badge>
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="موقع الاستلام" description="يحدده فريق شهم، ويُستخدم تلقائياً في كل طلب." icon={<MapPin className="h-5 w-5" />}>
          <SettingsRow label="العنوان" readOnly>{merchant.address}</SettingsRow>
          <div className="p-4">
            <BaseMap className="h-48" center={merchant.pickup} zoom={15} label="موقع الاستلام">
              <Marker position={[merchant.pickup.lat, merchant.pickup.lng]} icon={merchantIcon()} />
            </BaseMap>
          </div>
        </SettingsSection>

        <SettingsSection title="مناطق التوصيل والأسعار" description="رسوم ثابتة لكل منطقة يحددها فريق شهم." icon={<Tags className="h-5 w-5" />}>
          {zones.length === 0 ? (
            <p className="px-5 py-4 text-sm text-ink-muted">لا توجد مناطق مفعّلة لحسابك بعد.</p>
          ) : (
            zones.map(({ area, label, price }) => (
              <SettingsRow key={area.id} label={label} readOnly>
                <span className="font-bold">{formatMoney(price)}</span>
              </SettingsRow>
            ))
          )}
        </SettingsSection>

        <SettingsSection title="الحساب" icon={<UserCog className="h-5 w-5" />}>
          <SettingsRow label="اسم المستخدم" readOnly>
            <span dir="ltr">{merchant.username}</span>
          </SettingsRow>
          <SettingsRow label="كلمة المرور" description="تغيير كلمة المرور غير متاح في النموذج الأولي." readOnly />
          <SettingsRow label="تسجيل الخروج" description="من هذه النافذة فقط.">
            <Button variant="outline" icon={<LogOut className="h-4 w-4" />} onClick={signOut}>
              خروج
            </Button>
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="اللغة والعرض" icon={<Languages className="h-5 w-5" />}>
          <SettingsRow label="لغة الواجهة" readOnly>
            العربية (من اليمين إلى اليسار)
          </SettingsRow>
        </SettingsSection>

        <SettingsSection title="دعم شهم" icon={<Headphones className="h-5 w-5" />}>
          <div className="p-5">
            <SupportContactList />
          </div>
        </SettingsSection>
      </main>
    </div>
  );
}
