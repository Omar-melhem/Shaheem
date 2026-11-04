import { useEffect, type ReactNode } from 'react';
import { MapContainer, TileLayer, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import type { LatLng } from '@/domain/types';
import { cn } from '@/shared/lib/cn';

export const AMMAN_CENTER: LatLng = { lat: 31.985, lng: 35.87 };

/** Shared map shell: Leaflet + OpenStreetMap tiles (demo map choice — provider open, O-018). */
export function BaseMap({
  center = AMMAN_CENTER,
  zoom = 13,
  className,
  children,
  label = 'خريطة',
}: {
  center?: LatLng;
  zoom?: number;
  className?: string;
  children?: ReactNode;
  label?: string;
}) {
  // `isolate` keeps Leaflet's internal z-indexes (controls use 800–1000) below drawers and dialogs.
  return (
    <div className={cn('relative isolate overflow-hidden rounded-2xl border border-cream-deep', className)} role="region" aria-label={label}>
      <MapContainer center={[center.lat, center.lng]} zoom={zoom} scrollWheelZoom className="h-full w-full" attributionControl>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {children}
      </MapContainer>
    </div>
  );
}

/** Fits the viewport to the given points whenever the key changes. */
export function FitBounds({ points, fitKey, maxZoom = 15 }: { points: LatLng[]; fitKey: string; maxZoom?: number }) {
  const map = useMap();
  useEffect(() => {
    if (points.length === 0) return;
    if (points.length === 1) {
      map.setView([points[0].lat, points[0].lng], maxZoom);
      return;
    }
    map.fitBounds(L.latLngBounds(points.map((p) => [p.lat, p.lng] as [number, number])), { padding: [40, 40], maxZoom });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fitKey, map]);
  return null;
}

export function MapClickHandler({ onClick }: { onClick: (p: LatLng) => void }) {
  useMapEvents({ click: (e) => onClick({ lat: e.latlng.lat, lng: e.latlng.lng }) });
  return null;
}

/** Re-measures the map after its container changes size (drawers, tabs). */
export function InvalidateSize({ trigger }: { trigger?: unknown }) {
  const map = useMap();
  useEffect(() => {
    const t = setTimeout(() => map.invalidateSize(), 120);
    return () => clearTimeout(t);
  }, [map, trigger]);
  return null;
}
