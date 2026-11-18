import type { ReactNode } from 'react';
import { Logo } from '@/shared/components/Logo';
import { LOGIN_SLOGAN, LOGIN_TITLE, LoginCar } from './LoginBrand';

/**
 * Brand panel (tablet and up): logo → «شهم درايف» → slogan → the branded car, centred.
 * `background` is a decorative layer behind the content; `overlay` hosts preview-only controls.
 * Phones get a compact version of the same content in `LoginHeader`.
 */
export function BrandShowcase({ background, overlay }: { background: ReactNode; overlay?: ReactNode }) {
  return (
    <section aria-label="شهم" className="relative hidden overflow-hidden bg-gradient-to-b from-cream to-cream-dark md:flex md:items-center md:justify-center">
      {background}
      {overlay}
      <div className="relative flex w-full max-w-xl flex-col items-center px-8 py-12 text-center lg:px-12">
        <Logo className="h-20 motion-safe:animate-rise lg:h-24" />
        <p className="mt-6 text-4xl font-extrabold leading-tight text-primary motion-safe:animate-rise motion-safe:[animation-delay:120ms] lg:text-5xl">{LOGIN_TITLE}</p>
        <p className="mt-3 text-lg font-bold leading-relaxed text-secondary motion-safe:animate-fade motion-safe:[animation-delay:200ms] lg:text-xl">{LOGIN_SLOGAN}</p>
        <LoginCar priority className="mt-8 motion-safe:animate-fade motion-safe:[animation-delay:260ms]" />
      </div>
    </section>
  );
}
