import type { SelectHTMLAttributes } from 'react';
import { GOVERNORATES } from '@/domain/governorates';
import { Select } from '@/shared/components/ui';

/** «المحافظة» selector. Values are governorate codes, never display names. */
export function GovernorateSelect({ placeholder = 'اختر المحافظة', ...rest }: SelectHTMLAttributes<HTMLSelectElement> & { placeholder?: string }) {
  return (
    <Select {...rest}>
      <option value="">{placeholder}</option>
      {GOVERNORATES.map((g) => (
        <option key={g.id} value={g.id}>
          {g.name}
        </option>
      ))}
    </Select>
  );
}
