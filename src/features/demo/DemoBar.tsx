import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { FlaskConical, LayoutDashboard, Smartphone, Store, SlidersHorizontal } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { cn } from '@/shared/lib/cn';
import { DemoControlsDrawer } from './DemoControlsDrawer';

/**
 * Presenter-only bar for role switching (SRS §19.5, §19.8). Clearly marked as demo
 * mode — not production navigation or authentication.
 */
export function DemoBar() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const [controlsOpen, setControlsOpen] = useState(false);

  const merchantMatch = pathname.match(/^\/merchant\/([^/]+)/);
  const captainMatch = pathname.match(/^\/captain\/([^/]+)/);
  const role = pathname.startsWith('/admin') ? 'admin' : merchantMatch ? 'merchant' : captainMatch ? 'captain' : null;

  const chip = (active: boolean) =>
    cn('inline-flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-xs font-bold transition-colors', active ? 'bg-sand text-ink' : 'text-cream/90 hover:bg-white/10');

  return (
    <>
      <div className="relative z-[800] bg-ink text-cream">
        <div className="mx-auto flex max-w-[1600px] flex-wrap items-center gap-x-3 gap-y-2 px-4 py-1.5">
          <Link to="/" className="flex items-center gap-1.5 text-xs font-bold text-sand">
            <FlaskConical className="h-4 w-4" aria-hidden />
            وضع العرض التجريبي
          </Link>
          <span className="hidden text-[11px] text-cream/60 md:inline">بيانات ومواقع محاكاة · ليست منصة إنتاجية</span>
          <nav className="flex flex-1 flex-wrap items-center justify-end gap-1" aria-label="تبديل الدور التجريبي">
            <Link to="/admin" className={chip(role === 'admin')}>
              <LayoutDashboard className="h-3.5 w-3.5" aria-hidden /> الإدارة
            </Link>
            <label className={chip(role === 'merchant')}>
              <Store className="h-3.5 w-3.5" aria-hidden />
              <span className="sr-only">التاجر</span>
              <select
                className="max-w-[9.5rem] cursor-pointer bg-transparent text-xs font-bold focus:outline-none"
                value={merchantMatch?.[1] ?? ''}
                onChange={(e) => e.target.value && navigate(`/merchant/${e.target.value}`)}
              >
                <option value="" className="text-ink">
                  التاجر…
                </option>
                {merchants.map((m) => (
                  <option key={m.id} value={m.id} className="text-ink">
                    {m.businessName}
                  </option>
                ))}
              </select>
            </label>
            <label className={chip(role === 'captain')}>
              <Smartphone className="h-3.5 w-3.5" aria-hidden />
              <span className="sr-only">الكابتن</span>
              <select
                className="max-w-[9.5rem] cursor-pointer bg-transparent text-xs font-bold focus:outline-none"
                value={captainMatch?.[1] ?? ''}
                onChange={(e) => e.target.value && navigate(`/captain/${e.target.value}`)}
              >
                <option value="" className="text-ink">
                  الكابتن…
                </option>
                {captains.map((c) => (
                  <option key={c.id} value={c.id} className="text-ink">
                    {c.fullName}
                  </option>
                ))}
              </select>
            </label>
            <button onClick={() => setControlsOpen(true)} className={cn(chip(false), 'border border-sand/40')}>
              <SlidersHorizontal className="h-3.5 w-3.5" aria-hidden /> أدوات العرض
            </button>
          </nav>
        </div>
      </div>
      <DemoControlsDrawer open={controlsOpen} onClose={() => setControlsOpen(false)} />
    </>
  );
}
