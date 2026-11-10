import { Link } from 'react-router-dom';
import { Map, Users } from 'lucide-react';
import type { AvailabilitySummary } from '@/application/dashboard';
import { Card, CardHeader } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';

const ROWS: Array<{ key: keyof AvailabilitySummary; label: string; dot: string }> = [
  { key: 'available', label: 'متاح', dot: 'bg-secondary' },
  { key: 'busy', label: 'في توصيل', dot: 'bg-primary' },
  { key: 'offline', label: 'غير متاح', dot: 'bg-ink-muted' },
  { key: 'inactive', label: 'حساب موقوف', dot: 'bg-red-600' },
];

/** Captains by their real operational status; the map stays on its own page. */
export function CaptainAvailabilityCard({ summary }: { summary: AvailabilitySummary }) {
  const total = ROWS.reduce((n, r) => n + summary[r.key], 0);
  return (
    <Card className="min-w-0">
      <CardHeader
        title="توفر الكباتن"
        icon={<Users className="h-5 w-5" />}
        actions={
          <Link to="/admin/map" className="inline-flex items-center gap-1.5 text-sm font-bold text-primary hover:underline">
            <Map className="h-4 w-4" aria-hidden /> الخريطة الحية
          </Link>
        }
      />
      <div className="space-y-3 px-5 pb-5">
        <div className="flex h-2.5 overflow-hidden rounded-full bg-cream" aria-hidden>
          {ROWS.map((r) => summary[r.key] > 0 && <div key={r.key} className={r.dot} style={{ width: `${(summary[r.key] / Math.max(1, total)) * 100}%` }} />)}
        </div>
        <ul className="grid gap-2 sm:grid-cols-2 lg:grid-cols-4">
          {ROWS.map((r) => (
            <li key={r.key} className="flex items-center gap-3 rounded-xl bg-cream/70 px-3 py-2.5 text-sm">
              <span className={cn('h-2.5 w-2.5 shrink-0 rounded-full', r.dot)} aria-hidden />
              <span className="flex-1 text-ink-soft">{r.label}</span>
              <span className="font-extrabold text-ink">{summary[r.key]}</span>
            </li>
          ))}
        </ul>
      </div>
    </Card>
  );
}
