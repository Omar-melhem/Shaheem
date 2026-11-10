import { useMemo, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useConfirmedSignOut } from '@/features/auth/hooks/useConfirmedSignOut';
import { useSession } from '@/application/session';
import { Bell, History, LogOut, Navigation, Package, User, Wallet } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow } from '@/application/hooks';
import { SimTag, Toggle } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { cn } from '@/shared/lib/cn';
import { OffersTab } from './OffersTab';
import { ActiveDeliveryTab } from './ActiveDeliveryTab';
import { HistoryTab, WalletTab, ProfileTab } from './OtherTabs';
import { GpsChip } from './GpsChip';

type Tab = 'offers' | 'active' | 'history' | 'wallet' | 'profile';

/**
 * Simulated preview of the Captain Android/iOS app (SRS §6). The production app
 * is a dedicated mobile application; framework is open (O-037).
 */
export function CaptainApp() {
  const captainId = useSession((s) => s.session?.id);
  const { requestSignOut: signOut, signOutDialog } = useConfirmedSignOut();
  const now = useNow(1000);
  const views = useCaptainViews(now);
  const view = views.find((v) => v.captain.id === captainId);
  const offers = useAppStore((s) => s.offers);
  const orders = useAppStore((s) => s.orders);
  const setCaptainAvailability = useAppStore((s) => s.setCaptainAvailability);
  const [tab, setTab] = useState<Tab>('offers');

  const activeOrder = useMemo(() => orders.find((o) => o.id === view?.activeOrderId), [orders, view?.activeOrderId]);
  const pendingOffers = offers.filter((o) => o.captainId === captainId && o.status === 'pending' && o.expiresAt > now);

  if (!view) return <Navigate to="/login" replace />;
  const c = view.captain;
  const effectiveTab: Tab = tab === 'offers' && activeOrder ? 'active' : tab;

  const tabs: Array<{ id: Tab; label: string; icon: typeof Package; badge?: number }> = [
    { id: 'offers', label: 'الطلبات', icon: Bell, badge: pendingOffers.length || undefined },
    { id: 'active', label: 'التوصيل', icon: Navigation, badge: activeOrder ? 1 : undefined },
    { id: 'history', label: 'السجل', icon: History },
    { id: 'wallet', label: 'المحفظة', icon: Wallet },
    { id: 'profile', label: 'حسابي', icon: User },
  ];

  return (
    <div className="flex min-h-screen flex-col items-center gap-4 bg-gradient-to-b from-cream to-cream-dark px-4 py-6 lg:flex-row lg:items-start lg:justify-center lg:gap-10">
      <aside className="max-w-xs space-y-2 text-center lg:mt-24 lg:text-start">
        <SimTag>معاينة محاكاة لتطبيق الكابتن</SimTag>
        <p className="text-sm text-ink-muted">التطبيق الفعلي تطبيق جوال مخصص لنظامي Android و iOS. هذه المعاينة تعرض التدفق نفسه داخل المتصفح لأغراض العرض.</p>
      </aside>

      <div className="relative flex h-[min(820px,calc(100vh-90px))] w-full max-w-[400px] flex-col overflow-hidden rounded-[2.5rem] border-[10px] border-ink bg-cream shadow-pop">
        {/* status bar */}
        <div className="flex items-center justify-between bg-ink px-6 pb-1 pt-1.5 text-[11px] font-bold text-cream" dir="ltr">
          <span>{new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit' }).format(now)}</span>
          <span className="h-4 w-20 rounded-full bg-black" aria-hidden />
          <span>SHAHM</span>
        </div>

        {/* app header */}
        <header className="space-y-3 bg-primary px-4 pb-4 pt-3 text-white">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white/15 text-lg font-extrabold">{c.fullName.charAt(0)}</div>
            <div className="min-w-0 flex-1">
              <h1 className="truncate font-bold">{c.fullName}</h1>
              <div className="mt-1 flex flex-wrap items-center gap-2">
                <span className="text-xs text-white/80">كابتن شهم</span>
                <GpsChip captain={c} freshness={view.freshness} hasActive={!!activeOrder} />
              </div>
            </div>
            <button onClick={signOut} className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/15 hover:bg-white/25 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white" aria-label="تسجيل الخروج" title="تسجيل الخروج">
              <LogOut className="h-4 w-4" />
            </button>
            {signOutDialog}
          </div>
          <div className="rounded-xl bg-white/10 px-3 py-2">
            <Toggle
              checked={c.availability === 'available'}
              disabled={c.status !== 'active'}
              onChange={(v) => reportResult(setCaptainAvailability(c.id, v), v ? 'أنت متاح الآن لاستقبال الطلبات' : 'أنت غير متاح الآن')}
              label={<span className="text-white">{c.availability === 'available' ? 'متاح لاستقبال الطلبات' : 'غير متاح'}</span>}
              description={<span className="text-white/90">{c.status !== 'active' ? 'الحساب موقوف من الإدارة' : activeOrder ? 'لديك توصيل نشط' : 'بدّل لاستقبال العروض'}</span>}
            />
          </div>
        </header>

        <main className="flex-1 overflow-y-auto">
          {effectiveTab === 'offers' && <OffersTab view={view} now={now} />}
          {effectiveTab === 'active' && <ActiveDeliveryTab captain={c} order={activeOrder} freshness={view.freshness} now={now} />}
          {effectiveTab === 'history' && <HistoryTab captainId={c.id} />}
          {effectiveTab === 'wallet' && <WalletTab view={view} />}
          {effectiveTab === 'profile' && <ProfileTab captain={c} />}
        </main>

        <nav className="grid grid-cols-5 border-t border-cream-deep bg-white pb-2" aria-label="تنقل تطبيق الكابتن">
          {tabs.map((t) => (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              aria-current={effectiveTab === t.id ? 'page' : undefined}
              className={cn('relative flex flex-col items-center gap-0.5 py-2 text-[11px] font-bold', effectiveTab === t.id ? 'text-primary' : 'text-ink-muted')}
            >
              <t.icon className="h-5 w-5" aria-hidden />
              {t.label}
              {t.badge && <span className="absolute end-3 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[11px] text-white">{t.badge}</span>}
            </button>
          ))}
        </nav>
      </div>
    </div>
  );
}
