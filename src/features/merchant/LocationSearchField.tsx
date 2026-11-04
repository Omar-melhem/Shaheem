import { useEffect, useId, useRef, useState } from 'react';
import { Building2, Landmark, Loader2, MapPin, Route, Search, X } from 'lucide-react';
import { getPlaceProvider } from '@/application/hooks';
import { PlaceProviderError, type PlaceSuggestion } from '@/application/ports';
import { SimTag } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';

const KIND_ICON = { landmark: Landmark, street: Route, neighborhood: MapPin, business: Building2 };
const KIND_LABEL = { landmark: 'معلم', street: 'شارع', neighborhood: 'حي / منطقة', business: 'نشاط تجاري' };

type SearchState = { kind: 'idle' } | { kind: 'loading' } | { kind: 'results'; items: PlaceSuggestion[] } | { kind: 'error' };

/**
 * Customer destination search with autocomplete (SRS §5.4). Accessible combobox:
 * arrow keys move through suggestions, Enter selects, Escape closes.
 */
export function LocationSearchField({
  selected,
  onSelect,
  onClear,
  invalid,
}: {
  selected: PlaceSuggestion | null;
  onSelect: (p: PlaceSuggestion) => void;
  onClear: () => void;
  invalid?: boolean;
}) {
  const [query, setQuery] = useState('');
  const [state, setState] = useState<SearchState>({ kind: 'idle' });
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const listId = useId();
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (selected) return;
    const q = query.trim();
    if (q.length < 2) {
      setState({ kind: 'idle' });
      return;
    }
    const ctrl = new AbortController();
    const t = setTimeout(async () => {
      setState({ kind: 'loading' });
      try {
        const items = await getPlaceProvider().search(q, ctrl.signal);
        setState({ kind: 'results', items });
        setActive(0);
      } catch (e) {
        if ((e as Error).name === 'AbortError') return;
        setState(e instanceof PlaceProviderError ? { kind: 'error' } : { kind: 'error' });
      }
    }, 250);
    return () => {
      clearTimeout(t);
      ctrl.abort();
    };
  }, [query, selected]);

  const items = state.kind === 'results' ? state.items : [];

  const choose = (p: PlaceSuggestion) => {
    onSelect(p);
    setOpen(false);
    setQuery('');
  };

  if (selected) {
    const Icon = KIND_ICON[selected.kind];
    return (
      <div className="flex items-center gap-3 rounded-xl border-2 border-secondary-200 bg-secondary-50 p-3">
        <Icon className="h-5 w-5 shrink-0 text-secondary" aria-hidden />
        <div className="min-w-0 flex-1">
          <p className="font-bold text-ink">{selected.name}</p>
          <p className="text-xs text-ink-muted">{selected.context}</p>
        </div>
        <button
          type="button"
          onClick={() => {
            onClear();
            setTimeout(() => inputRef.current?.focus(), 0);
          }}
          className="rounded-lg p-1.5 text-ink-muted hover:bg-white"
          aria-label="تغيير الوجهة"
        >
          <X className="h-5 w-5" />
        </button>
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="relative">
        <Search className="pointer-events-none absolute start-3 top-1/2 h-5 w-5 -translate-y-1/2 text-ink-muted" aria-hidden />
        <input
          ref={inputRef}
          role="combobox"
          aria-expanded={open && state.kind !== 'idle'}
          aria-controls={listId}
          aria-autocomplete="list"
          aria-invalid={invalid || undefined}
          aria-activedescendant={open && items[active] ? `${listId}-${active}` : undefined}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          onKeyDown={(e) => {
            if (e.key === 'ArrowDown') {
              e.preventDefault();
              setOpen(true);
              setActive((a) => Math.min(items.length - 1, a + 1));
            } else if (e.key === 'ArrowUp') {
              e.preventDefault();
              setActive((a) => Math.max(0, a - 1));
            } else if (e.key === 'Enter' && open && items[active]) {
              e.preventDefault();
              choose(items[active]);
            } else if (e.key === 'Escape') {
              setOpen(false);
            }
          }}
          placeholder="ابحث بالمنطقة أو الشارع أو معلم قريب… مثال: الجبيهة بجانب سوبرماركت الخالد"
          className={cn(
            'h-12 w-full rounded-xl border-2 bg-white pe-10 ps-11 text-sm text-ink placeholder:text-ink-muted/70 focus:outline-none focus:ring-4',
            invalid ? 'border-red-300 focus:ring-red-100' : 'border-cream-deep focus:border-primary-300 focus:ring-primary-100',
          )}
        />
        {state.kind === 'loading' && <Loader2 className="absolute end-3 top-1/2 h-5 w-5 -translate-y-1/2 animate-spin text-primary" aria-label="جارٍ البحث" />}
      </div>

      {open && state.kind !== 'idle' && state.kind !== 'loading' && (
        <div className="absolute inset-x-0 top-full z-[600] mt-1 overflow-hidden rounded-xl border border-cream-deep bg-white shadow-pop">
          {state.kind === 'error' ? (
            <p className="p-4 text-sm text-red-700" role="alert">
              خدمة البحث عن المواقع غير متاحة مؤقتاً. حاول مرة أخرى بعد قليل، أو تواصل مع دعم شهم.
            </p>
          ) : items.length === 0 ? (
            <p className="p-4 text-sm text-ink-muted">لا توجد نتائج مطابقة. جرّب اسم الحي أو شارعاً رئيسياً أو معلماً معروفاً قريباً.</p>
          ) : (
            <ul id={listId} role="listbox" aria-label="اقتراحات المواقع" className="max-h-80 overflow-y-auto py-1">
              {items.map((p, i) => {
                const Icon = KIND_ICON[p.kind];
                return (
                  <li
                    key={p.id}
                    id={`${listId}-${i}`}
                    role="option"
                    aria-selected={i === active}
                    onMouseDown={(e) => {
                      e.preventDefault();
                      choose(p);
                    }}
                    onMouseEnter={() => setActive(i)}
                    className={cn('flex cursor-pointer items-center gap-3 px-4 py-2.5', i === active && 'bg-cream')}
                  >
                    <Icon className="h-4 w-4 shrink-0 text-sand-dark" aria-hidden />
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-bold text-ink">{p.name}</p>
                      <p className="truncate text-xs text-ink-muted">{p.context}</p>
                    </div>
                    <span className="text-[11px] text-ink-muted">{KIND_LABEL[p.kind]}</span>
                  </li>
                );
              })}
            </ul>
          )}
          <div className="flex items-center justify-between border-t border-cream-dark bg-cream/60 px-4 py-1.5">
            <SimTag>نتائج بحث تجريبية</SimTag>
            <span className="text-[11px] text-ink-muted">مزود الخرائط لم يُحدد بعد (O-018)</span>
          </div>
        </div>
      )}
    </div>
  );
}
