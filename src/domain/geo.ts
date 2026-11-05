import type { LatLng, ServiceArea } from './types';

const EARTH_RADIUS_M = 6_371_000;
const toRad = (deg: number) => (deg * Math.PI) / 180;

export function isValidLatLng(p: LatLng | undefined | null): p is LatLng {
  return (
    !!p &&
    Number.isFinite(p.lat) &&
    Number.isFinite(p.lng) &&
    Math.abs(p.lat) <= 90 &&
    Math.abs(p.lng) <= 180
  );
}

/** Straight-line (great-circle) distance. Road distance / ETA is open — SRS O-004. */
export function haversineMeters(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(h));
}

/**
 * Ray-casting point-in-polygon. Points exactly on a boundary may resolve either
 * way; the business rule for boundaries is open (SRS O-013). Production should
 * resolve this server-side (e.g. PostGIS).
 */
export function pointInPolygon(p: LatLng, polygon: LatLng[]): boolean {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[i];
    const b = polygon[j];
    const intersects =
      a.lat > p.lat !== b.lat > p.lat && p.lng < ((b.lng - a.lng) * (p.lat - a.lat)) / (b.lat - a.lat) + a.lng;
    if (intersects) inside = !inside;
  }
  return inside;
}

export function areasContaining(p: LatLng, areas: ServiceArea[]): ServiceArea[] {
  return areas.filter((a) => a.status === 'active' && a.polygon.length >= 3 && pointInPolygon(p, a.polygon));
}

const cross = (o: LatLng, a: LatLng, b: LatLng) => (a.lng - o.lng) * (b.lat - o.lat) - (a.lat - o.lat) * (b.lng - o.lng);
const segmentsCross = (a: LatLng, b: LatLng, c: LatLng, d: LatLng) =>
  cross(a, b, c) * cross(a, b, d) < 0 && cross(c, d, a) * cross(c, d, b) < 0;

/** Boundary geometry check: an error message, or null when valid (CR v1.3 §5.2). The ring is closed implicitly. */
export function polygonError(points: LatLng[]): string | null {
  if (!points.every(isValidLatLng)) return 'إحداثيات الحدود غير صالحة';
  const unique = new Set(points.map((p) => `${p.lat.toFixed(6)},${p.lng.toFixed(6)}`));
  if (unique.size < 3) return 'ارسم ثلاث نقاط مختلفة على الأقل';
  const n = points.length;
  for (let i = 0; i < n; i++) {
    for (let j = i + 2; j < n; j++) {
      if (i === 0 && j === n - 1) continue; // adjacent through the closing edge
      if (segmentsCross(points[i], points[(i + 1) % n], points[j], points[(j + 1) % n])) return 'الحدود متقاطعة مع نفسها — عدّل ترتيب النقاط';
    }
  }
  return null;
}

export function moveTowards(from: LatLng, to: LatLng, meters: number): LatLng {
  const total = haversineMeters(from, to);
  if (total <= meters || total === 0) return { ...to };
  const f = meters / total;
  return { lat: from.lat + (to.lat - from.lat) * f, lng: from.lng + (to.lng - from.lng) * f };
}

export function polygonCentroid(polygon: LatLng[]): LatLng {
  const n = polygon.length || 1;
  return {
    lat: polygon.reduce((s, p) => s + p.lat, 0) / n,
    lng: polygon.reduce((s, p) => s + p.lng, 0) / n,
  };
}

export function formatDistance(meters: number): string {
  if (meters < 1000) return `${Math.round(meters)} م`;
  return `${(meters / 1000).toFixed(1)} كم`;
}
