import type { ReactNode } from 'react';
import { Logo } from '@/shared/components/Logo';
import { LOGIN_SLOGAN, LOGIN_TITLE } from './LoginBrand';

/**
 * Left brand panel: logo, «شهم درايف» and the vowel-marked tagline, centred on both axes.
 * The driving SHAHM car is part of `background` (`ShahmDeliveryCar`).
 * `background` is a decorative layer behind the content; `overlay` hosts preview-only controls.
 */
export function BrandShowcase({ background, overlay }: { background: ReactNode; overlay?: ReactNode }) {
  return (
    <section aria-label="شهم" className="relative hidden overflow-hidden bg-gradient-to-b from-cream to-cream-dark md:flex md:items-center md:justify-center">
      {background}
      {overlay}
      {/* One tight lockup: ~20px from the visible logo (the asset has ~4% transparent margin) to the title, ~8px to the tagline. */}
      <div className="relative flex max-w-md flex-col items-center px-10 py-16 text-center">
        <Logo className="h-32 motion-safe:animate-rise lg:h-40" />
        <h2 className="mt-4 text-3xl font-bold leading-tight text-secondary motion-safe:animate-rise motion-safe:[animation-delay:120ms] lg:text-4xl lg:leading-tight">
          {LOGIN_TITLE}
        </h2>
        <p className="mt-2 max-w-sm text-balance text-lg font-medium leading-relaxed text-primary motion-safe:animate-fade motion-safe:[animation-delay:220ms] lg:text-xl lg:leading-relaxed">
          {LOGIN_SLOGAN}
        </p>
      </div>
    </section>
  );
}
