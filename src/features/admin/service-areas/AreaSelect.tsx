import type { SelectHTMLAttributes } from 'react';
import type { ServiceArea } from '@/domain/types';
import { Select } from '@/shared/components/ui';

/** Areas of one Governorate only; `excludeId` removes the area already chosen as origin. */
export function AreaSelect({
  areas,
  governorateId,
  excludeId,
  placeholder,
  ...rest
}: SelectHTMLAttributes<HTMLSelectElement> & { areas: ServiceArea[]; governorateId: string; excludeId?: string; placeholder: string }) {
  const options = areas.filter((a) => a.governorateId === governorateId && a.id !== excludeId).sort((a, b) => a.name.localeCompare(b.name, 'ar'));
  return (
    <Select {...rest} disabled={rest.disabled || !governorateId || options.length === 0}>
      <option value="">{!governorateId ? 'اختر المحافظة أولاً' : options.length === 0 ? 'لا توجد مناطق متاحة' : placeholder}</option>
      {options.map((a) => (
        <option key={a.id} value={a.id}>
          {a.name}
          {a.status !== 'active' ? ' (متوقفة)' : ''}
        </option>
      ))}
    </Select>
  );
}
