import type { MerchantCategory } from '@/domain/types';
import { Badge } from '@/shared/components/ui';
import { categoryLabel } from './categories';

/** Business category tag; legacy records without a category read «غير مصنّف». */
export function MerchantCategoryBadge({ category }: { category: MerchantCategory | null }) {
  return <Badge tone={category ? 'sand' : 'warning'}>{categoryLabel(category)}</Badge>;
}
