import type { MerchantCategory } from '@/domain/types';

/** Arabic labels for the business-category codes. The account role «تاجر» is not a category. */
export const CATEGORY_LABEL: Record<MerchantCategory, string> = {
  restaurant: 'مطعم',
  cafe: 'مقهى',
  retail: 'متجر / محل تجاري',
  grocery: 'بقالة / سوبر ماركت',
  pharmacy: 'صيدلية',
  bakery: 'مخبز',
  other: 'أخرى',
};

export const UNCATEGORIZED_LABEL = 'غير مصنّف';

export const categoryLabel = (c: MerchantCategory | null) => (c ? CATEGORY_LABEL[c] : UNCATEGORIZED_LABEL);
