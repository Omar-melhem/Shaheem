import { useState, type ReactNode } from 'react';
import { ChevronDown } from 'lucide-react';
import { useAppStore, DEMO_ADMIN } from '@/app/state';
import { Button, Select, SimTag } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { useDemoSignIn } from '../hooks/useDemoSignIn';

/**
 * Presenter shortcut, collapsed by default: every demo account in one place. Each button signs in
 * through the same credential check as the form, so role routing is unchanged.
 * Prototype only — a production login has no account list.
 */
export function DemoAccountsPanel() {
  const signInWith = useDemoSignIn();
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const [merchantId, setMerchantId] = useState(merchants[0]?.id ?? '');
  const [captainId, setCaptainId] = useState(captains[0]?.id ?? '');

  const enterAs = (account?: { username: string; password: string }) => account && reportResult(signInWith(account.username, account.password));

  return (
    <details className="group mt-8 rounded-2xl border border-dashed border-sand-dark/50 bg-cream/50">
      <summary className="flex cursor-pointer list-none items-center gap-2 rounded-2xl px-4 py-3 text-sm font-bold text-ink-soft transition-colors hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 [&::-webkit-details-marker]:hidden">
        <ChevronDown className="h-4 w-4 transition-transform duration-150 group-open:rotate-180" aria-hidden />
        <span className="flex-1">حسابات العرض</span>
        <SimTag>تجريبي</SimTag>
      </summary>
      <div className="space-y-2 px-4 pb-4">
        <DemoRow label="الإدارة" onEnter={() => enterAs(DEMO_ADMIN)} />
        <DemoRow label="تاجر" onEnter={() => enterAs(merchants.find((m) => m.id === merchantId))}>
          <Select value={merchantId} onChange={(e) => setMerchantId(e.target.value)} aria-label="اختر حساب التاجر">
            {merchants.map((m) => (
              <option key={m.id} value={m.id}>
                {m.businessName}
                {m.status !== 'active' ? ' (غير مفعّل)' : ''}
              </option>
            ))}
          </Select>
        </DemoRow>
        <DemoRow label="كابتن" onEnter={() => enterAs(captains.find((c) => c.id === captainId))}>
          <Select value={captainId} onChange={(e) => setCaptainId(e.target.value)} aria-label="اختر حساب الكابتن">
            {captains.map((c) => (
              <option key={c.id} value={c.id}>
                {c.fullName}
                {c.status !== 'active' ? ' (موقوف)' : ''}
              </option>
            ))}
          </Select>
        </DemoRow>
      </div>
    </details>
  );
}

function DemoRow({ label, onEnter, children }: { label: string; onEnter: () => void; children?: ReactNode }) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-14 shrink-0 text-sm font-bold text-ink-soft">{label}</span>
      <div className="min-w-0 flex-1">{children}</div>
      <Button variant="outline" size="md" className="shrink-0" onClick={onEnter} aria-label={`الدخول كـ${label}`}>
        دخول
      </Button>
    </div>
  );
}
