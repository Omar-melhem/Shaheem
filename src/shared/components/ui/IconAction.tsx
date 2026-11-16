import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { cn } from '@/shared/lib/cn';

const TONES = {
  neutral: 'text-ink-soft hover:bg-cream-dark hover:text-ink',
  primary: 'text-primary hover:bg-primary-50',
  secondary: 'text-secondary hover:bg-secondary-50',
  danger: 'text-red-700 hover:bg-red-50',
} as const;

/**
 * Icon-only table action (Master Prompt §13): accessible name from `label`, a tooltip (display:none until shown, anchored inward so it never widens the table) on
 * hover AND keyboard focus, a 36px hit target with an 18px glyph, and a visible focus ring. `to` renders a link.
 * A disabled action stays focusable (`aria-disabled`) so its tooltip can say why it is unavailable (`disabledReason`).
 */
export function IconAction({
  icon,
  label,
  onClick,
  to,
  tone = 'neutral',
  disabled,
  disabledReason,
}: {
  icon: ReactNode;
  label: string;
  onClick?: () => void;
  to?: string;
  tone?: keyof typeof TONES;
  disabled?: boolean;
  /** Shown in the tooltip and read by screen readers while `disabled`. */
  disabledReason?: string;
}) {
  const className = cn(
    'peer relative inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 active:bg-cream-deep [&>svg]:h-[18px] [&>svg]:w-[18px] [&>svg]:shrink-0',
    disabled ? 'cursor-not-allowed text-ink-muted opacity-40' : TONES[tone],
  );
  const tip = disabled && disabledReason ? `${label} — ${disabledReason}` : label;
  return (
    <span className="relative inline-flex">
      {to && !disabled ? (
        <Link to={to} aria-label={label} className={className}>{icon}</Link>
      ) : (
        <button
          type="button"
          aria-label={tip}
          aria-disabled={disabled || undefined}
          onClick={disabled ? undefined : onClick}
          className={className}
        >
          {icon}
        </button>
      )}
      <span
        role="tooltip"
        className="pointer-events-none absolute bottom-full end-0 z-40 mb-1.5 hidden whitespace-nowrap rounded-lg bg-ink px-2 py-1 text-[11px] font-medium text-white shadow-pop peer-hover:block peer-focus-visible:block"
        aria-hidden
      >
        {tip}
      </span>
    </span>
  );
}
