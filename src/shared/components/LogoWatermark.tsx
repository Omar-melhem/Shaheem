import { cn } from '@/shared/lib/cn';
import { LOGO_SRC } from './Logo';

/**
 * Decorative brand texture: the official logo rendered monochrome (CSS grayscale —
 * the asset itself is untouched) at ~7% on the wrapper, so the burgundy/green
 * artwork reads as a soft charcoal (#444-ish) watermark, never a second logo.
 *
 * Opacity and blend sit on the wrapper, not the image, so the one-time fade-in
 * on the image can't override them. Multiply drops the PNG's white background.
 * Hidden from assistive tech and pointer input; place inside a `relative
 * overflow-hidden` parent with content in a `relative` layer above it.
 */
export function LogoWatermark({ className }: { className?: string }) {
  return (
    <div className="pointer-events-none absolute inset-0 select-none overflow-hidden opacity-[0.07] mix-blend-multiply" aria-hidden="true">
      <img src={LOGO_SRC} alt="" draggable={false} className={cn('absolute max-w-none grayscale motion-safe:animate-fade', className)} />
    </div>
  );
}
