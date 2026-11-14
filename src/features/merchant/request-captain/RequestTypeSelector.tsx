import { CalendarClock, Zap } from 'lucide-react';
import type { RequestType } from '@/domain/types';
import { cn } from '@/shared/lib/cn';

const OPTIONS: Array<{ value: RequestType; label: string; hint: string; Icon: typeof Zap }> = [
  { value: 'immediate', label: 'طلب فوري', hint: 'إرسال الطلب للكباتن المتاحين الآن', Icon: Zap },
  { value: 'scheduled', label: 'طلب مؤجل', hint: 'تحديد موعد لاحق لاستلام الطلب', Icon: CalendarClock },
];

/** Immediate vs scheduled as two cards (CR v1.4 §6.1). A radio group, keyboard accessible. */
export function RequestTypeSelector({ value, onChange }: { value: RequestType; onChange: (v: RequestType) => void }) {
  return (
    <div role="radiogroup" aria-label="نوع الطلب" className="grid grid-cols-1 gap-3 sm:grid-cols-2">
      {OPTIONS.map(({ value: v, label, hint, Icon }) => {
        const selected = value === v;
        return (
          <button
            key={v}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(v)}
            className={cn(
              'rounded-xl border bg-white px-4 py-3 text-start transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300',
              selected ? 'border-secondary ring-1 ring-secondary' : 'border-cream-deep hover:border-sand',
            )}
          >
            <span className="flex items-center gap-2">
              <Icon className={cn('h-4 w-4 shrink-0', selected ? 'text-secondary' : 'text-ink-soft')} aria-hidden />
              <span className="text-sm font-extrabold text-ink">{label}</span>
            </span>
            <span className="mt-1 block text-xs text-ink-muted">{hint}</span>
          </button>
        );
      })}
    </div>
  );
}
