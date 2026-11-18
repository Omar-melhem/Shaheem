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
      <div className="relative flex max-w-md flex-col items-center px-10 py-16 text-center">
        <Logo className="h-28 motion-safe:animate-rise lg:h-36" />
        <h2 className="mt-10 text-3xl font-extrabold leading-snug text-secondary motion-safe:animate-rise motion-safe:[animation-delay:120ms] lg:text-4xl">
          {LOGIN_TITLE}
        </h2>
        {/* Extra line height so the tashkeel above and below the letters is never clipped. */}
        <p className="mt-3 max-w-sm text-lg font-bold leading-[2] text-primary motion-safe:animate-fade motion-safe:[animation-delay:220ms] lg:text-xl">
          {LOGIN_SLOGAN}
        </p>
      </div>
    </section>
  );
}
