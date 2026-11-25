import { CAPTAIN_STATUS_COLOR } from './markers';

/** Captain marker legend for the Live Map (Captain-only view, FU-1.2 §6). Starts collapsed so it never hides a marker. */
export function MapLegend() {
  const item = (color: string, label: string) => (
    <li className="flex items-center gap-2">
      <span className="h-3.5 w-3.5 rounded-full" style={{ background: color }} />
      {label}
    </li>
  );
  return (
    <details className="group rounded-xl bg-white/95 p-3 text-xs shadow-card ring-1 ring-cream-deep">
      <summary className="flex min-h-8 cursor-pointer list-none items-center justify-between gap-3 font-bold text-ink [&::-webkit-details-marker]:hidden">
        دليل الخريطة
        <span className="text-[11px] font-medium text-primary group-open:hidden">إظهار</span>
        <span className="hidden text-[11px] font-medium text-primary group-open:inline">إخفاء</span>
      </summary>
      <ul className="mt-2 space-y-1.5 text-ink-soft">
        {item(CAPTAIN_STATUS_COLOR.busy, 'في توصيل — مع شارة الطرد (تتبع نشط)')}
        {item(CAPTAIN_STATUS_COLOR.available, 'متاح — آخر تحديث خلال 90 ثانية')}
      </ul>
      <p className="mt-2 border-t border-cream-dark pt-2 text-[11px] text-ink-muted">لا تظهر على الخريطة: غير المتاحين والموقوفون، ومن انقطع موقعه (يظهر في القائمة بجانب الخريطة). جميع المواقع في هذا النموذج محاكاة.</p>
    </details>
  );
}
