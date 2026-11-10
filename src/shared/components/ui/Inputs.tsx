import { forwardRef, type InputHTMLAttributes, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react';
import { ChevronDown } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

/** Shared input styling — change it here and every field follows. */
export const inputBase =
  'w-full rounded-xl border border-cream-deep bg-white px-3 text-sm transition-[border-color,box-shadow] duration-150 text-ink placeholder:text-ink-muted/70 focus:border-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-100 disabled:bg-cream disabled:text-ink-muted aria-[invalid=true]:border-red-400';

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(function Input({ className, ...rest }, ref) {
  return <input ref={ref} className={cn(inputBase, 'h-10', className)} {...rest} />;
});

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(function Textarea({ className, ...rest }, ref) {
  return <textarea ref={ref} className={cn(inputBase, 'min-h-[72px] py-2', className)} {...rest} />;
});

/**
 * The one dropdown in SHAHM (Master Prompt §13 chevron standard): the native arrow is hidden and
 * a single ChevronDown sits inside the control at the inline end (left in RTL) with a fixed 14px
 * inset, vertically centred; text keeps 16px from the start edge and never runs under the icon.
 * `className` sizes the wrapper (e.g. `w-44`); the control always fills it.
 */
export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Select({ className, children, ...rest }, ref) {
  return (
    <span className={cn('relative block w-full', className)}>
      <select ref={ref} className={cn(inputBase, 'h-10 cursor-pointer appearance-none truncate ps-4 pe-11 disabled:cursor-not-allowed')} {...rest}>
        {children}
      </select>
      <ChevronDown
        aria-hidden
        className={cn('pointer-events-none absolute end-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-ink-muted', rest.disabled && 'opacity-50')}
        strokeWidth={2}
      />
    </span>
  );
});
