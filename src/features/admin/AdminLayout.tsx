import { useEffect, useRef, useState } from 'react';
import { Outlet } from 'react-router-dom';
import {
  Bell,
  LayoutDashboard,
  Map,
  Radio,
  RadioTower,
  ReceiptText,
  Send,
  Settings,
  Shapes,
  Store,
  Tags,
  Users,
  Wallet,
} from 'lucide-react';
import { useAppStore } from '@/app/state';
import { isInQueue } from '@/domain/orderStatus';
import { useNow } from '@/shared/hooks/application';
import { BroadcastConfirmDialog } from './BroadcastConfirmDialog';
import { DemoToolsButton } from '@/features/demo/DemoToolsButton';
import { Logo } from '@/shared/components/Logo';
import { AppShell, type ShellNavItem } from '@/shared/components/layout/AppShell';
import { cn } from '@/shared/lib/cn';
import { formatRelative } from '@/shared/lib/format';

const NAV: Array<Extract<ShellNavItem, { to: string }>> = [
  { to: '/admin', label: 'لوحة التحكم', icon: LayoutDashboard, end: true },
  { to: '/admin/dispatch', label: 'مركز التوزيع', icon: Send },
  { to: '/admin/map', label: 'الخريطة الحية', icon: Map },
  { to: '/admin/orders', label: 'الطلبات', icon: ReceiptText },
  { to: '/admin/merchants', label: 'التجار', icon: Store },
  { to: '/admin/captains', label: 'الكباتن', icon: Users },
  { to: '/admin/areas', label: 'مناطق التوصيل', icon: Shapes },
  { to: '/admin/pricing', label: 'أسعار التجار', icon: Tags },
  { to: '/admin/wallets', label: 'محافظ الكباتن', icon: Wallet },
  { to: '/admin/settings', label: 'الإعدادات', icon: Settings },
];

/**
 * Admin shell: the shared right-side sidebar / phone drawer, with the broadcast pill and
 * notifications in the top bar. Sign-out lives in Settings (with its confirmation), not here.
 */
export function AdminLayout() {
  // Orders in the Admin queue (the shared QUEUE_STATUSES rule): waiting, needs Admin, and scheduled ones awaiting coordination.
  const queueCount = useAppStore((s) => s.orders.filter((o) => isInQueue(o.status)).length);
  const nav = NAV.map((item) =>
    item.to === '/admin/dispatch' && queueCount > 0
      ? { ...item, badge: <span className="rounded-full bg-amber-400 px-2 text-xs font-extrabold text-ink" aria-label={`${queueCount} بانتظار الإدارة`}>{queueCount}</span> }
      : item,
  );

  return (
    <AppShell
      brand={<div className="flex justify-center"><Logo className="h-14" /></div>}
      mobileBrand={<Logo className="h-9" />}
      nav={nav}
      navLabel="التنقل الرئيسي للإدارة"
      headerActions={<><DemoToolsButton /><BroadcastPill /><AlertsMenu /></>}
      sidebarFooter="مدير النظام (تجريبي)"
    >
      <Outlet />
    </AppShell>
  );
}

/**
 * The single place to switch public broadcasting from the admin shell. It only opens the shared
 * BroadcastConfirmDialog, which calls the store's `setPublicBroadcast` use case — the one setting
 * (`settings.publicBroadcast`) that dispatch, orders and settings all read.
 */
function BroadcastPill() {
  const enabled = useAppStore((s) => s.settings.publicBroadcast);
  const [pending, setPending] = useState<boolean | null>(null);
  const action = enabled ? 'إيقاف البث العام للطلبات' : 'تفعيل البث العام للطلبات';
  return (
    <span className="relative inline-flex">
      <button
        type="button"
        onClick={() => setPending(!enabled)}
        disabled={pending !== null}
        aria-label={`${action} — الحالة الآن: ${enabled ? 'مفعّل' : 'متوقف'}`}
        className={cn(
          'peer inline-flex h-9 items-center gap-2 rounded-full px-3 text-xs font-bold ring-1 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300 disabled:opacity-60',
          enabled ? 'bg-secondary-50 text-secondary ring-secondary-200 hover:bg-secondary-100' : 'bg-amber-50 text-amber-900 ring-amber-300 hover:bg-amber-100',
        )}
      >
        {enabled ? <RadioTower className="h-4 w-4" aria-hidden /> : <Radio className="h-4 w-4" aria-hidden />}
        <span className="hidden sm:inline">البث العام:</span> {enabled ? 'مفعّل' : 'متوقف'}
      </button>
      <span
        role="tooltip"
        aria-hidden
        className="pointer-events-none absolute end-0 top-full z-50 mt-2 hidden w-56 rounded-lg bg-ink px-3 py-2 text-xs font-medium text-white shadow-pop peer-hover:block peer-focus-visible:block"
      >
        البث العام {enabled ? 'مفعّل: الطلبات الجديدة تُعرض على الكباتن المؤهلين.' : 'متوقف: الطلبات الجديدة تبقى في طابور الإدارة.'} اضغط لـ{enabled ? 'الإيقاف' : 'التفعيل'}.
      </span>
      <BroadcastConfirmDialog next={pending} onClose={() => setPending(null)} />
    </span>
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
          <span className="absolute -end-0.5 -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-[11px] font-bold text-white">{unread}</span>
        )}
      </button>
      {open && (
        <div className="fixed inset-x-4 top-16 sm:absolute sm:inset-x-auto sm:end-0 sm:top-12 z-50 w-[min(20rem,calc(100vw-2rem))] overflow-hidden rounded-2xl border border-cream-deep bg-white shadow-pop">
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
