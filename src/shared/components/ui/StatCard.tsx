import type { ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';
import { Card } from './Card';

export function StatCard({ label, value, icon, tone = 'neutral', hint }: { label: string; value: ReactNode; icon?: ReactNode; tone?: 'neutral' | 'primary' | 'secondary' | 'warning' | 'danger'; hint?: ReactNode }) {
  const tones = {
    neutral: 'bg-cream text-ink-soft',
    primary: 'bg-primary-50 text-primary',
    secondary: 'bg-secondary-50 text-secondary',
    warning: 'bg-amber-50 text-amber-700',
    danger: 'bg-red-50 text-red-700',
  };
  return (
    <Card className="flex h-full flex-col items-start gap-2 p-3 sm:flex-row sm:items-center sm:gap-4 sm:p-4">
      {icon && <div className={cn('shrink-0 rounded-xl p-2 sm:p-2.5', tones[tone])}>{icon}</div>}
      <div className="min-w-0">
        <p className="text-xs font-medium text-ink-muted">{label}</p>
        <p className="text-2xl font-extrabold leading-tight text-ink">{value}</p>
        {hint && <p className="text-[11px] text-ink-muted">{hint}</p>}
      </div>
    </Card>
  );
}
