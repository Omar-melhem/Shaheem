// Small builders for unit tests: complete objects with sensible defaults, overridable per test.
import type { Captain, ServiceArea } from '@/domain/types';

export const T0 = Date.UTC(2026, 10, 9, 9, 0); // 2026-11-09 12:00 Amman

export function makeCaptain(over: Partial<Captain> = {}): Captain {
  return {
    id: 'c-test',
    fullName: 'كابتن تجريبي',
    phone: '0790000000',
    username: 'cap',
    password: 'secret',
    status: 'active',
    availability: 'available',
    lastLocation: { position: { lat: 31.95, lng: 35.9 }, recordedAt: T0, source: 'demo_idle' },
    gpsSignal: 'ok',
    createdAt: T0,
    ...over,
  };
}

export function makeArea(over: Partial<ServiceArea> = {}): ServiceArea {
  return {
    id: 'a-test',
    governorateId: 'amman',
    cityId: 'amman',
    parentId: null,
    name: 'خلدا',
    aliases: [],
    polygon: [],
    status: 'active',
    createdAt: T0,
    updatedAt: T0,
    ...over,
  };
}

/** A 0.02° square around (31.95, 35.90). */
export const SQUARE = [
  { lat: 31.94, lng: 35.89 },
  { lat: 31.94, lng: 35.91 },
  { lat: 31.96, lng: 35.91 },
  { lat: 31.96, lng: 35.89 },
];
