import { CAPTAIN_STATUS_COLOR, STALE_COLOR } from './markers';

/** Captain marker legend for the Live Map (Captain-only view, FU-1.2 §6). */
export function MapLegend() {
  const item = (color: string, label: string, style: 'solid' | 'dashed' = 'solid') => (
    <li className="flex items-center gap-2">
      <span className="h-3.5 w-3.5 rounded-full" style={{ background: color, outline: style === 'dashed' ? `2px dashed ${color}` : undefined, outlineOffset: 2 }} />
      {label}
    </li>
  );
  return (
    <div className="rounded-xl bg-white/95 p-3 text-xs shadow-card ring-1 ring-cream-deep">
      <p className="mb-2 font-bold text-ink">دليل الخريطة</p>
      <ul className="space-y-1.5 text-ink-soft">
        {item(CAPTAIN_STATUS_COLOR.busy, 'كابتن في توصيل (تتبع نشط)')}
        {item(CAPTAIN_STATUS_COLOR.available, 'كابتن متاح — موقع غير متتبَّع')}
        {item(STALE_COLOR, 'موقع متأخر — انقطع GPS', 'dashed')}
        {item(CAPTAIN_STATUS_COLOR.offline, 'غير متاح')}
      </ul>
      <p className="mt-2 border-t border-cream-dark pt-2 text-[11px] text-ink-muted">جميع المواقع في هذا النموذج محاكاة. يُتتبع الموقع أثناء التوصيل النشط فقط.</p>
    </div>
  );
}
