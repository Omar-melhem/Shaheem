// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes, useNavigate } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';
import { ScrollToTop } from '@/app/ScrollToTop';
import { destinationParts, destinationText } from '@/domain/destination';
import { formatMoney } from '@/domain/money';
import { ORDER_STATUS_LABEL, orderStatusLabel } from '@/domain/orderStatus';
import { glueDayPeriod } from '@/domain/time';
import { LoginPage } from '@/features/auth/LoginPage';
import { PASSWORD_REQUIRED, USERNAME_REQUIRED } from '@/features/auth/components/LoginForm';
import { SupportContactList } from '@/features/support/SupportContacts';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { MapLegend } from '@/shared/components/map/MapLegend';
import { IconAction } from '@/shared/components/ui';

beforeEach(() => {
  useAppStore.getState().resetDemo();
  useSession.getState().signOut();
});

describe('phase 3 — shared formatting', () => {
  it('#11 prices use one format: two decimals and «د.أ»', () => {
    expect(formatMoney(2000)).toBe('2.00 د.أ');
    expect(formatMoney(1750)).toBe('1.75 د.أ');
  });

  it('#12 the time keeps its «ص/م» on the same line', () => {
    expect(glueDayPeriod('21 تشرين الثاني، 12:19 م')).toBe('21 تشرين الثاني، 12:19 م');
    expect(glueDayPeriod('3:05 ص')).toBe('3:05 ص');
  });

  it('#13 the area is named once', () => {
    const areaOnly = { destination: { label: 'منطقة الشميساني' }, areaName: 'الشميساني' };
    expect(destinationParts(areaOnly)).toEqual({ area: 'الشميساني' });
    expect(destinationText(areaOnly)).toBe('الشميساني');
    const described = { destination: { label: 'خلف سيتي مول' }, areaName: 'خلدا' };
    expect(destinationText(described)).toBe('خلف سيتي مول · خلدا');
    expect(destinationText({ destination: { label: 'الصويفية' }, areaName: 'الصويفية' })).toBe('الصويفية');
  });

  it('#14 every route change scrolls to the top', async () => {
    const scrollTo = vi.spyOn(window, 'scrollTo').mockImplementation(() => {});
    function Go() {
      const navigate = useNavigate();
      return <button onClick={() => navigate('/b')}>go</button>;
    }
    render(
      <MemoryRouter initialEntries={['/a']}>
        <ScrollToTop />
        <Routes>
          <Route path="/a" element={<Go />} />
          <Route path="/b" element={<p>b</p>} />
        </Routes>
      </MemoryRouter>,
    );
    scrollTo.mockClear();
    await userEvent.click(screen.getByText('go'));
    expect(scrollTo).toHaveBeenCalledWith(expect.objectContaining({ top: 0 }));
    scrollTo.mockRestore();
  });
});

describe('phase 4 — merchant wording', () => {
  it('#18 a failed dispatch reads differently for merchants; admin keeps the internal label', () => {
    expect(orderStatusLabel('dispatch_expired', { audience: 'merchant' })).toBe('بانتظار كابتن – فريق شهم يتابع الطلب');
    expect(orderStatusLabel('dispatch_expired')).toBe(ORDER_STATUS_LABEL.dispatch_expired);
    render(<OrderStatusBadge status="dispatch_expired" audience="merchant" />);
    expect(screen.queryByText('انتهى التوزيع دون إسناد')).not.toBeInTheDocument();
  });

  it('#17 the empty support list never mentions the admin panel', () => {
    render(<SupportContactList />);
    expect(document.body.textContent).not.toMatch(/لوحة الإدارة/);
  });

  it('#16 configured support channels are shown to the merchant', () => {
    useAppStore.setState({ supportContacts: [{ id: 's1', channel: 'whatsapp', label: 'دعم شهم', value: '0791234567', enabled: true, order: 1 }] } as never);
    render(<SupportContactList />);
    expect(screen.getByRole('link', { name: /دعم شهم/ })).toHaveAttribute('href', 'https://wa.me/0791234567');
  });
});

describe('phase 5 — admin polish', () => {
  it('#20 the map legend starts collapsed', () => {
    const { container } = render(<MapLegend />);
    expect(container.querySelector('details')).not.toHaveAttribute('open');
  });

  it('#22 icon actions show their label as a hover tooltip', () => {
    render(<IconAction icon={<svg />} label="شحن المحفظة" onClick={() => {}} />);
    expect(screen.getByRole('button', { name: 'شحن المحفظة' })).toHaveAttribute('title', 'شحن المحفظة');
  });
});

describe('phase 6 — login', () => {
  const renderLogin = () => render(<MemoryRouter><LoginPage /></MemoryRouter>);

  it('#25 #30 #31 placeholder, no ⓘ, one demo panel holding the demo tools (collapsed)', () => {
    renderLogin();
    expect(screen.getByLabelText('اسم المستخدم')).toHaveAttribute('placeholder', 'merchant1');
    expect(screen.queryByRole('button', { name: 'معلومات الحساب' })).not.toBeInTheDocument();
    const panel = screen.getByText('أدوات وحسابات العرض').closest('details')!;
    expect(panel).not.toHaveAttribute('open');
    expect(panel.querySelector('button[aria-label="أدوات العرض"]')).not.toBeNull();
    expect(screen.queryByText('حسابات العرض')).not.toBeInTheDocument();
  });

  it('#27 #28 empty submit: clear messages and focus on the first invalid field', async () => {
    renderLogin();
    await userEvent.click(screen.getByRole('button', { name: 'دخول' }));
    expect(screen.getByText(USERNAME_REQUIRED)).toBeInTheDocument();
    expect(screen.getByText(PASSWORD_REQUIRED)).toBeInTheDocument();
    expect(screen.getByLabelText('اسم المستخدم')).toHaveFocus();

    await userEvent.type(screen.getByLabelText('اسم المستخدم'), 'merchant1');
    await userEvent.click(screen.getByRole('button', { name: 'دخول' }));
    expect(screen.getByLabelText('كلمة المرور')).toHaveFocus();
  });

  it('#26 #29 a failed sign-in clears and focuses the password and keeps the demo panel closed', async () => {
    renderLogin();
    await userEvent.type(screen.getByLabelText('اسم المستخدم'), 'merchant1');
    await userEvent.type(screen.getByLabelText('كلمة المرور'), 'wrong-password');
    await userEvent.click(screen.getByRole('button', { name: 'دخول' }));
    await waitFor(() => expect(screen.getByRole('alert')).toHaveTextContent('غير صحيحة'));
    expect(screen.getByLabelText('كلمة المرور')).toHaveValue('');
    expect(screen.getByLabelText('كلمة المرور')).toHaveFocus();
    expect(screen.getByText('أدوات وحسابات العرض').closest('details')).not.toHaveAttribute('open');
  });
});
