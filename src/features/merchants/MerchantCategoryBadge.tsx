import type { StoredMerchantCategory } from '@/domain/types';
import { Badge } from '@/shared/components/ui';
import { categoryLabel, needsCategoryReview } from './categories';

/** Business category tag; uncategorised and legacy-category records are flagged for review. */
export function MerchantCategoryBadge({ category }: { category: StoredMerchantCategory }) {
  return <Badge tone={needsCategoryReview(category) ? 'warning' : 'sand'}>{categoryLabel(category)}</Badge>;
}
