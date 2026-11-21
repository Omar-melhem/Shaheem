import { Component, type ReactNode } from 'react';

/**
 * Last-resort screen for an unexpected render error, instead of a blank page. It shows no
 * technical details to the user; reloading starts the app again from the saved demo data.
 */
export class AppErrorBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  state = { failed: false };

  static getDerivedStateFromError() {
    return { failed: true };
  }

  render() {
    if (!this.state.failed) return this.props.children;
    return (
      <main role="alert" className="flex min-h-screen flex-col items-center justify-center gap-4 bg-cream px-6 text-center">
        <h1 className="text-xl font-extrabold text-ink">حدث خطأ غير متوقع</h1>
        <p className="max-w-sm text-sm text-ink-soft">نعتذر، تعذّر عرض هذه الصفحة. أعد تحميل الصفحة للمتابعة.</p>
        <button
          type="button"
          onClick={() => window.location.reload()}
          className="h-11 rounded-xl bg-primary px-5 text-sm font-bold text-white hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300"
        >
          إعادة تحميل الصفحة
        </button>
      </main>
    );
  }
}
