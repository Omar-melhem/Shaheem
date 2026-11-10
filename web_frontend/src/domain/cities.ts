// City layer between Governorate and Area (CR v1.3 §3.1): a City is not a Governorate,
// so it has its own reference data and IDs. Proposed starter catalogue — each governorate's
// main city only. The authoritative City/Area catalogue is an open owner decision (FU §14.7).

export const CITIES = [
  { id: 'amman', governorateId: 'amman', name: 'عمّان' },
  { id: 'irbid', governorateId: 'irbid', name: 'إربد' },
  { id: 'zarqa', governorateId: 'zarqa', name: 'الزرقاء' },
  { id: 'salt', governorateId: 'balqa', name: 'السلط' },
  { id: 'madaba', governorateId: 'madaba', name: 'مادبا' },
  { id: 'jerash', governorateId: 'jerash', name: 'جرش' },
  { id: 'ajloun', governorateId: 'ajloun', name: 'عجلون' },
  { id: 'mafraq', governorateId: 'mafraq', name: 'المفرق' },
  { id: 'karak', governorateId: 'karak', name: 'الكرك' },
  { id: 'tafilah', governorateId: 'tafilah', name: 'الطفيلة' },
  { id: 'maan', governorateId: 'maan', name: 'معان' },
  { id: 'aqaba', governorateId: 'aqaba', name: 'العقبة' },
] as const;

export const citiesOf = (governorateId: string) => CITIES.filter((c) => c.governorateId === governorateId);

export const findCity = (id: string | null | undefined) => CITIES.find((c) => c.id === id);

export const cityName = (id: string | null | undefined): string => findCity(id)?.name ?? 'غير محددة';

/** True when the city exists and belongs to the governorate. */
export const isCityInGovernorate = (cityId: string, governorateId: string): boolean => findCity(cityId)?.governorateId === governorateId;
