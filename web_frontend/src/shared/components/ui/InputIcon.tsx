import type { ReactNode } from 'react';

/** Padding the wrapped input needs to clear the leading icon (page direction, works for dir="ltr" inputs too). */
export const INPUT_ICON_PAD = 'rtl:pr-10 ltr:pl-10';

/** Places a decorative icon at the start of an input (right in RTL). The icon is hidden from screen readers. */
export function InputIcon({ icon, children }: { icon?: ReactNode; children: ReactNode }) {
  return (
    <div className="relative">
      {icon && (
        <span className="pointer-events-none absolute inset-y-0 start-0 flex w-10 items-center justify-center text-ink-muted [&>svg]:h-[18px] [&>svg]:w-[18px]" aria-hidden>
          {icon}
        </span>
      )}
      {children}
    </div>
  );
}
