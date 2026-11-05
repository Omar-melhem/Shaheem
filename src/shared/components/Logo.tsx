import { cn } from '@/shared/lib/cn';

/**
 * Official SHAHM artwork, never redrawn or recoloured: the supplied logo with only its
 * surrounding white and letter counters made transparent (the keffiyeh's white is artwork
 * and stays). The original is kept at /brand/shahm-logo.png.
 */
export const LOGO_SRC = '/brand/shahm-logo-transparent.png';
const LOGO_WIDTH = 861;
const LOGO_HEIGHT = 498;

/**
 * Official SHAHM logo at its natural aspect ratio. Size it with a height class
 * (default h-12). `decorative` hides it from assistive tech when a visible name is next to it.
 */
export function Logo({ className, decorative }: { className?: string; decorative?: boolean }) {
  return (
    <img
      src={LOGO_SRC}
      alt={decorative ? '' : 'شهم — SHAHM'}
      aria-hidden={decorative || undefined}
      width={LOGO_WIDTH}
      height={LOGO_HEIGHT}
      draggable={false}
      className={cn('inline-block w-auto shrink-0 select-none object-contain', className ?? 'h-12')}
    />
  );
}
