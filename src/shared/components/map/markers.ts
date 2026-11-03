import L from 'leaflet';
import type { LocationFreshness } from '@/domain/location';
import type { CaptainView } from '@/application/hooks';

// Custom map markers (SRS §4.6): Captain = person in a delivery helmet,
// Merchant = storefront. Shape (circle vs square) and colour both differ.

export const CAPTAIN_STATUS_COLOR: Record<CaptainView['opStatus'], string> = {
  available: '#263D34',
  busy: '#8C2335',
  offline: '#8A8580',
  inactive: '#B5B0A8',
};
export const STALE_COLOR = '#B45309';

const helmetPerson = (stripe: string) => `
<svg viewBox="0 0 32 32" width="26" height="26" aria-hidden="true">
  <path d="M6 30c0-6 4.5-9.2 10-9.2S26 24 26 30z" fill="#fff"/>
  <circle cx="16" cy="14" r="5.4" fill="#F3D9BF"/>
  <path d="M8.4 14a7.6 7.6 0 0 1 15.2 0v1.2H8.4z" fill="#fff"/>
  <path d="M16 6.5v6.4" stroke="${stripe}" stroke-width="1.8" stroke-linecap="round"/>
  <rect x="9.6" y="13.4" width="12.8" height="3.1" rx="1.5" fill="#242424" opacity=".88"/>
</svg>`;

export function captainIcon(opStatus: CaptainView['opStatus'], freshness: LocationFreshness, selected = false) {
  const stale = freshness === 'stale';
  const color = stale ? STALE_COLOR : CAPTAIN_STATUS_COLOR[opStatus];
  const notTracked = freshness === 'demo' || freshness === 'last_known';
  const ring = stale
    ? `outline:3px dashed ${STALE_COLOR};outline-offset:2px;`
    : notTracked
      ? 'outline:2px dashed rgba(36,36,36,.35);outline-offset:2px;'
      : freshness === 'live'
        ? 'box-shadow:0 0 0 4px rgba(38,61,52,.25),0 2px 6px rgba(0,0,0,.3);'
        : '';
  const size = selected ? 44 : 38;
  return L.divIcon({
    className: 'shahm-marker',
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
    popupAnchor: [0, -size / 2],
    html: `<div style="width:${size}px;height:${size}px;border-radius:9999px;background:${color};display:flex;align-items:center;justify-content:center;border:2px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,.3);${ring}${notTracked ? 'opacity:.85;' : ''}">${helmetPerson(color)}</div>`,
  });
}

const storeSvg = `
<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#F5F0E8" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
  <path d="m2 7 4.4-4.4A2 2 0 0 1 7.8 2h8.4a2 2 0 0 1 1.4.6L22 7"/>
  <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/>
  <path d="M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4"/>
  <path d="M2 7h20v3a2 2 0 0 1-2 2 2.7 2.7 0 0 1-2-1 2.7 2.7 0 0 1-4 0 2.7 2.7 0 0 1-4 0 2.7 2.7 0 0 1-4 0 2 2 0 0 1-4-1z"/>
</svg>`;

export function merchantIcon(inactive = false) {
  return L.divIcon({
    className: 'shahm-marker',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18],
    html: `<div style="width:36px;height:36px;border-radius:10px;background:${inactive ? '#8A8580' : '#242424'};display:flex;align-items:center;justify-content:center;border:2px solid #C8A98A;box-shadow:0 2px 6px rgba(0,0,0,.3);">${storeSvg}</div>`,
  });
}

export function destinationIcon() {
  return L.divIcon({
    className: 'shahm-marker',
    iconSize: [30, 40],
    iconAnchor: [15, 38],
    popupAnchor: [0, -36],
    html: `<svg viewBox="0 0 30 40" width="30" height="40" aria-hidden="true"><path d="M15 39s13-13.2 13-23A13 13 0 0 0 2 16c0 9.8 13 23 13 23z" fill="#8C2335" stroke="#fff" stroke-width="2"/><circle cx="15" cy="16" r="5" fill="#F5F0E8"/></svg>`,
  });
}

export function vertexIcon() {
  return L.divIcon({
    className: 'shahm-marker',
    iconSize: [14, 14],
    iconAnchor: [7, 7],
    html: `<div style="width:14px;height:14px;border-radius:9999px;background:#fff;border:3px solid #8C2335"></div>`,
  });
}
