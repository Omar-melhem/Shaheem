import { LogoWatermark } from '@/shared/components/LogoWatermark';
import { AuroraBackground } from './AuroraBackground';
import { SilkBackground } from './SilkBackground';
import { GridBackground } from './GridBackground';
import type { BackgroundVariant } from './useBackgroundPreview';

/**
 * Picks one brand-panel background. Default: the large monochrome watermark only — the
 * branded car is now the panel's content (`LoginCar`), not a background.
 * The preview variants drop the watermark so effects never stack.
 */
export function BrandBackground({ variant }: { variant: BackgroundVariant }) {
  switch (variant) {
    case 'aurora':
      return <AuroraBackground />;
    case 'silk':
      return <SilkBackground />;
    case 'grid':
      return <GridBackground />;
    default:
      return <LogoWatermark className="left-1/2 top-1/2 w-[125%] -translate-x-1/2 -translate-y-1/2" />;
  }
}
