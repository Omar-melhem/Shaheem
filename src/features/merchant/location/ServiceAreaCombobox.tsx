import { useId, useMemo, useState, type KeyboardEvent } from 'react';
import { Search, Shapes } from 'lucide-react';
import type { MerchantZoneOption } from '@/application/queries';
import { cityName } from '@/domain/cities';
import type { ID } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { Input, fieldMessageId } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';

/**
 * Required delivery area picker: filters the Merchant's priced areas and yields a stable
 * area ID. Typing clears the selection, so a typed name alone is never a valid choice.
 */
export function ServiceAreaCombobox({
  id,
  options,
  selectedId,
  invalid,
  onSelect,
}: {
  id: string;
  options: MerchantZoneOption[];
  selectedId: ID | null;
  invalid?: boolean;
  onSelect: (areaId: ID | null) => void;
}) {
  const [query, setQuery] = useState(() => options.find((o) => o.area.id === selectedId)?.label ?? '');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const listId = useId();

  const matches = useMemo(() => {
    const needle = query.trim().toLowerCase();
    // The chosen name should not narrow the list when the Merchant reopens it to change area.
    if (!needle || selectedId) return options;
    return options.filter((o) => [o.label, ...o.area.aliases].some((name) => name.toLowerCase().includes(needle)));
  }, [options, query, selectedId]);

  const choose = (option: MerchantZoneOption) => {
    setOpen(false);
    setQuery(option.label);
    onSelect(option.area.id);
  };

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Escape') return setOpen(false);
    if (e.key === 'ArrowDown' && !open) return setOpen(true);
    if (!open || matches.length === 0) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((i) => (i + 1) % matches.length); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((i) => (i - 1 + matches.length) % matches.length); }
    else if (e.key === 'Enter') { e.preventDefault(); if (matches[active]) choose(matches[active]); }
  };

  return (
    <div className="relative">
      <Search className="pointer-events-none absolute start-3 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-muted" aria-hidden />
      <Input
        id={id}
        role="combobox"
        aria-expanded={open}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={open && matches[active] ? `${listId}-${active}` : undefined}
        aria-invalid={invalid}
        aria-required
        aria-describedby={fieldMessageId(id)}
        className="h-12 ps-10 text-base"
        placeholder="ابحث عن منطقة التوصيل واخترها من القائمة"
        value={query}
        onChange={(e) => {
          setQuery(e.target.value);
          setOpen(true);
          setActive(0);
          if (selectedId) onSelect(null);
        }}
        onFocus={() => setOpen(true)}
        onClick={() => setOpen(true)}
        onBlur={() => setOpen(false)}
        onKeyDown={onKeyDown}
        autoComplete="off"
      />
      {open && (
        <ul id={listId} role="listbox" onMouseDown={(e) => e.preventDefault()} className="absolute inset-x-0 top-full z-[1100] mt-1 max-h-72 overflow-y-auto rounded-xl border border-cream-deep bg-white py-1 shadow-pop">
          {matches.map((o, i) => (
            <li
              key={o.area.id}
              id={`${listId}-${i}`}
              role="option"
              aria-selected={o.area.id === selectedId}
              onClick={() => choose(o)}
              onMouseEnter={() => setActive(i)}
              className={cn('flex cursor-pointer items-start gap-3 px-4 py-2.5', i === active && 'bg-cream')}
            >
              <Shapes className="mt-0.5 h-4 w-4 shrink-0 text-primary" aria-hidden />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-sm font-bold text-ink">{o.label}</span>
                <span className="block truncate text-xs text-ink-muted">{cityName(o.area.cityId)}</span>
              </span>
              <span className="shrink-0 text-xs font-bold text-primary">{formatMoney(o.price)}</span>
            </li>
          ))}
          {matches.length === 0 && <li className="px-4 py-3 text-sm text-ink-muted">لا توجد منطقة توصيل مطابقة في حسابك.</li>}
        </ul>
      )}
    </div>
  );
}
