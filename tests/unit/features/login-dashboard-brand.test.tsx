// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';
import { LoginPage } from '@/features/auth/LoginPage';
import { DashboardPage } from '@/features/admin/dashboard/DashboardPage';
import { scheduledForToday } from '@/application/dashboard';

describe('login brand copy and car', () => {
  beforeEach(() => useSession.getState().signOut());

  it('shows «شهم درايف» and the unvocalized tagline; the old line is gone', () => {
    render(<MemoryRouter><LoginPage /></MemoryRouter>);
    expect(screen.getAllByText('شهم درايف').length).toBeGreaterThan(0);
    const taglines = screen.getAllByText('نوصلها بشهامة ونحفظها بأمانة');
    expect(taglines.length).toBeGreaterThan(0);
    // No Arabic tashkeel anywhere in the rendered tagline (U+064B–U+0652, incl. shadda and sukun).
    for (const t of taglines) expect(t.textContent).not.toMatch(/[ً-ْ]/);
    expect(screen.queryByText(/منصة تشغيل التوصيل للأعمال/)).not.toBeInTheDocument();
    expect(screen.getByRole('heading', { level: 1, name: 'تسجيل الدخول' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'دخول' })).toBeInTheDocument();
  });

  it('keeps the original driving SHAHM car (decorative, behind the copy) and no framed photo', () => {
    const { container } = render(<MemoryRouter><LoginPage /></MemoryRouter>);
    const lane = container.querySelector('.shahm-car-lane');
    expect(lane).toHaveAttribute('aria-hidden', 'true');
    expect(lane?.querySelector('.shahm-car-run img.shahm-car')).toHaveAttribute('src', '/brand/shahm-car.png');
    expect(container.querySelector('img[src="/brand/shahm-login-car.jpg"]')).toBeNull();
    expect(container.querySelector('figure')).toBeNull();
  });
});

describe('Admin dashboard «الطلبات المؤجلة اليوم»', () => {
  const NOW = Date.UTC(2026, 10, 18, 7, 0); // 10:00 Amman
  beforeEach(() => {
    vi.useFakeTimers({ now: NOW, toFake: ['Date'] });
    useAppStore.getState().resetDemo();
    useSession.getState().signIn({ role: 'admin', id: 'admin' });
  });
  afterEach(() => vi.useRealTimers());

  const value = () => screen.getByText('الطلبات المؤجلة اليوم').nextSibling?.textContent;

  it('shows the application count and follows creation and cancellation', () => {
    render(<MemoryRouter><DashboardPage /></MemoryRouter>);
    const before = scheduledForToday(useAppStore.getState().orders, NOW);
    expect(value()).toBe(String(before));

    let id = '';
    act(() => {
      const r = useAppStore.getState().createOrder('m-sanabel', { areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: Date.UTC(2026, 10, 18, 12, 0) });
      if (!r.ok) throw new Error(r.error);
      id = r.value.id;
    });
    expect(value()).toBe(String(before + 1));

    act(() => {
      const r = useAppStore.getState().createOrder('m-sanabel', { areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: Date.UTC(2026, 10, 19, 12, 0) });
      if (!r.ok) throw new Error(r.error);
    });
    expect(value()).toBe(String(before + 1)); // tomorrow's pickup does not count

    act(() => {
      const r = useAppStore.getState().cancelOrder(id, 'اختبار');
      if (!r.ok) throw new Error(r.error);
    });
    expect(value()).toBe(String(before));
  });

  it('keeps the cleaned-up dashboard: no chart, broadcast banner, alerts or availability sections', () => {
    render(<MemoryRouter><DashboardPage /></MemoryRouter>);
    for (const gone of [/آخر 7 أيام/, /التنبيهات التشغيلية/, /توفر الكباتن/]) expect(screen.queryByText(gone)).not.toBeInTheDocument();
    for (const action of ['إضافة تاجر', 'إضافة كابتن', 'توزيع يدوي']) expect(screen.getByRole('link', { name: action })).toBeInTheDocument();
  });
});
