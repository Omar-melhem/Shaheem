import { useId, useState, type KeyboardEvent } from 'react';
import { Loader2, MapPin, Search } from 'lucide-react';
import type { PlaceResult } from '@/infrastructure/placeSearch';
import { Input } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';
import { usePlaceSearch } from './usePlaceSearch';

/** Delivery-app style place search (combobox): type, pick a result, the map pin follows. */
export function LocationSearchField({ onSelect, invalid }: { onSelect: (place: PlaceResult) => void; invalid?: boolean }) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const listId = useId();
  const search = usePlaceSearch(query, open);
  const results = search.status === 'done' ? search.results : [];

  const choose = (place: PlaceResult) => {
    setQuery(place.name);
    setOpen(false);
    onSelect(place);
  };

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (!open || results.length === 0) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((i) => (i + 1) % results.length); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((i) => (i - 1 + results.length) % results.length); }
    else if (e.key === 'Enter') { e.preventDefault(); choose(results[active]); }
    else if (e.key === 'Escape') setOpen(false);
  };

  return (
    <div className="relative">
      <Search className="pointer-events-none absolute start-3 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-muted" aria-hidden />
      <Input
        role="combobox"
        aria-label="ابحث عن موقع العميل"
        aria-expanded={open && results.length > 0}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={open && results[active] ? `${listId}-${active}` : undefined}
        aria-invalid={invalid}
        className="h-12 ps-10 text-base"
        placeholder="ابحث عن مكان العميل: شارع، مجمّع، معلم…"
        value={query}
        onChange={(e) => { setQuery(e.target.value); setOpen(true); setActive(0); }}
        onFocus={() => query.trim().length >= 2 && setOpen(true)}
        onBlur={() => window.setTimeout(() => setOpen(false), 150)}
        onKeyDown={onKeyDown}
        autoComplete="off"
      />
      {search.status === 'loading' && <Loader2 className="absolute end-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-ink-muted" aria-label="جارٍ البحث" />}
      {open && query.trim().length >= 2 && search.status !== 'idle' && search.status !== 'loading' && (
        <ul id={listId} role="listbox" className="absolute inset-x-0 top-full z-[1100] mt-1 max-h-72 overflow-y-auto rounded-xl border border-cream-deep bg-white py-1 shadow-pop">
          {search.status === 'error' && <li className="px-4 py-3 text-sm text-red-700">تعذّر البحث الآن — حدّد الموقع بالضغط على الخريطة.</li>}
          {search.status === 'done' && results.length === 0 && <li className="px-4 py-3 text-sm text-ink-muted">لا نتائج — جرّب اسماً آخر أو حدّد الموقع على الخريطة.</li>}
          {results.map((r, i) => (
            <li
              key={r.id + i}
              id={`${listId}-${i}`}
              role="option"
              aria-selected={i === active}
              onMouseDown={(e) => { e.preventDefault(); choose(r); }}
              onMouseEnter={() => setActive(i)}
              className={cn('flex cursor-pointer items-start gap-3 px-4 py-2.5', i === active && 'bg-cream')}
            >
              <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-primary" aria-hidden />
              <span className="min-w-0">
                <span className="block truncate text-sm font-bold text-ink">{r.name}</span>
                {r.context && <span className="block truncate text-xs text-ink-muted">{r.context}</span>}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
