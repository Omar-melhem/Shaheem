import type { SelectHTMLAttributes } from 'react';
import { CITIES, citiesOf } from '@/domain/cities';
import { Select } from '@/shared/components/ui';

/** «المدينة» selector, optionally limited to one Governorate. Values are city codes, never names. */
export function CitySelect({ governorateId, ...rest }: SelectHTMLAttributes<HTMLSelectElement> & { governorateId?: string }) {
  const options = governorateId === undefined ? CITIES : citiesOf(governorateId);
  return (
    <Select {...rest} disabled={rest.disabled || options.length === 0}>
      <option value="">{options.length === 0 ? 'اختر المحافظة أولاً' : 'اختر المدينة'}</option>
      {options.map((c) => (
        <option key={c.id} value={c.id}>
          {c.name}
        </option>
      ))}
    </Select>
  );
}
