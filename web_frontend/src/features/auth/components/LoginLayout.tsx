import type { ReactNode } from 'react';

/**
 * Two-panel login layout. In RTL the first column sits on the right: the white
 * form panel. The brand showcase takes the left column from tablet width up.
 */
export function LoginLayout({ form, showcase }: { form: ReactNode; showcase: ReactNode }) {
  return (
    <div className="grid min-h-screen bg-white md:grid-cols-[minmax(0,46fr)_minmax(0,54fr)]">
      <main className="flex items-center justify-center px-5 pb-24 pt-10 sm:px-10 md:py-12">{form}</main>
      {showcase}
    </div>
  );
}
