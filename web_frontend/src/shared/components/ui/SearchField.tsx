import type { InputHTMLAttributes } from 'react';
import { Search } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { Input } from './Inputs';

/** Text input with a leading search icon. `label` doubles as the accessible name. */
export function SearchField({
  label,
  className,
  ...rest
}: { label: string; className?: string } & Omit<InputHTMLAttributes<HTMLInputElement>, 'className' | 'type'>) {
  return (
    <div className={cn('relative', className)}>
      <Search className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted" aria-hidden />
      <Input type="search" className="ps-9" aria-label={label} {...rest} />
    </div>
  );
}
