import { useSearchParams } from 'react-router-dom';

export const BACKGROUND_VARIANTS = ['original', 'aurora', 'silk', 'grid'] as const;
export type BackgroundVariant = (typeof BACKGROUND_VARIANTS)[number];

const isVariant = (v: string | null): v is BackgroundVariant => BACKGROUND_VARIANTS.includes(v as BackgroundVariant);

/**
 * Preview-only switch for the login brand background, read from `?bg=`.
 * Default is always 'original' — nothing changes for normal visitors until the
 * Product Owner picks a variant. The selector shows in dev or when `?bg` is present.
 */
export function useBackgroundPreview() {
  const [params, setParams] = useSearchParams();
  const raw = params.get('bg');
  const variant: BackgroundVariant = isVariant(raw) ? raw : 'original';
  const showSelector = import.meta.env.DEV || raw !== null;
  const setVariant = (v: BackgroundVariant) => setParams({ bg: v }, { replace: true });
  return { variant, setVariant, showSelector };
}
