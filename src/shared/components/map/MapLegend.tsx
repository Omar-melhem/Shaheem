import { CAPTAIN_STATUS_COLOR, STALE_COLOR } from './markers';

export function MapLegend() {
  const item = (color: string, label: string, style: 'solid' | 'dashed' | 'square' = 'solid') => (
    <li className="flex items-center gap-2">
      <span
        className={style === 'square' ? 'h-3.5 w-3.5 rounded-[4px] border-2 border-sand' : 'h-3.5 w-3.5 rounded-full'}
        style={{ background: color, outline: style === 'dashed' ? `2px dashed ${color}` : undefined, outlineOffset: 2 }}
      />
      {label}
    </li>
  );
  return (
    <div className="rounded-xl bg-white/95 p-3 text-xs shadow-card ring-1 ring-cream-deep">
      <p className="mb-2 font-bold text-ink">دليل الخريطة</p>
      <ul className="space-y-1.5 text-ink-soft">
        {item(CAPTAIN_STATUS_COLOR.available, 'كابتن متاح')}
        {item(CAPTAIN_STATUS_COLOR.busy, 'كابتن في توصيل (تتبع نشط)')}
        {item(STALE_COLOR, 'موقع متأخر — انقطع GPS', 'dashed')}
        {item(CAPTAIN_STATUS_COLOR.offline, 'غير متاح / موقع غير متتبَّع')}
        {item('#242424', 'تاجر (نقطة الاستلام)', 'square')}
        {item('#8C2335', 'وجهة العميل')}
      </ul>
      <p className="mt-2 border-t border-cream-dark pt-2 text-[11px] text-ink-muted">جميع المواقع في هذا النموذج محاكاة. الخط المتقطع توضيحي وليس مساراً فعلياً.</p>
    </div>
  );
}
