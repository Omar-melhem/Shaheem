import { createContext, useContext, type ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

/** Set by `FormRow`: a `Field` inside joins the row's shared label / control / message tracks. */
const FormRowContext = createContext(false);
export const useInFormRow = () => useContext(FormRowContext);

/**
 * A row of fields. Below `md` the fields stack in one column. From `md`, two columns whose fields use
 * CSS subgrid over three shared tracks (label, control, message), so the controls always line up:
 * a wrapped label, a «مطلوب» badge or a hint on one side never pushes the other control down.
 * A single child, or one with `wide`, spans both columns (no empty cell).
 */
export function FormRow({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <FormRowContext.Provider value>
      <div className={cn('grid grid-cols-1 gap-x-4 gap-y-4 md:grid-cols-2 md:gap-y-1.5 md:[&>*:only-child]:col-span-2', className)}>{children}</div>
    </FormRowContext.Provider>
  );
}

/** A titled group of form rows; sections are separated by a hairline, no nested cards. */
export function FormSection({ title, children, className }: { title: string; children: ReactNode; className?: string }) {
  return (
    <section className={cn('space-y-4 border-t border-cream-dark pt-5 first:border-t-0 first:pt-0', className)}>
      <h3 className="text-sm font-extrabold text-ink">{title}</h3>
      {children}
    </section>
  );
}
