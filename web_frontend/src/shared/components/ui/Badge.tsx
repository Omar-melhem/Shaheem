import type { ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';
import type { StatusTone } from '@/domain/orderStatus';

const badgeTones: Record<StatusTone, string> = {
  neutral: 'bg-gray-100 text-gray-700 ring-gray-200',
  sand: 'bg-sand-light/60 text-sand-dark ring-sand/40',
  warning: 'bg-amber-50 text-amber-800 ring-amber-200',
  primary: 'bg-primary-50 text-primary-700 ring-primary-200',
  info: 'bg-sky-50 text-sky-800 ring-sky-200',
  success: 'bg-secondary-50 text-secondary-600 ring-secondary-200',
  danger: 'bg-red-50 text-red-800 ring-red-200',
};

export function Badge({ tone = 'neutral', children, className, dot }: { tone?: StatusTone; children: ReactNode; className?: string; dot?: boolean }) {
  return (
    <span className={cn('inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-bold ring-1 ring-inset', badgeTones[tone], className)}>
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden />}
      {children}
    </span>
  );
}
