import type { SelectHTMLAttributes } from 'react';
import { MERCHANT_CATEGORIES, isMerchantCategory, type MerchantCategory } from '@/domain/types';
import { Select } from '@/shared/components/ui';
import { CATEGORY_LABEL } from './categories';

/** Business category picker. An empty value means «not chosen yet» and must be resolved before saving. */
export function BusinessCategorySelect({
  value,
  onChange,
  ...rest
}: {
  value: MerchantCategory | null;
  onChange: (value: MerchantCategory | null) => void;
} & Omit<SelectHTMLAttributes<HTMLSelectElement>, 'value' | 'onChange'>) {
  return (
    <Select value={value ?? ''} onChange={(e) => onChange(isMerchantCategory(e.target.value) ? e.target.value : null)} {...rest}>
      <option value="" disabled>
        اختر فئة النشاط
      </option>
      {MERCHANT_CATEGORIES.map((c) => (
        <option key={c} value={c}>
          {CATEGORY_LABEL[c]}
        </option>
      ))}
    </Select>
  );
}
