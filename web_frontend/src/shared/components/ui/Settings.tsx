import type { ReactNode } from 'react';
import { Lock } from 'lucide-react';
import { Card, CardHeader } from './Card';

/** A titled group of settings rows (Admin and Merchant settings pages). */
export function SettingsSection({
  title,
  description,
  icon,
  actions,
  children,
}: {
  title: ReactNode;
  description?: ReactNode;
  icon?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
}) {
  return (
    <Card>
      <CardHeader title={title} description={description} icon={icon} actions={actions} />
      <div className="divide-y divide-cream-dark">{children}</div>
    </Card>
  );
}

/**
 * One setting: label + description on the start side, value or control on the end.
 * `readOnly` marks values the current user cannot change, so they never look editable.
 */
export function SettingsRow({
  label,
  description,
  readOnly,
  children,
}: {
  label: ReactNode;
  description?: ReactNode;
  readOnly?: boolean;
  children?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-2 px-5 py-4 sm:flex-row sm:items-center sm:justify-between sm:gap-6">
      <div className="min-w-0">
        <p className="flex items-center gap-1.5 text-sm font-bold text-ink">
          {label}
          {readOnly && <Lock className="h-3.5 w-3.5 text-ink-muted" aria-label="للعرض فقط" />}
        </p>
        {description && <p className="mt-0.5 text-xs text-ink-muted">{description}</p>}
      </div>
      {children !== undefined && <div className="min-w-0 text-sm text-ink sm:text-end">{children}</div>}
    </div>
  );
}
