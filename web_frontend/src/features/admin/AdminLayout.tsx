import { useEffect, useRef, useState } from 'react';
import { NavLink, Outlet, useLocation, Link } from 'react-router-dom';
import { useSignOut } from '@/features/auth/hooks/useSignOut';
import {
  Bell,
  Headphones,
  LayoutDashboard,
  LogOut,
  Map,
  Menu,
  Radio,
  ReceiptText,
  Send,
  Settings,
  Shapes,
  Store,
  Tags,
  Users,
  Wallet,
  X,
} from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import { Logo } from '@/shared/components/Logo';
import { cn } from '@/shared/lib/cn';
import { formatRelative } from '@/shared/lib/format';

const NAV = [
  { to: '/admin', label: 'لوحة التحكم', icon: LayoutDashboard, end: true },
  { to: '/admin/dispatch', label: 'مركز التوزيع', icon: Send },
  { to: '/admin/map', label: 'الخريطة الحية', icon: Map },
  { to: '/admin/orders', label: 'الطلبات', icon: ReceiptText },
  { to: '/admin/merchants', label: 'التجار', icon: Store },
  { to: '/admin/captains', label: 'الكباتن', icon: Users },
  { to: '/admin/areas', label: 'مناطق التوصيل', icon: Shapes },
  { to: '/admin/pricing', label: 'أسعار التجار', icon: Tags },
  { to: '/admin/wallets', label: 'محافظ الكباتن', icon: Wallet },
  { to: '/admin/support', label: 'بيانات الدعم', icon: Headphones },
  { to: '/admin/settings', label: 'الإعدادات', icon: Settings },
];

export function AdminLayout() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { pathname } = useLocation();
  const signOut = useSignOut();
  useEffect(() => setMobileOpen(false), [pathname]);

  const queueCount = useAppStore((s) => s.orders.filter((o) => o.status === 'pending_dispatch' || o.status === 'dispatch_expired').length);

  const nav = (
    <nav className="space-y-1 p-3" aria-label="التنقل الرئيسي للإدارة">
      {NAV.map(({ to, label, icon: Icon, end }) => (
        <NavLink
          key={to}
          to={to}
          end={end}
          className={({ isActive }) =>
            cn(
              'flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-bold transition-colors',
              isActive ? 'bg-primary text-white shadow-sm' : 'text-ink-soft hover:bg-cream-dark',
            )
          }
        >
          <Icon className="h-[18px] w-[18px]" aria-hidden />
          <span className="flex-1">{label}</span>
          {to === '/admin/dispatch' && queueCount > 0 && (
            <span className="rounded-full bg-amber-400 px-2 text-xs font-extrabold text-ink">{queueCount}</span>
          )}
        </NavLink>
      ))}
    </nav>
  );

  return (
    <div className="flex min-h-screen">
      <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-e border-cream-deep bg-white lg:flex">
        <div className="flex items-center justify-center border-b border-cream-dark px-4 py-3">
          <Logo className="h-14" />
        </div>
        <div className="flex-1 overflow-y-auto">{nav}</div>
        <p className="border-t border-cream-dark p-3 text-[11px] text-ink-muted">مدير النظام (تجريبي)</p>
      </aside>

      {mobileOpen && (
        <div className="fixed inset-0 z-[850] lg:hidden">
          <div className="absolute inset-0 bg-ink/40" onClick={() => setMobileOpen(false)} />
          <aside className="absolute inset-y-0 start-0 w-72 overflow-y-auto bg-white shadow-pop">
            <div className="flex items-center justify-between border-b border-cream-dark px-4 py-3">
              <Logo className="h-12" />
              <button onClick={() => setMobileOpen(false)} aria-label="إغلاق القائمة" className="rounded-lg p-1.5 hover:bg-cream">
                <X className="h-5 w-5" />
              </button>
            </div>
            {nav}
          </aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-[700] flex items-center gap-3 border-b border-cream-deep bg-cream/95 px-4 py-2.5 backdrop-blur lg:px-6">
          <button className="rounded-lg p-2 hover:bg-cream-dark lg:hidden" onClick={() => setMobileOpen(true)} aria-label="فتح القائمة">
            <Menu className="h-5 w-5" />
          </button>
          <div className="flex-1" />
          <BroadcastPill />
          <AlertsMenu />
          <button
            onClick={signOut}
            className="inline-flex items-center gap-1.5 rounded-xl px-3 py-2 text-sm font-bold text-ink-soft hover:bg-cream-dark"
          >
            <LogOut className="h-4 w-4" /> خروج
          </button>
        </header>
        <main className="mx-auto w-full max-w-[1400px] flex-1 px-4 py-6 lg:px-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

function BroadcastPill() {
  const enabled = useAppStore((s) => s.settings.publicBroadcast);
  return (
    <Link
      to="/admin"
      className={cn(
        'inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-bold ring-1',
        enabled ? 'bg-secondary-50 text-secondary ring-secondary-200' : 'bg-amber-50 text-amber-800 ring-amber-300',
      )}
      title="التحكم من لوحة التحكم"
    >
      <Radio className={cn('h-4 w-4', enabled && 'animate-pulse')} aria-hidden />
      البث العام: {enabled ? 'مفعّل' : 'متوقف'}
    </Link>
  );
}

function AlertsMenu() {
  const alerts = useAppStore((s) => s.alerts);
  const markAlertsRead = useAppStore((s) => s.markAlertsRead);
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const now = useNow(15000);
  const unread = alerts.filter((a) => !a.read).length;

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => ref.current && !ref.current.contains(e.target as Node) && setOpen(false);
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  return (
    <div className="relative" ref={ref}>
      <button
        onClick={() => {
          setOpen((o) => !o);
          if (!open && unread) setTimeout(markAlertsRead, 1500);
        }}
        className="relative rounded-xl p-2 text-ink-soft hover:bg-cream-dark"
        aria-label={`التنبيهات التشغيلية${unread ? ` (${unread} غير مقروءة)` : ''}`}
        aria-expanded={open}
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute -end-0.5 -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-white">{unread}</span>
        )}
      </button>
      {open && (
        <div className="absolute end-0 top-12 z-50 w-80 overflow-hidden rounded-2xl border border-cream-deep bg-white shadow-pop">
          <p className="border-b border-cream-dark px-4 py-3 text-sm font-bold">التنبيهات التشغيلية</p>
          <ul className="max-h-96 divide-y divide-cream-dark overflow-y-auto">
            {alerts.length === 0 && <li className="p-4 text-center text-sm text-ink-muted">لا توجد تنبيهات</li>}
            {alerts.slice(0, 25).map((a) => (
              <li key={a.id} className={cn('px-4 py-3 text-sm', !a.read && 'bg-primary-50/50')}>
                <p className="text-ink">{a.message}</p>
                <p className="mt-0.5 text-xs text-ink-muted">{formatRelative(a.at, now)}</p>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
