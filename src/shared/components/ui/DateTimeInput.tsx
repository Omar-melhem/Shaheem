import { forwardRef, type InputHTMLAttributes } from 'react';
import { CalendarDays, Clock } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { inputBase } from './Inputs';

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'value' | 'placeholder'> & {
  type: 'date' | 'time';
  /** Machine value: `YYYY-MM-DD` for date, `HH:mm` for time; '' when unset. */
  value: string;
  /** Shown while empty: iOS Safari renders an empty native date/time input as a blank box. */
  emptyHint: string;
};

/**
 * Native date/time input that reads the same on iOS Safari, Chromium and Firefox.
 * The native picker is kept (no custom picker); `.shahm-datetime` in index.css removes WebKit's
 * native chrome that clips the value, and stretches Chromium's picker button over the whole field.
 * The value is LTR inside the RTL page and aligned to the right, like the page text.
 * The hint and icon ignore pointer events, so every tap reaches the input itself.
 * `className` sizes the wrapper.
 */
export const DateTimeInput = forwardRef<HTMLInputElement, Props>(function DateTimeInput({ type, value, emptyHint, className, ...rest }, ref) {
  const Icon = type === 'date' ? CalendarDays : Clock;
  const empty = !value;
  return (
    <span className={cn('relative block min-w-0 max-w-full w-full', className)}>
      <input
        ref={ref}
        type={type}
        value={value}
        dir="ltr"
        data-empty={empty || undefined}
        className={cn(inputBase, 'shahm-datetime peer relative h-12 cursor-pointer pl-11 pr-4 text-right text-base disabled:cursor-not-allowed')}
        {...rest}
      />
      {empty && (
        <span aria-hidden className="pointer-events-none absolute inset-y-0 start-4 end-11 flex items-center truncate text-base text-ink-muted peer-focus:hidden">
          {emptyHint}
        </span>
      )}
      <Icon aria-hidden className="pointer-events-none absolute end-3.5 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-muted peer-disabled:opacity-50" strokeWidth={2} />
    </span>
  );
});
