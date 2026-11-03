import { cn } from '@/shared/lib/cn';

/**
 * Official SHAHM artwork, never redrawn or recoloured. This file is the supplied
 * logo with only its white margins trimmed (pixels unchanged); the original is
 * kept at /brand/shahm-logo.png.
 */
export const LOGO_SRC = '/brand/shahm-logo-trimmed.png';

/**
 * Official SHAHM logo at its natural aspect ratio. Size it with a height class
 * (default h-12). `mix-blend-multiply` lets the white background sit on cream
 * surfaces. `decorative` hides it from assistive tech when a visible name is next to it.
 */
export function Logo({ className, blend = true, decorative }: { className?: string; blend?: boolean; decorative?: boolean }) {
  return (
    <img
      src={LOGO_SRC}
      alt={decorative ? '' : 'شهم — SHAHM'}
      aria-hidden={decorative || undefined}
      draggable={false}
      className={cn('inline-block w-auto shrink-0 select-none', blend && 'mix-blend-multiply', className ?? 'h-12')}
    />
  );
}
