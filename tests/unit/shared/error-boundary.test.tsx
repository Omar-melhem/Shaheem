// @vitest-environment jsdom
import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AppErrorBoundary } from '@/app/AppErrorBoundary';

function Broken(): never {
  throw new Error('boom');
}

describe('AppErrorBoundary (H1)', () => {
  it('shows an Arabic fallback with a reload button instead of a blank page', () => {
    const quiet = vi.spyOn(console, 'error').mockImplementation(() => {}); // React logs caught errors
    render(<AppErrorBoundary><Broken /></AppErrorBoundary>);
    expect(screen.getByRole('alert')).toHaveTextContent('حدث خطأ غير متوقع');
    expect(screen.getByRole('button', { name: 'إعادة تحميل الصفحة' })).toBeInTheDocument();
    expect(document.body.textContent).not.toContain('boom');
    quiet.mockRestore();
  });

  it('renders children normally', () => {
    render(<AppErrorBoundary><p>ok</p></AppErrorBoundary>);
    expect(screen.getByText('ok')).toBeInTheDocument();
  });
});
