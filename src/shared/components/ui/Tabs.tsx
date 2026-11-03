import type { ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

export function Tabs<T extends string>({ value, onChange, items }: { value: T; onChange: (v: T) => void; items: Array<{ value: T; label: ReactNode; count?: number }> }) {
  return (
    <div role="tablist" className="inline-flex flex-wrap gap-1 rounded-xl bg-cream-dark p-1">
      {items.map((it) => (
        <button
          key={it.value}
          role="tab"
          aria-selected={value === it.value}
          onClick={() => onChange(it.value)}
          className={cn(
            'inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-bold transition-colors',
            value === it.value ? 'bg-white text-primary shadow-sm' : 'text-ink-muted hover:text-ink',
          )}
        >
          {it.label}
          {it.count !== undefined && (
            <span className={cn('rounded-full px-1.5 text-xs', value === it.value ? 'bg-primary-50' : 'bg-cream')}>{it.count}</span>
          )}
        </button>
      ))}
    </div>
  );
}
