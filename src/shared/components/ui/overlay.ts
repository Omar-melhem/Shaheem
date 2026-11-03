import { useEffect, useRef } from 'react';

/** Shared Escape-to-close and focus handling for Dialog and Drawer. */
export function useEscape(open: boolean, onClose: () => void) {
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);
}

export function useFocusOnOpen(open: boolean) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const previous = document.activeElement as HTMLElement | null;
    const el = ref.current;
    const focusable = el?.querySelector<HTMLElement>('input, select, textarea, button:not([data-close])');
    (focusable ?? el)?.focus();
    return () => previous?.focus?.();
  }, [open]);
  return ref;
}
