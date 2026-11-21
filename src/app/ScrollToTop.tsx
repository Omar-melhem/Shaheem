import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

/** Every route change starts at the top of the page (query-string changes such as filters do not scroll). */
export function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'instant' as ScrollBehavior });
  }, [pathname]);
  return null;
}
