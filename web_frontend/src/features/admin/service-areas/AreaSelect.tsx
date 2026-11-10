import type { SelectHTMLAttributes } from 'react';
import type { ServiceArea } from '@/domain/types';
import { Select } from '@/shared/components/ui';

/** Areas of one parent only (a Governorate or a City); `excludeId` removes the area already chosen as origin. */
export function AreaSelect({
  areas,
  scope,
  excludeId,
  placeholder,
  ...rest
}: SelectHTMLAttributes<HTMLSelectElement> & { areas: ServiceArea[]; scope: { by: 'governorate' | 'city'; id: string }; excludeId?: string; placeholder: string }) {
  const inScope = (a: ServiceArea) => (scope.by === 'city' ? a.cityId : a.governorateId) === scope.id;
  const options = areas.filter((a) => inScope(a) && a.id !== excludeId).sort((a, b) => a.name.localeCompare(b.name, 'ar'));
  const emptyLabel = !scope.id ? (scope.by === 'city' ? 'اختر المدينة أولاً' : 'اختر المحافظة أولاً') : options.length === 0 ? 'لا توجد مناطق متاحة' : placeholder;
  return (
    <Select {...rest} disabled={rest.disabled || !scope.id || options.length === 0}>
      <option value="">{emptyLabel}</option>
      {options.map((a) => (
        <option key={a.id} value={a.id}>
          {a.name}
          {a.status !== 'active' ? ' (متوقفة)' : ''}
        </option>
      ))}
    </Select>
  );
}
