import type { ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

/** `compact`: a single short line for sections that are often empty (no tall blank card). */
export function EmptyState({ icon, title, description, action, compact }: { icon?: ReactNode; title: ReactNode; description?: ReactNode; action?: ReactNode; compact?: boolean }) {
  if (compact) {
    return <p className="px-5 py-4 text-sm text-ink-muted">{title}</p>;
  }
  return (
    <div className={cn('flex flex-col items-center justify-center gap-2 px-6 py-10 text-center')}>
      {icon && <div className="mb-1 rounded-2xl bg-cream p-3 text-sand-ink">{icon}</div>}
      <p className="font-bold text-ink">{title}</p>
      {description && <p className="max-w-sm text-sm text-ink-muted">{description}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
