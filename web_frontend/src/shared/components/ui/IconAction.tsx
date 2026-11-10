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
 * hover AND keyboard focus, a 32px hit target, and a visible focus ring. `to` renders a link.
 */
export function IconAction({
  icon,
  label,
  onClick,
  to,
  tone = 'neutral',
  disabled,
}: {
  icon: ReactNode;
  label: string;
  onClick?: () => void;
  to?: string;
  tone?: keyof typeof TONES;
  disabled?: boolean;
}) {
  const className = cn(
    'peer inline-flex h-8 w-8 items-center justify-center rounded-lg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 disabled:cursor-not-allowed disabled:opacity-40 [&>svg]:h-4 [&>svg]:w-4',
    TONES[tone],
  );
  return (
    <span className="relative inline-flex">
      {to && !disabled ? (
        <Link to={to} aria-label={label} className={className}>{icon}</Link>
      ) : (
        <button type="button" aria-label={label} onClick={onClick} disabled={disabled} className={className}>{icon}</button>
      )}
      <span
        role="tooltip"
        className="pointer-events-none absolute bottom-full end-0 z-40 mb-1.5 hidden whitespace-nowrap rounded-lg bg-ink px-2 py-1 text-[11px] font-medium text-white shadow-pop peer-hover:block peer-focus-visible:block"
        aria-hidden
      >
        {label}
      </span>
    </span>
  );
}
