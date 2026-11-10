import { useState } from 'react';
import { Star } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { Captain } from '@/domain/types';
import { Button, OpenDecision, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { cn } from '@/shared/lib/cn';

/** Internal five-star rating with admin notes; used in the Captain drawer and the row «تقييم» dialog. */
export function CaptainRatingForm({ captain, onSaved }: { captain: Captain; onSaved?: () => void }) {
  const rateCaptain = useAppStore((s) => s.rateCaptain);
  const [rating, setRating] = useState<number | undefined>(captain.rating);
  const [notes, setNotes] = useState(captain.adminNotes ?? '');

  const save = () => {
    if (reportResult(rateCaptain(captain.id, rating, notes), 'تم حفظ التقييم')) onSaved?.();
  };

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-1" role="radiogroup" aria-label="التقييم من 5">
        {[1, 2, 3, 4, 5].map((n) => (
          <button key={n} type="button" role="radio" aria-checked={rating === n} aria-label={`${n} من 5`} onClick={() => setRating(rating === n ? undefined : n)}>
            <Star className={cn('h-6 w-6', rating && n <= rating ? 'fill-sand text-sand-dark' : 'text-cream-deep')} />
          </button>
        ))}
      </div>
      <Textarea value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="ملاحظات إدارية داخلية" aria-label="ملاحظات إدارية" />
      <Button size="sm" variant="outline" onClick={save}>حفظ التقييم</Button>
      <OpenDecision id="O-033">ميزة التقييم موروثة من المتطلبات السابقة؛ مقياس الخمس نجوم والملاحظات مقترحان. التقييم داخلي ولا يظهر للكابتن أو التاجر.</OpenDecision>
    </div>
  );
}
