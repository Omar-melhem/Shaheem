// @vitest-environment jsdom
import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { Home, Headphones, Settings } from 'lucide-react';
import { AppShell, type ShellNavItem } from '@/shared/components/layout/AppShell';

function renderShell({ headerActions, onSupport = vi.fn() }: { headerActions?: React.ReactNode; onSupport?: () => void } = {}) {
  const nav: ShellNavItem[] = [
    { to: '/m', label: 'الرئيسية', icon: Home, end: true },
    { kind: 'action', label: 'الدعم', icon: Headphones, onSelect: onSupport },
    { to: '/m/settings', label: 'الإعدادات', icon: Settings },
  ];
  return render(
    <MemoryRouter initialEntries={['/m']}>
      <Routes>
        <Route
          path="/m/*"
          element={
            <AppShell brand={<span>علامة</span>} mobileBrand={<span>علامة صغيرة</span>} nav={nav} navLabel="تنقل تجريبي" headerActions={headerActions} sidebarFooter="تذييل">
              <Routes>
                <Route index element={<p>صفحة رئيسية</p>} />
                <Route path="settings" element={<p>صفحة الإعدادات</p>} />
              </Routes>
            </AppShell>
          }
        />
      </Routes>
    </MemoryRouter>,
  );
}

describe('AppShell (shared Admin/Merchant shell)', () => {
  it('renders the sidebar nav before the content, so it sits on the right in RTL', () => {
    renderShell();
    const sidebar = screen.getByTestId('shell-sidebar');
    expect(sidebar).toHaveClass('hidden', 'lg:flex', 'w-64');
    expect(sidebar.parentElement?.firstElementChild).toBe(sidebar);
    expect(within(sidebar).getByRole('navigation', { name: 'تنقل تجريبي' })).toBeInTheDocument();
    expect(within(sidebar).getByText('تذييل')).toBeInTheDocument();
  });

  it('marks the active route and navigates', async () => {
    renderShell();
    const sidebar = screen.getByTestId('shell-sidebar');
    expect(within(sidebar).getByRole('link', { name: 'الرئيسية' })).toHaveAttribute('aria-current', 'page');
    await userEvent.click(within(sidebar).getByRole('link', { name: 'الإعدادات' }));
    expect(screen.getByText('صفحة الإعدادات')).toBeInTheDocument();
    expect(within(sidebar).getByRole('link', { name: 'الإعدادات' })).toHaveAttribute('aria-current', 'page');
  });

  it('nav items have at least a 44px touch height', () => {
    renderShell();
    for (const el of within(screen.getByTestId('shell-sidebar')).getAllByRole('link')) expect(el).toHaveClass('min-h-11');
  });

  it('the phone drawer is absent until opened, then closes on Escape', async () => {
    renderShell();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    const menu = screen.getByRole('button', { name: 'فتح القائمة' });
    expect(menu).toHaveAttribute('aria-expanded', 'false');
    await userEvent.click(menu);
    expect(screen.getByRole('dialog', { name: 'تنقل تجريبي' })).toBeInTheDocument();
    expect(menu).toHaveAttribute('aria-expanded', 'true');
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('the drawer closes after navigating and after an action', async () => {
    const onSupport = vi.fn();
    renderShell({ onSupport });
    await userEvent.click(screen.getByRole('button', { name: 'فتح القائمة' }));
    await userEvent.click(within(screen.getByRole('dialog')).getByRole('link', { name: 'الإعدادات' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(screen.getByText('صفحة الإعدادات')).toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: 'فتح القائمة' }));
    await userEvent.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'الدعم' }));
    expect(onSupport).toHaveBeenCalledTimes(1);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('without header actions the top bar exists only below lg; with actions it stays', () => {
    const { unmount } = renderShell();
    expect(screen.getByRole('banner')).toHaveClass('lg:hidden');
    unmount();
    renderShell({ headerActions: <button>تنبيهات</button> });
    expect(screen.getByRole('banner')).not.toHaveClass('lg:hidden');
    expect(screen.getByRole('button', { name: 'تنبيهات' })).toBeInTheDocument();
  });
});
