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

/** A slow public service must not leave the search spinning forever. */
const SEARCH_TIMEOUT_MS = 8000;

/** Fetch that gives up after `SEARCH_TIMEOUT_MS`; a caller abort still reads as an AbortError. */
async function fetchWithTimeout(url: string, signal?: AbortSignal): Promise<Response> {
  const controller = new AbortController();
  let timedOut = false;
  const timer = setTimeout(() => { timedOut = true; controller.abort(); }, SEARCH_TIMEOUT_MS);
  const forward = () => controller.abort();
  if (signal?.aborted) controller.abort();
  signal?.addEventListener('abort', forward);
  try {
    return await fetch(url, { signal: controller.signal });
  } catch (err) {
    if (timedOut) throw new Error('place search timed out');
    throw err;
  } finally {
    clearTimeout(timer);
    signal?.removeEventListener('abort', forward);
  }
}

const isCoordinatePair = (c: unknown): c is [number, number] =>
  Array.isArray(c) && c.length >= 2 && Number.isFinite(c[0]) && Number.isFinite(c[1]) && Math.abs(c[1]) <= 90 && Math.abs(c[0]) <= 180;

export async function searchPlaces(query: string, signal?: AbortSignal): Promise<PlaceResult[]> {
  const url = `https://photon.komoot.io/api/?q=${encodeURIComponent(query)}&limit=6&bbox=${AMMAN_BBOX}&${BIAS}`;
  const res = await fetchWithTimeout(url, signal);
  if (!res.ok) throw new Error(`place search failed: ${res.status}`);
  const json = (await res.json()) as { features?: PhotonFeature[] };
  return (Array.isArray(json.features) ? json.features : [])
    .filter((f) => isCoordinatePair(f?.geometry?.coordinates) && !!f.properties)
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
