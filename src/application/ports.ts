import type { LatLng } from '@/domain/types';

// Ports the application layer depends on. Infrastructure supplies implementations,
// so the mock place search can later be swapped for Google Places / Mapbox / OSM
// (provider is open — SRS O-018) without touching UI or use cases.

export interface PlaceSuggestion {
  id: string;
  /** Primary label, e.g. "سوبرماركت الخالد". */
  name: string;
  /** Secondary context, e.g. "الجبيهة، عمّان". */
  context: string;
  kind: 'landmark' | 'street' | 'neighborhood' | 'business';
  position: LatLng | null;
}

export class PlaceProviderError extends Error {}

export interface PlaceProvider {
  readonly isSimulated: boolean;
  search(query: string, signal?: AbortSignal): Promise<PlaceSuggestion[]>;
}
