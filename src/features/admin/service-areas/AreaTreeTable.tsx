import { useState } from 'react';
import { ChevronDown, CornerDownLeft, Pencil, Plus } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { childrenOf } from '@/domain/regions';
import { governorateName } from '@/domain/governorates';
import { cityName } from '@/domain/cities';
import { Badge, Button, Toggle } from '@/shared/components/ui';
import { cn } from '@/shared/lib/cn';

const HEADERS = ['المنطقة', 'المحافظة › المدينة', 'أقسام', 'تجار يغطّونها', 'طلبات', 'الحالة', ''];

/**
 * Areas with their sub-areas (CR v1.4 §1.3): a top-level row expands to its sections.
 * `visibleIds` limits rows to search/filter matches; a parent of a matching section stays shown.
 */
export function AreaTreeTable({
  roots,
  visibleIds,
  onEdit,
  onAddSection,
  onToggle,
}: {
  roots: ServiceArea[];
  visibleIds: Set<string> | null;
  onEdit: (area: ServiceArea) => void;
  onAddSection: (parent: ServiceArea) => void;
  onToggle: (area: ServiceArea) => void;
}) {
  const areas = useAppStore((s) => s.areas);
  const coverage = useAppStore((s) => s.coverage);
  const orders = useAppStore((s) => s.orders);
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const merchantsServing = (id: string) => coverage.filter((c) => c.areaId === id).length;
  const orderCount = (id: string) => orders.filter((o) => o.areaId === id).length;

  const toggleOpen = (id: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const row = (a: ServiceArea, depth: 0 | 1, sectionCount: number) => {
    const parentOff = depth === 1 && areas.find((p) => p.id === a.parentId)?.status !== 'active';
    return (
      <tr key={a.id} className={cn(depth === 1 && 'bg-cream/40', a.status !== 'active' && 'opacity-70')}>
        <td className="px-4 py-3">
          <div className={cn('flex items-start gap-2', depth === 1 && 'ps-6')}>
            {depth === 0 ? (
              <button
                type="button"
                onClick={() => toggleOpen(a.id)}
                disabled={sectionCount === 0}
                aria-expanded={sectionCount > 0 ? !collapsed.has(a.id) : undefined}
                aria-label={`أقسام ${a.name}`}
                className="mt-0.5 rounded p-0.5 text-ink-muted hover:bg-cream disabled:invisible"
              >
                <ChevronDown className={cn('h-4 w-4 transition-transform', collapsed.has(a.id) && 'rtl:rotate-90 ltr:-rotate-90')} />
              </button>
            ) : (
              <CornerDownLeft className="mt-0.5 h-4 w-4 shrink-0 text-ink-muted" aria-hidden />
            )}
            <div>
              <p className="font-bold">{a.name}</p>
              {a.aliases.length > 0 && <p className="text-xs text-ink-muted">{a.aliases.join('، ')}</p>}
              {a.notes && <p className="text-xs text-ink-muted">{a.notes}</p>}
            </div>
          </div>
        </td>
        <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-soft">{governorateName(a.governorateId)} › {cityName(a.cityId)}</td>
        <td className="px-4 py-3">{depth === 0 ? sectionCount : '—'}</td>
        <td className="px-4 py-3">{merchantsServing(a.id)}</td>
        <td className="px-4 py-3">{orderCount(a.id)}</td>
        <td className="px-4 py-3">
          <div className="flex items-center gap-2">
            <Toggle checked={a.status === 'active'} onChange={() => onToggle(a)} label={<span className="sr-only">تفعيل {a.name}</span>} />
            <Badge tone={a.status === 'active' && !parentOff ? 'success' : 'neutral'}>{a.status !== 'active' ? 'متوقفة' : parentOff ? 'المنطقة الأم متوقفة' : 'نشطة'}</Badge>
          </div>
        </td>
        <td className="px-4 py-3">
          <div className="flex gap-1">
            <Button size="sm" variant="ghost" icon={<Pencil className="h-3.5 w-3.5" />} onClick={() => onEdit(a)}>تعديل</Button>
            {depth === 0 && <Button size="sm" variant="ghost" icon={<Plus className="h-3.5 w-3.5" />} onClick={() => onAddSection(a)}>قسم</Button>}
          </div>
        </td>
      </tr>
    );
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[860px] text-sm">
        <thead className="bg-cream text-xs text-ink-muted">
          <tr>
            {HEADERS.map((h, i) => (
              <th key={i} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-cream-dark">
          {roots.flatMap((root) => {
            const sections = childrenOf(areas, root.id);
            const shownSections = visibleIds ? sections.filter((s) => visibleIds.has(s.id)) : sections;
            const open = !collapsed.has(root.id) || (visibleIds !== null && shownSections.length > 0);
            return [row(root, 0, sections.length), ...(open ? shownSections.map((s) => row(s, 1, 0)) : [])];
          })}
        </tbody>
      </table>
    </div>
  );
}
