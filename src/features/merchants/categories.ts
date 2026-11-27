import { isLegacyMerchantCategory, type LegacyMerchantCategory, type MerchantCategory, type StoredMerchantCategory } from '@/domain/types';

/** Arabic labels for the four selectable business categories (owner, 2026-11-27). */
export const CATEGORY_LABEL: Record<MerchantCategory, string> = {
  restaurant: 'مطاعم',
  sweets_shop: 'محل حلويات',
  online_company: 'شركات أون لاين',
  online_page: 'صفحات أون لاين',
};

/** Labels kept only to show what an older record still holds; never offered for selection. */
const LEGACY_CATEGORY_LABEL: Record<LegacyMerchantCategory, string> = {
  cafe: 'مقهى',
  retail: 'متجر / محل تجاري',
  grocery: 'بقالة / سوبر ماركت',
  pharmacy: 'صيدلية',
  bakery: 'مخبز',
  other: 'أخرى',
};

export const UNCATEGORIZED_LABEL = 'غير مصنّف';
export const LEGACY_CATEGORY_NOTE = 'فئة سابقة — اختر إحدى الفئات الأربع عند الحفظ';

export const categoryLabel = (c: StoredMerchantCategory) =>
  c === null ? UNCATEGORIZED_LABEL : isLegacyMerchantCategory(c) ? `${LEGACY_CATEGORY_LABEL[c]} (فئة سابقة)` : CATEGORY_LABEL[c];

/** The record needs Admin to choose one of the four categories (legacy code or none). */
export const needsCategoryReview = (c: StoredMerchantCategory) => c === null || isLegacyMerchantCategory(c);
