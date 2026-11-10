import { useState } from 'react';
import { Radio, RadioTower } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { Card, OpenDecision, Toggle } from '@/shared/components/ui';
import { BroadcastConfirmDialog } from './BroadcastConfirmDialog';
import { cn } from '@/shared/lib/cn';

/** Public broadcasting switch — kept prominent on the dashboard (SRS §4.2, §4.7). */
export function BroadcastControl() {
  const enabled = useAppStore((s) => s.settings.publicBroadcast);
  const [pending, setPending] = useState<boolean | null>(null);

  return (
    <Card className={cn('overflow-hidden', enabled ? 'ring-2 ring-secondary-200' : 'ring-2 ring-amber-300')}>
      <div className={cn('flex flex-wrap items-center gap-4 p-5', enabled ? 'bg-secondary text-white' : 'bg-amber-50')}>
        <div className={cn('rounded-2xl p-3', enabled ? 'bg-white/15' : 'bg-amber-100 text-amber-800')}>
          {enabled ? <RadioTower className="h-7 w-7" /> : <Radio className="h-7 w-7" />}
        </div>
        <div className="min-w-0 flex-1">
          <p className={cn('text-xs font-bold', enabled ? 'text-white/80' : 'text-amber-800')}>البث العام للطلبات</p>
          <p className={cn('text-xl font-extrabold', !enabled && 'text-ink')}>{enabled ? 'مفعّل — الطلبات الجديدة تُعرض على الكباتن المؤهلين' : 'متوقف — الطلبات الجديدة تبقى في طابور الإدارة'}</p>
        </div>
        <div className={cn('rounded-xl px-3 py-2', enabled ? 'bg-white/10' : 'bg-white')}>
          <Toggle checked={enabled} tone="primary" onChange={(v) => setPending(v)} label={<span className={enabled ? 'text-white' : ''}>{enabled ? 'إيقاف' : 'تفعيل'}</span>} />
        </div>
      </div>
      <div className="space-y-2 p-4 text-xs text-ink-muted">
        <p>إيقاف البث لا يلغي الطلبات ولا يوقف التوصيلات النشطة أو تتبعها. الإسناد الخاص يبقى متاحاً.</p>
        <OpenDecision id="O-032">عند الإيقاف، يسحب هذا النموذج العروض العامة القائمة ويعيد طلباتها إلى الطابور (سلوك مقترح غير معتمد).</OpenDecision>
      </div>
      <BroadcastConfirmDialog next={pending} onClose={() => setPending(null)} />
    </Card>
  );
}
