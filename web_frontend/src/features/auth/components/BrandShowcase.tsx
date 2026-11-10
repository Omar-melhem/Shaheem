import type { ReactNode } from 'react';
import { Logo } from '@/shared/components/Logo';

/**
 * Left brand panel: logo, headline and one short line, centred on both axes.
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
          منصة تشغيل التوصيل للأعمال
        </h2>
        <p className="mt-4 max-w-sm text-base leading-relaxed text-ink-soft motion-safe:animate-fade motion-safe:[animation-delay:220ms] lg:text-lg">
          إدارة الطلبات والكباتن والمتاجر في مكان واحد.
        </p>
      </div>
    </section>
  );
}
