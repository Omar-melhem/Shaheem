import type { Money } from '@/domain/types';

/** Use-case outcome: a value, or an Arabic error the UI shows as is. */
export interface Failure {
  ok: false;
  error: string;
  /** Machine-readable reason, e.g. 'fee_changed'. */
  code?: string;
  currentFee?: Money;
}
export type Result<T = undefined> = { ok: true; value: T } | Failure;
export const ok = <T,>(value: T): Result<T> => ({ ok: true, value });
export const done: Result = { ok: true, value: undefined };
export const fail = (error: string, extra?: Omit<Failure, 'ok' | 'error'>): Failure => ({ ok: false, error, ...extra });
