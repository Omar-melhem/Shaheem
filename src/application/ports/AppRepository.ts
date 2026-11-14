import type { AppData } from '../data';

/** Synchronous local prototype repository. A production API needs an asynchronous unit of work. */
export interface AppRepository {
  load(): AppData | null;
  save(data: AppData): void;
}
