import { LogoWatermark } from '@/shared/components/LogoWatermark';
import { AuroraBackground } from './AuroraBackground';
import { SilkBackground } from './SilkBackground';
import { GridBackground } from './GridBackground';
import { ShahmDeliveryCar } from './ShahmDeliveryCar';
import type { BackgroundVariant } from './useBackgroundPreview';

/**
 * Picks one brand-panel background. Default: the official SHAHM delivery car driving
 * behind the large monochrome watermark (layer order: car, then watermark, then content).
 * The preview variants drop both so effects never stack.
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
      return (
        <>
          <ShahmDeliveryCar />
          <LogoWatermark className="left-1/2 top-1/2 w-[125%] -translate-x-1/2 -translate-y-1/2" />
        </>
      );
  }
}
