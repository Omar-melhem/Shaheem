import { Headphones, Mail, MessageCircle, Phone, Link2 } from 'lucide-react';
import { useAppStore } from '@/app/state';
import type { SupportChannel, SupportContact } from '@/domain/types';
import { EmptyState } from '@/shared/components/ui';

export const CHANNEL_LABEL: Record<SupportChannel, string> = {
  phone: 'اتصال هاتفي',
  whatsapp: 'واتساب',
  email: 'بريد إلكتروني',
  other: 'قناة أخرى',
};

const CHANNEL_ICON = { phone: Phone, whatsapp: MessageCircle, email: Mail, other: Link2 };

export function contactHref(c: SupportContact): string | undefined {
  const digits = c.value.replace(/[^\d+]/g, '');
  switch (c.channel) {
    case 'phone':
      return `tel:${digits}`;
    case 'whatsapp':
      return `https://wa.me/${digits.replace(/^\+/, '')}`;
    case 'email':
      return `mailto:${c.value}`;
    default:
      return /^https?:\/\//.test(c.value) ? c.value : undefined;
  }
}

/** Official SHAHM contact info, configured centrally by Admin (SRS §12). */
export function SupportContactList({ compact }: { compact?: boolean }) {
  const contacts = useAppStore((s) => s.supportContacts);
  const visible = [...contacts].filter((c) => c.enabled).sort((a, b) => a.order - b.order);

  if (visible.length === 0) {
    return (
      <EmptyState
        icon={<Headphones className="h-6 w-6" />}
        title="بيانات التواصل الرسمية قيد الإضافة"
        description="ستظهر هنا قنوات تواصل شهم الرسمية بعد اعتمادها وإضافتها من لوحة الإدارة."
      />
    );
  }

  return (
    <ul className={compact ? 'space-y-2' : 'space-y-3'}>
      {visible.map((c) => {
        const Icon = CHANNEL_ICON[c.channel];
        const href = contactHref(c);
        const content = (
          <>
            <span className="rounded-xl bg-primary-50 p-2.5 text-primary">
              <Icon className="h-5 w-5" aria-hidden />
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-sm font-bold text-ink">{c.label}</span>
              <span className="block truncate text-sm text-ink-muted" dir="ltr" style={{ textAlign: 'right' }}>
                {c.value}
              </span>
            </span>
            <span className="text-xs text-ink-muted">{CHANNEL_LABEL[c.channel]}</span>
          </>
        );
        return (
          <li key={c.id}>
            {href ? (
              <a
                href={href}
                target={href.startsWith('http') ? '_blank' : undefined}
                rel="noopener noreferrer"
                className="flex items-center gap-3 rounded-xl border border-cream-deep bg-white p-3 hover:bg-cream"
              >
                {content}
              </a>
            ) : (
              <div className="flex items-center gap-3 rounded-xl border border-cream-deep bg-white p-3">{content}</div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
