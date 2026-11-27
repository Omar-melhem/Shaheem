import type { SelectHTMLAttributes } from 'react';
import { MERCHANT_CATEGORIES, isMerchantCategory, type MerchantCategory, type StoredMerchantCategory } from '@/domain/types';
import { Select } from '@/shared/components/ui';
import { CATEGORY_LABEL } from './categories';

/**
 * Business category picker: exactly the four categories, in order. A legacy or empty value shows the
 * placeholder, so Admin must choose one of the four before saving; the old value is never an option.
 */
export function BusinessCategorySelect({
  value,
  onChange,
  ...rest
}: {
  value: StoredMerchantCategory;
  onChange: (value: MerchantCategory | null) => void;
} & Omit<SelectHTMLAttributes<HTMLSelectElement>, 'value' | 'onChange'>) {
  return (
    <Select value={isMerchantCategory(value) ? value : ''} onChange={(e) => onChange(isMerchantCategory(e.target.value) ? e.target.value : null)} {...rest}>
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
