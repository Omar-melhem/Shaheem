import type { LatLng } from '@/domain/types';

/**
 * Place search adapter — OpenStreetMap data via the public Photon service
 * (photon.komoot.io), limited to Greater Amman. Demo provider: the production
 * map/search provider is still an open decision (O-018). Swap this file to change it.
 */
export interface PlaceResult {
  id: string;
  name: string;
  /** Street / district for disambiguation. */
  context: string;
  position: LatLng;
}

const AMMAN_BBOX = '35.70,31.80,36.10,32.15'; // minLon,minLat,maxLon,maxLat
const BIAS = 'lat=31.985&lon=35.87';

interface PhotonFeature {
  geometry: { coordinates: [number, number] };
  properties: { osm_type?: string; osm_id?: number; name?: string; street?: string; housenumber?: string; district?: string; locality?: string; city?: string };
}

export async function searchPlaces(query: string, signal?: AbortSignal): Promise<PlaceResult[]> {
  const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=6&bbox=${AMMAN_BBOX}&${BIAS}`;
  const res = await fetch(url, { signal });
  if (!res.ok) throw new Error(`place search failed: ${res.status}`);
  const json = (await res.json()) as { features?: PhotonFeature[] };
  return (json.features ?? [])
    .map((f) => {
      const p = f.properties;
      const name = p.name ?? [p.street, p.housenumber].filter(Boolean).join(' ');
      return {
        id: `${p.osm_type ?? ''}${p.osm_id ?? name}`,
        name,
        context: [p.name ? p.street : undefined, p.district ?? p.locality, p.city].filter(Boolean).join('، '),
        position: { lat: f.geometry.coordinates[1], lng: f.geometry.coordinates[0] },
      };
    })
    .filter((r) => r.name);
}
