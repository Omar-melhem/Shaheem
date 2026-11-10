import type { ReactNode } from 'react';
import { FlaskConical } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

/** Marks simulated data/behaviour so it is never mistaken for production (SRS §19.3). */
export function SimTag({ children = 'محاكاة', className }: { children?: ReactNode; className?: string }) {
  return (
    <span className={cn('inline-flex items-center gap-1 rounded-md border border-dashed border-sand-dark/60 bg-sand-light/40 px-1.5 py-0.5 text-[11px] font-bold text-sand-dark', className)}>
      <FlaskConical className="h-3 w-3" aria-hidden />
      {children}
    </span>
  );
}

/** Notes an open Product Owner decision behind a demo behaviour. */
export function OpenDecision({ id, children }: { id: string; children: ReactNode }) {
  return (
    <p className="flex items-start gap-2 rounded-lg bg-cream px-3 py-2 text-xs text-ink-muted">
      <span className="mt-px shrink-0 rounded bg-white px-1.5 font-bold text-primary ring-1 ring-cream-deep" dir="ltr">
        {id}
      </span>
      <span>{children}</span>
    </p>
  );
}
