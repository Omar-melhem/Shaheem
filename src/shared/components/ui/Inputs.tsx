import { forwardRef, type InputHTMLAttributes, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react';
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

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Select({ className, children, ...rest }, ref) {
  return (
    <select ref={ref} className={cn(inputBase, 'h-10 pe-8', className)} {...rest}>
      {children}
    </select>
  );
});
