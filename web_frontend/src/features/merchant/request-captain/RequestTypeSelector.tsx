import { CalendarClock, Zap } from 'lucide-react';
import type { RequestType } from '@/domain/types';
import { cn } from '@/shared/lib/cn';

const OPTIONS: Array<{ value: RequestType; label: string; hint: string; Icon: typeof Zap }> = [
  { value: 'immediate', label: 'طلب فوري', hint: 'يُعرض على أقرب الكباتن الآن', Icon: Zap },
  { value: 'scheduled', label: 'طلب مؤجل', hint: 'تنسّق الإدارة الكابتن لموعد تحدده', Icon: CalendarClock },
];

/** Immediate vs scheduled, chosen first (CR v1.4 §6.1). A radio group, keyboard accessible. */
export function RequestTypeSelector({ value, onChange }: { value: RequestType; onChange: (v: RequestType) => void }) {
  return (
    <div role="radiogroup" aria-label="نوع الطلب" className="grid grid-cols-2 gap-2 rounded-2xl bg-cream p-1.5">
      {OPTIONS.map(({ value: v, label, hint, Icon }) => (
        <button
          key={v}
          type="button"
          role="radio"
          aria-checked={value === v}
          onClick={() => onChange(v)}
          className={cn(
            'flex items-start gap-2 rounded-xl px-3 py-2.5 text-start transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300',
            value === v ? 'bg-white shadow-card ring-1 ring-primary-200' : 'text-ink-soft hover:bg-white/60',
          )}
        >
          <Icon className={cn('mt-0.5 h-5 w-5 shrink-0', value === v ? 'text-primary' : 'text-ink-muted')} aria-hidden />
          <span className="min-w-0">
            <span className="block text-sm font-extrabold">{label}</span>
            <span className="block text-xs text-ink-muted">{hint}</span>
          </span>
        </button>
      ))}
    </div>
  );
}
