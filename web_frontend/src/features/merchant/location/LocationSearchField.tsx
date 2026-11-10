import { useId, useMemo, useState, type KeyboardEvent } from 'react';
import { Loader2, MapPin, Search, Shapes } from 'lucide-react';
import type { ServiceArea } from '@/domain/types';
import { cityName } from '@/domain/cities';
import type { PlaceResult } from '@/infrastructure/placeSearch';
import { Input } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';
import { usePlaceSearch } from './usePlaceSearch';

type Option = { kind: 'area'; area: ServiceArea } | { kind: 'place'; place: PlaceResult };

/**
 * Searchable destination list (combobox): configured areas filter locally and real places
 * come from the search provider. A place sets the pin; an area only moves the map, because
 * a neighbourhood is too imprecise for a Captain (CR v1.3 §8.1).
 */
export function LocationSearchField({
  onSelect,
  onSelectArea,
  areas = [],
  invalid,
  placeholder = 'ابحث عن موقع: شارع، مجمّع، معلم…',
  label = 'ابحث عن الموقع',
}: {
  onSelect: (place: PlaceResult) => void;
  onSelectArea?: (area: ServiceArea) => void;
  areas?: ServiceArea[];
  invalid?: boolean;
  placeholder?: string;
  label?: string;
}) {
  const [query, setQuery] = useState('');
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const listId = useId();
  const search = usePlaceSearch(query, open);
  const needle = query.trim().toLowerCase();

  const options = useMemo<Option[]>(() => {
    const matchedAreas = areas.filter((a) => !needle || [a.name, ...a.aliases].some((n) => n.toLowerCase().includes(needle)));
    const places = search.status === 'done' ? search.results : [];
    return [...matchedAreas.map((area) => ({ kind: 'area' as const, area })), ...places.map((place) => ({ kind: 'place' as const, place }))];
  }, [areas, needle, search]);
  const areaCount = options.filter((o) => o.kind === 'area').length;
  const showList = open && (options.length > 0 || (needle.length >= 2 && (search.status === 'done' || search.status === 'error')));

  const choose = (option: Option) => {
    setOpen(false);
    if (option.kind === 'area') {
      setQuery(option.area.name);
      onSelectArea?.(option.area);
    } else {
      setQuery(option.place.name);
      onSelect(option.place);
    }
  };

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Escape') return setOpen(false);
    if (e.key === 'ArrowDown' && !open) return setOpen(true);
    if (!open || options.length === 0) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); setActive((i) => (i + 1) % options.length); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((i) => (i - 1 + options.length) % options.length); }
    else if (e.key === 'Enter') { e.preventDefault(); if (options[active]) choose(options[active]); }
  };

  const heading = (text: string) => (
    <li role="presentation" className="px-4 pb-1 pt-2 text-xs font-bold text-ink-muted">{text}</li>
  );

  return (
    <div className="relative">
      <Search className="pointer-events-none absolute start-3 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-muted" aria-hidden />
      <Input
        role="combobox"
        aria-label={label}
        aria-expanded={showList}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={showList && options[active] ? `${listId}-${active}` : undefined}
        aria-invalid={invalid}
        className="h-12 ps-10 text-base"
        placeholder={placeholder}
        value={query}
        onChange={(e) => { setQuery(e.target.value); setOpen(true); setActive(0); }}
        onFocus={() => setOpen(true)}
        onClick={() => setOpen(true)}
        onBlur={() => window.setTimeout(() => setOpen(false), 150)}
        onKeyDown={onKeyDown}
        autoComplete="off"
      />
      {search.status === 'loading' && <Loader2 className="absolute end-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-ink-muted" aria-label="جارٍ البحث" />}
      {showList && (
        <ul id={listId} role="listbox" className="absolute inset-x-0 top-full z-[1100] mt-1 max-h-72 overflow-y-auto rounded-xl border border-cream-deep bg-white py-1 shadow-pop">
          {areaCount > 0 && heading('مناطق التوصيل — حدّد بعدها الموقع بدقة على الخريطة')}
          {options.map((o, i) => {
            const isArea = o.kind === 'area';
            const Icon = isArea ? Shapes : MapPin;
            return [
              !isArea && i === areaCount && areaCount > 0 ? <li key="places-heading" role="presentation" className="px-4 pb-1 pt-2 text-xs font-bold text-ink-muted">أماكن</li> : null,
              <li
                key={isArea ? o.area.id : `${o.place.id}-${i}`}
                id={`${listId}-${i}`}
                role="option"
                aria-selected={i === active}
                onMouseDown={(e) => { e.preventDefault(); choose(o); }}
                onMouseEnter={() => setActive(i)}
                className={cn('flex cursor-pointer items-start gap-3 px-4 py-2.5', i === active && 'bg-cream')}
              >
                <Icon className="mt-0.5 h-4 w-4 shrink-0 text-primary" aria-hidden />
                <span className="min-w-0">
                  <span className="block truncate text-sm font-bold text-ink">{isArea ? o.area.name : o.place.name}</span>
                  <span className="block truncate text-xs text-ink-muted">{isArea ? cityName(o.area.cityId) : o.place.context}</span>
                </span>
              </li>,
            ];
          })}
          {search.status === 'error' && <li className="px-4 py-3 text-sm text-red-700">تعذّر البحث الآن — حدّد الموقع بالضغط على الخريطة.</li>}
          {search.status === 'done' && options.length === 0 && <li className="px-4 py-3 text-sm text-ink-muted">لا نتائج — جرّب اسماً آخر أو حدّد الموقع على الخريطة.</li>}
        </ul>
      )}
    </div>
  );
}
