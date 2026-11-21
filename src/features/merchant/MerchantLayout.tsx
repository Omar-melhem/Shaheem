import { useState } from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { Headphones, History, Send, Settings, Tags } from 'lucide-react';
import type { Merchant } from '@/domain/types';
import { useSession } from '@/app/session';
import { useAppStore } from '@/app/state';
import { Logo } from '@/shared/components/Logo';
import { Dialog } from '@/shared/components/ui';
import { AppShell, type ShellNavItem } from '@/shared/components/layout/AppShell';
import { SupportContactList } from '@/features/support/SupportContacts';
import { DemoToolsButton } from '@/features/demo/DemoToolsButton';

function MerchantIdentity({ merchant, compact }: { merchant: Merchant; compact?: boolean }) {
  return (
    <div className="flex min-w-0 items-center gap-3">
      <Logo className={compact ? 'h-8 shrink-0' : 'h-11 shrink-0'} />
      <div className="min-w-0 border-s border-cream-deep ps-3">
        <p className="truncate font-extrabold text-ink" title={merchant.businessName}>{merchant.businessName}</p>
        <p className="truncate text-xs text-ink-muted">بوابة التاجر</p>
      </div>
    </div>
  );
}

/**
 * Merchant shell: the shared right-side sidebar (phone drawer) for the Merchant's existing
 * destinations. «دعم شهم» opens the official support list; sign-out lives in Settings.
 */
export function MerchantLayout() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const [supportOpen, setSupportOpen] = useState(false);
  if (!merchant) return <Navigate to="/login" replace />;

  const nav: ShellNavItem[] = [
    { to: '/merchant', label: 'طلب كابتن', icon: Send, end: true },
    { to: '/merchant/orders', label: 'الطلبات', icon: History },
    { to: '/merchant/areas', label: 'المناطق والأسعار', icon: Tags },
    { kind: 'action', label: 'دعم شهم', icon: Headphones, onSelect: () => setSupportOpen(true) },
    { to: '/merchant/settings', label: 'الإعدادات', icon: Settings },
  ];

  return (
    <AppShell brand={<MerchantIdentity merchant={merchant} />} mobileBrand={<MerchantIdentity merchant={merchant} compact />} nav={nav} navLabel="تنقل بوابة التاجر" headerActions={<DemoToolsButton />}>
      <Outlet />
      <Dialog open={supportOpen} onClose={() => setSupportOpen(false)} title="تواصل مع شهم" description="قنوات الدعم الرسمية">
        <SupportContactList />
      </Dialog>
    </AppShell>
  );
}
