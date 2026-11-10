import { useMemo, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Printer, Tags } from 'lucide-react';
import { useSession } from '@/application/session';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions, type MerchantZoneOption } from '@/application/queries';
import { governorateName } from '@/domain/governorates';
import { cityName } from '@/domain/cities';
import { formatMoneyExact } from '@/domain/money';
import { Logo } from '@/shared/components/Logo';
import { Button, Card, EmptyState, SearchField } from '@/shared/components/ui';
import { formatDate } from '@/shared/lib/format';
import { MerchantHeader } from '../MerchantHeader';

interface Group {
  key: string;
  title: string;
  rows: MerchantZoneOption[];
}

/** Groups destinations by governorate › city, keeping each section right after its parent. */
function groupOptions(options: MerchantZoneOption[]): Group[] {
  const groups = new Map<string, Group>();
  for (const o of options) {
    const key = `${o.area.governorateId}|${o.area.cityId}`;
    const gov = governorateName(o.area.governorateId);
    const city = cityName(o.area.cityId);
    if (!groups.has(key)) groups.set(key, { key, title: gov === city ? city : `${gov} › ${city}`, rows: [] });
    groups.get(key)!.rows.push(o);
  }
  return [...groups.values()].sort((a, b) => a.title.localeCompare(b.title, 'ar'));
}

/**
 * The Merchant's own delivery areas and fees, read-only, with a print layout (CR v1.4 §5).
 * Only enabled AND priced destinations appear; editing stays with Admin.
 */
export function MerchantAreasPage() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const [q, setQ] = useState('');

  const options = useMemo(() => (merchantId ? merchantZoneOptions({ areas, prices, coverage }, merchantId) : []), [areas, prices, coverage, merchantId]);
  const needle = q.trim().toLowerCase();
  const visible = options.filter((o) => !needle || [o.label, ...o.area.aliases].some((n) => n.toLowerCase().includes(needle)));
  if (!merchant) return <Navigate to="/login" replace />;

  return (
    <div className="min-h-screen print:bg-white">
      <div className="print:hidden">
        <MerchantHeader merchant={merchant} page="areas" />
      </div>

      <main className="mx-auto max-w-4xl space-y-4 px-4 py-6 print:max-w-none print:p-0">
        {/* Print-only heading: brand, merchant and date. */}
        <header className="hidden items-center justify-between border-b border-ink/20 pb-3 print:flex">
          <Logo className="h-14" />
          <div className="text-end">
            <p className="text-lg font-extrabold">{merchant.businessName}</p>
            <p className="text-sm">مناطق التوصيل والأسعار · {formatDate(Date.now())}</p>
          </div>
        </header>

        <div className="flex flex-wrap items-end justify-between gap-3 print:hidden">
          <div>
            <h1 className="text-2xl font-extrabold text-ink">مناطق التوصيل والأسعار</h1>
            <p className="mt-1 text-sm text-ink-muted">المناطق المفعّلة لحسابك ورسوم توصيلها. يحددها فريق شهم؛ للتعديل تواصل مع الإدارة.</p>
          </div>
          <Button variant="outline" icon={<Printer className="h-4 w-4" />} onClick={() => window.print()} disabled={options.length === 0}>
            طباعة القائمة
          </Button>
        </div>

        {options.length > 0 && (
          <SearchField label="بحث في مناطقك" className="max-w-sm print:hidden" placeholder="ابحث عن منطقة أو قسم" value={q} onChange={(e) => setQ(e.target.value)} />
        )}

        {options.length === 0 ? (
          <Card>
            <EmptyState icon={<Tags className="h-6 w-6" />} title="لا توجد مناطق مسعّرة لحسابك بعد" description="سيحدد فريق شهم مناطقك ورسومها، وتظهر هنا تلقائياً." />
          </Card>
        ) : visible.length === 0 ? (
          <Card><EmptyState title="لا توجد منطقة مطابقة" /></Card>
        ) : (
          groupOptions(visible).map((g) => (
            <Card key={g.key} className="overflow-hidden print:break-inside-auto print:rounded-none print:shadow-none print:ring-1 print:ring-ink/20">
              <h2 className="border-b border-cream-dark bg-cream px-5 py-3 text-sm font-extrabold text-ink print:bg-white">{g.title}</h2>
              <table className="w-full text-sm">
                <thead className="text-xs text-ink-muted">
                  <tr>
                    <th scope="col" className="px-5 py-2 text-start font-bold">منطقة التوصيل</th>
                    <th scope="col" className="w-36 px-5 py-2 text-end font-bold">رسوم التوصيل</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-cream-dark">
                  {g.rows.map((o) => (
                    <tr key={o.area.id} className="break-inside-avoid">
                      <td className="px-5 py-2.5 font-medium">{o.label}</td>
                      <td className="px-5 py-2.5 text-end font-bold" dir="ltr">{formatMoneyExact(o.price)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Card>
          ))
        )}
        <p className="text-xs text-ink-muted">عدد المناطق: {visible.length} · الأسعار الحالية لحسابك فقط.</p>
      </main>
    </div>
  );
}
