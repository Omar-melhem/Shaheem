import { useEffect, useState } from 'react';
import { searchPlaces, type PlaceResult } from '@/infrastructure/placeSearch';

export type PlaceSearchState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'done'; results: PlaceResult[] }
  | { status: 'error' };

/** Debounced place search (min 2 chars); cancels stale requests so results never arrive out of order. */
export function usePlaceSearch(query: string, enabled: boolean): PlaceSearchState {
  const [state, setState] = useState<PlaceSearchState>({ status: 'idle' });

  useEffect(() => {
    const q = query.trim();
    if (!enabled || q.length < 2) {
      setState({ status: 'idle' });
      return;
    }
    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      setState({ status: 'loading' });
      searchPlaces(q, controller.signal)
        .then((results) => setState({ status: 'done', results }))
        .catch((err: unknown) => {
          if ((err as Error).name !== 'AbortError') setState({ status: 'error' });
        });
    }, 350);
    return () => {
      window.clearTimeout(timer);
      controller.abort();
    };
  }, [query, enabled]);

  return state;
}
