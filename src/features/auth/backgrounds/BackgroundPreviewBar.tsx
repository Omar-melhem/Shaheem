import { SimTag } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';
import { BACKGROUND_VARIANTS, type BackgroundVariant } from './useBackgroundPreview';

const LABEL: Record<BackgroundVariant, string> = { original: 'الافتراضي', aurora: 'Aurora', silk: 'Silk', grid: 'Grid' };

/** Preview-only selector for comparing brand-panel backgrounds. Not part of the final design. */
export function BackgroundPreviewBar({ value, onChange }: { value: BackgroundVariant; onChange: (v: BackgroundVariant) => void }) {
  return (
    <div className="absolute inset-x-0 top-4 z-10 flex justify-center px-4">
      <div role="radiogroup" aria-label="معاينة خلفية لوحة الهوية" className="flex items-center gap-1 rounded-full bg-white/90 p-1 shadow-card ring-1 ring-cream-deep backdrop-blur">
        <SimTag className="mx-1">معاينة</SimTag>
        {BACKGROUND_VARIANTS.map((v) => (
          <button
            key={v}
            type="button"
            role="radio"
            aria-checked={value === v}
            onClick={() => onChange(v)}
            className={cn(
              'rounded-full px-3 py-1 text-xs font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300',
              value === v ? 'bg-secondary text-white' : 'text-ink-soft hover:bg-cream',
            )}
          >
            {LABEL[v]}
          </button>
        ))}
      </div>
    </div>
  );
}
