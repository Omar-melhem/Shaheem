import { useEffect, useId, useState, type ReactNode } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { Menu, X, type LucideIcon } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { trapTabKey, useEscape, useFocusOnOpen } from '../ui/overlay';

/** A sidebar entry: a route link, or an action such as opening the support dialog. */
export type ShellNavItem =
  | { kind?: 'link'; to: string; label: string; icon: LucideIcon; end?: boolean; badge?: ReactNode }
  | { kind: 'action'; label: string; icon: LucideIcon; onSelect: () => void };

/** Same breakpoint as Tailwind `lg`: from here the sidebar is persistent; below it is a drawer. */
const DESKTOP_QUERY = '(min-width: 1024px)';

const itemClass = (active: boolean) =>
  cn(
    'flex min-h-11 w-full items-center gap-3 rounded-xl px-3 py-2 text-start text-sm font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300',
    active ? 'bg-primary text-white shadow-sm' : 'text-ink-soft hover:bg-cream-dark',
  );

function NavList({ items, label, onNavigate }: { items: ShellNavItem[]; label: string; onNavigate?: () => void }) {
  return (
    <nav aria-label={label} className="p-3">
      <ul className="space-y-1">
        {items.map((item) => {
          const Icon = item.icon;
          if (item.kind === 'action') {
            return (
              <li key={item.label}>
                <button type="button" className={itemClass(false)} onClick={() => { onNavigate?.(); item.onSelect(); }}>
                  <Icon className="h-[18px] w-[18px] shrink-0" aria-hidden />
                  <span className="min-w-0 flex-1 truncate">{item.label}</span>
                </button>
              </li>
            );
          }
          return (
            <li key={item.to}>
              <NavLink to={item.to} end={item.end} onClick={onNavigate} className={({ isActive }) => itemClass(isActive)}>
                <Icon className="h-[18px] w-[18px] shrink-0" aria-hidden />
                <span className="min-w-0 flex-1 truncate">{item.label}</span>
                {item.badge}
              </NavLink>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

/**
 * Admin and Merchant web shell (Arabic RTL). From `lg` a persistent sidebar sits on the right
 * (first flex child in RTL) and the content takes the remaining width; below `lg` the same items
 * open in an off-canvas drawer from the right, and the closed drawer reserves no space.
 * Presentation only: authorisation stays in the route guards, actions come from the caller.
 */
export function AppShell({
  brand,
  mobileBrand,
  nav,
  navLabel,
  headerActions,
  sidebarFooter,
  children,
}: {
  /** Top of the sidebar and the drawer. */
  brand: ReactNode;
  /** Compact identity shown in the phone top bar next to the menu button. */
  mobileBrand?: ReactNode;
  nav: ShellNavItem[];
  navLabel: string;
  /** Global actions for the top bar (e.g. broadcast and notifications). Without them the bar exists on phones only. */
  headerActions?: ReactNode;
  sidebarFooter?: ReactNode;
  children: ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const { pathname } = useLocation();
  const drawerId = useId();
  const close = () => setOpen(false);
  useEscape(open, close);
  const drawerRef = useFocusOnOpen(open);

  useEffect(() => setOpen(false), [pathname]);
  // A drawer left open while widening to desktop must not keep the page scroll-locked.
  useEffect(() => {
    const mq = typeof window.matchMedia === 'function' ? window.matchMedia(DESKTOP_QUERY) : null;
    if (!mq) return;
    const onChange = () => mq.matches && setOpen(false);
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  return (
    <div className="flex min-h-screen">
      <aside className="sticky top-0 hidden h-screen w-64 shrink-0 flex-col border-e border-cream-deep bg-white lg:flex print:hidden" data-testid="shell-sidebar">
        <div className="border-b border-cream-dark px-4 py-3">{brand}</div>
        <div className="min-h-0 flex-1 overflow-y-auto">
          <NavList items={nav} label={navLabel} />
        </div>
        {sidebarFooter && <div className="border-t border-cream-dark p-3 text-[11px] text-ink-muted">{sidebarFooter}</div>}
      </aside>

      {open && (
        <div className="fixed inset-0 z-[850] lg:hidden">
          <div className="absolute inset-0 bg-ink/40" onClick={close} aria-hidden />
          <div
            ref={drawerRef}
            id={drawerId}
            role="dialog"
            aria-modal="true"
            aria-label={navLabel}
            tabIndex={-1}
            onKeyDown={trapTabKey}
            className="absolute inset-y-0 start-0 flex w-72 max-w-[85vw] flex-col bg-white shadow-pop focus:outline-none"
          >
            <div className="flex items-center justify-between gap-2 border-b border-cream-dark px-4 py-3">
              <div className="min-w-0 flex-1">{brand}</div>
              <button data-close type="button" onClick={close} aria-label="إغلاق القائمة" className="inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-lg hover:bg-cream">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
              <NavList items={nav} label={navLabel} onNavigate={close} />
            </div>
          </div>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header
          className={cn(
            'sticky top-0 z-[700] flex items-center gap-1 border-b border-cream-deep bg-cream/95 px-3 py-2 backdrop-blur sm:gap-3 sm:px-4 lg:px-6 print:hidden',
            !headerActions && 'lg:hidden',
          )}
        >
          <button
            type="button"
            className="inline-flex h-11 w-11 shrink-0 items-center justify-center rounded-lg hover:bg-cream-dark lg:hidden"
            onClick={() => setOpen(true)}
            aria-label="فتح القائمة"
            aria-expanded={open}
            aria-controls={open ? drawerId : undefined}
          >
            <Menu className="h-5 w-5" />
          </button>
          <div className="min-w-0 flex-1">{mobileBrand && <div className="lg:hidden">{mobileBrand}</div>}</div>
          {headerActions}
        </header>
        <main className="mx-auto w-full min-w-0 max-w-[1400px] flex-1 px-4 py-6 lg:px-6 print:max-w-none print:p-0">{children}</main>
      </div>
    </div>
  );
}
