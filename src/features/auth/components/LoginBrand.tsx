import { cn } from '@/shared/lib/cn';

/** Login marketing copy (owner wording, kept exactly as supplied — do not "correct" the spelling). */
export const LOGIN_TITLE = 'شهم درايف';
export const LOGIN_SLOGAN = 'نوصلها بشهامه ونحفظها بأمانه';

/** The supplied SHAHM delivery-car photo (677 × 337), served locally and never altered. */
export const LOGIN_CAR_SRC = '/brand/shahm-login-car.jpg';
const CAR_WIDTH = 677;
const CAR_HEIGHT = 337;

/**
 * The branded car in a soft white frame, so the photo's own light background reads as a
 * deliberate print rather than a block on the cream panel. Never wider than its native width
 * (no upscaling blur); `object-contain` keeps the wheels, both ends and the door logo visible.
 */
export function LoginCar({ className, priority, compact }: { className?: string; priority?: boolean; compact?: boolean }) {
  return (
    <figure
      className={cn(
        'bg-white shadow-card ring-1 ring-cream-deep/70',
        compact ? 'w-[40%] max-w-[170px] shrink-0 rounded-2xl p-1' : 'w-full max-w-[677px] rounded-3xl p-2',
        className,
      )}
    >
      <img
        src={LOGIN_CAR_SRC}
        width={CAR_WIDTH}
        height={CAR_HEIGHT}
        alt="سيارة شهم للتوصيل"
        className={cn('block h-auto w-full object-contain', compact ? 'rounded-xl' : 'rounded-2xl')}
        decoding="async"
        fetchPriority={priority ? 'high' : undefined}
        draggable={false}
      />
    </figure>
  );
}
