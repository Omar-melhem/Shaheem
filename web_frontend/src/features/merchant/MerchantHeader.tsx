import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Headphones, LogOut, Settings, Tags } from 'lucide-react';
import type { Merchant } from '@/domain/types';
import { Logo } from '@/shared/components/Logo';
import { Button, Dialog } from '@/shared/components/ui';
import { SupportContactList } from '@/features/support/SupportContacts';
import { useSignOut } from '@/features/auth/hooks/useSignOut';

const iconLink = 'inline-flex h-10 items-center gap-2 rounded-xl px-3 text-sm font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300';

const SUBTITLE = { home: 'بوابة التاجر', settings: 'الإعدادات', areas: 'مناطق التوصيل والأسعار', orders: 'سجل الطلبات' } as const;

/** Merchant top bar shared by the operations screen, the areas & prices list and settings. */
export function MerchantHeader({ merchant, page }: { merchant: Merchant; page: keyof typeof SUBTITLE }) {
  const signOut = useSignOut();
  const [supportOpen, setSupportOpen] = useState(false);

  return (
    <header className="border-b border-cream-deep bg-white">
      <div className="mx-auto flex max-w-6xl items-center gap-2 px-4 py-3 sm:gap-4">
        <Logo className="h-11" />
        <div className="min-w-0 flex-1 border-s border-cream-deep ps-4">
          <p className="truncate font-extrabold text-ink">{merchant.businessName}</p>
          <p className="truncate text-xs text-ink-muted">{SUBTITLE[page]}</p>
        </div>
        {page === 'home' ? (
          <>
            <Button variant="outline" icon={<Headphones className="h-4 w-4" />} onClick={() => setSupportOpen(true)} aria-label="دعم شهم">
              <span className="hidden sm:inline">دعم شهم</span>
            </Button>
            <Link to="/merchant/areas" className={`${iconLink} text-ink-soft hover:bg-cream-dark`} aria-label="مناطق التوصيل والأسعار">
              <Tags className="h-4 w-4" aria-hidden />
              <span className="hidden md:inline">المناطق والأسعار</span>
            </Link>
            <Link to="/merchant/settings" className={`${iconLink} text-ink-soft hover:bg-cream-dark`} aria-label="الإعدادات">
              <Settings className="h-4 w-4" aria-hidden />
              <span className="hidden md:inline">الإعدادات</span>
            </Link>
          </>
        ) : (
          <Link to="/merchant" className={`${iconLink} bg-primary text-white hover:bg-primary-600`}>
            <ArrowRight className="h-4 w-4" aria-hidden />
            <span>طلب كابتن</span>
          </Link>
        )}
        <Button variant="ghost" icon={<LogOut className="h-4 w-4" />} onClick={signOut} aria-label="خروج">
          <span className="hidden sm:inline">خروج</span>
        </Button>
      </div>
      <Dialog open={supportOpen} onClose={() => setSupportOpen(false)} title="تواصل مع شهم" description="قنوات الدعم الرسمية">
        <SupportContactList />
      </Dialog>
    </header>
  );
}
