import { create } from 'zustand';
import { CheckCircle2, AlertTriangle, Info, X } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

type ToastKind = 'success' | 'error' | 'info';
interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
  description?: string;
}
interface ToastOptions {
  description?: string;
  durationMs?: number;
}

const useToastStore = create<{ toasts: Toast[]; push: (kind: ToastKind, message: string, options?: ToastOptions) => void; dismiss: (id: number) => void }>((set) => ({
  toasts: [],
  push: (kind, message, options) => {
    const id = Date.now() + Math.random();
    set((s) => ({ toasts: [...s.toasts.slice(-3), { id, kind, message, description: options?.description }] }));
    setTimeout(() => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })), options?.durationMs ?? (kind === 'error' ? 6000 : 3500));
  },
  dismiss: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}));

export const toast = {
  success: (m: string, options?: ToastOptions) => useToastStore.getState().push('success', m, options),
  error: (m: string, options?: ToastOptions) => useToastStore.getState().push('error', m, options),
  info: (m: string, options?: ToastOptions) => useToastStore.getState().push('info', m, options),
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
    <div className="pointer-events-none fixed inset-x-0 top-[max(1rem,env(safe-area-inset-top))] z-[2000] flex flex-col items-start gap-2 px-4" aria-live="polite">
      {toasts.map((t) => {
        const Icon = icons[t.kind];
        return (
          <div key={t.id} role="status" className={cn('pointer-events-auto flex w-full max-w-md items-start gap-3 rounded-xl border px-4 py-3 shadow-pop motion-safe:animate-rise', tones[t.kind])}>
            <Icon className="mt-0.5 h-5 w-5 shrink-0" aria-hidden />
            <div className="flex-1">
              <p className="text-sm font-medium text-ink">{t.message}</p>
              {t.description && <p className="mt-0.5 text-xs text-ink-soft">{t.description}</p>}
            </div>
            <button onClick={() => dismiss(t.id)} className="text-ink-muted hover:text-ink" aria-label="إغلاق التنبيه">
              <X className="h-4 w-4" />
            </button>
          </div>
        );
      })}
    </div>
  );
}
