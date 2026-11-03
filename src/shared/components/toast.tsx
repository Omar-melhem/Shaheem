import { create } from 'zustand';
import { CheckCircle2, AlertTriangle, Info, X } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

type ToastKind = 'success' | 'error' | 'info';
interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
}

const useToastStore = create<{ toasts: Toast[]; push: (kind: ToastKind, message: string) => void; dismiss: (id: number) => void }>((set) => ({
  toasts: [],
  push: (kind, message) => {
    const id = Date.now() + Math.random();
    set((s) => ({ toasts: [...s.toasts.slice(-3), { id, kind, message }] }));
    setTimeout(() => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })), kind === 'error' ? 6000 : 3500);
  },
  dismiss: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}));

export const toast = {
  success: (m: string) => useToastStore.getState().push('success', m),
  error: (m: string) => useToastStore.getState().push('error', m),
  info: (m: string) => useToastStore.getState().push('info', m),
};

/** Shows a toast for a use-case Result and returns whether it succeeded. */
export function reportResult(result: { ok: boolean; error?: string }, successMessage?: string): boolean {
  if (result.ok) {
    if (successMessage) toast.success(successMessage);
    return true;
  }
  toast.error(result.error ?? 'تعذّر تنفيذ العملية');
  return false;
}

const icons = { success: CheckCircle2, error: AlertTriangle, info: Info };
const tones = {
  success: 'border-secondary-200 bg-white text-secondary',
  error: 'border-red-200 bg-white text-red-700',
  info: 'border-cream-deep bg-white text-ink',
};

export function Toaster() {
  const { toasts, dismiss } = useToastStore();
  return (
    <div className="pointer-events-none fixed inset-x-0 bottom-4 z-[2000] flex flex-col items-center gap-2 px-4" aria-live="polite">
      {toasts.map((t) => {
        const Icon = icons[t.kind];
        return (
          <div key={t.id} role="status" className={cn('pointer-events-auto flex w-full max-w-md items-start gap-3 rounded-xl border px-4 py-3 shadow-pop', tones[t.kind])}>
            <Icon className="mt-0.5 h-5 w-5 shrink-0" aria-hidden />
            <p className="flex-1 text-sm font-medium text-ink">{t.message}</p>
            <button onClick={() => dismiss(t.id)} className="text-ink-muted hover:text-ink" aria-label="إغلاق التنبيه">
              <X className="h-4 w-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}
