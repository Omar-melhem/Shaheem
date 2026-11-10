// Jordan's twelve governorates — the parent level for service areas (FU-1.2 §7).
// Which Governorate/Area catalogue is authoritative is still open (FU-1.2 §14.7);
// IDs are stable codes, labels are display only.

export const GOVERNORATES = [
  { id: 'amman', name: 'عمّان' },
  { id: 'irbid', name: 'إربد' },
  { id: 'zarqa', name: 'الزرقاء' },
  { id: 'balqa', name: 'البلقاء' },
  { id: 'madaba', name: 'مادبا' },
  { id: 'jerash', name: 'جرش' },
  { id: 'ajloun', name: 'عجلون' },
  { id: 'mafraq', name: 'المفرق' },
  { id: 'karak', name: 'الكرك' },
  { id: 'tafilah', name: 'الطفيلة' },
  { id: 'maan', name: 'معان' },
  { id: 'aqaba', name: 'العقبة' },
] as const;

export type GovernorateId = (typeof GOVERNORATES)[number]['id'];

export const isGovernorateId = (v: unknown): v is GovernorateId => GOVERNORATES.some((g) => g.id === v);

export const governorateName = (id: string | undefined): string => GOVERNORATES.find((g) => g.id === id)?.name ?? 'غير محددة';
