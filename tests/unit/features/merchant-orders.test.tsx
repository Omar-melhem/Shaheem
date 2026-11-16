// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';
import { MerchantOrdersPage } from '@/features/merchant/orders/MerchantOrdersPage';
import { MerchantOrderDetail } from '@/features/merchant/orders/MerchantOrderDetail';
import type { DeliveryOrder } from '@/domain/types';

beforeEach(() => {
  useAppStore.getState().resetDemo();
  useSession.getState().signIn({ role: 'merchant', id: 'm-sanabel' });
});

const renderPage = () => render(<MemoryRouter><MerchantOrdersPage /></MemoryRouter>);

describe('merchant order history', () => {
  it('each finished order opens its read-only details', async () => {
    renderPage();
    const rows = screen.getAllByRole('button', { name: /عرض تفاصيل الطلب SH-/ });
    expect(rows.length).toBeGreaterThan(0);
    await userEvent.click(rows[0]);
    const drawer = screen.getByRole('dialog');
    expect(within(drawer).getByText('رسوم التوصيل')).toBeInTheDocument();
    expect(within(drawer).getByText('مراحل الطلب')).toBeInTheDocument();
    expect(within(drawer).queryByRole('button', { name: /إلغاء|تعديل/ })).not.toBeInTheDocument();
  });

  it('search narrows the list by reference', async () => {
    renderPage();
    const first = screen.getAllByRole('button', { name: /عرض تفاصيل الطلب SH-/ })[0];
    const ref = first.getAttribute('aria-label')!.replace('عرض تفاصيل الطلب ', '');
    await userEvent.type(screen.getByRole('searchbox', { name: 'بحث في الطلبات' }), ref);
    expect(screen.getAllByRole('button', { name: /عرض تفاصيل الطلب SH-/ })).toHaveLength(1);
    await userEvent.clear(screen.getByRole('searchbox'));
    await userEvent.type(screen.getByRole('searchbox'), 'لا يوجد شيء كهذا');
    expect(screen.getByText(/لا توجد طلبات مطابقة/)).toBeInTheDocument();
  });
});

describe('MerchantOrderDetail', () => {
  const base = useAppStore.getState().orders[0];
  const order = {
    ...base,
    customerPhone: undefined,
    history: [
      { to: 'pending_dispatch', actor: { role: 'merchant', id: 'm', name: 'السنابل' }, at: 1, note: 'تم إنشاء الطلب' },
      { from: 'pending_dispatch', to: 'offered_privately', actor: { role: 'admin', id: 'admin', name: 'الإدارة' }, at: 2, note: 'عرض خاص للكابتن فلان' },
      { from: 'offered_privately', to: 'offered_privately', actor: { role: 'captain', id: 'c', name: 'فلان' }, at: 3, note: 'رفض الكابتن العرض' },
    ],
  } as unknown as DeliveryOrder;

  it('shows status changes only — no internal notes or declined-offer entries', () => {
    render(<MerchantOrderDetail order={order} onClose={() => {}} />);
    const drawer = screen.getByRole('dialog');
    expect(drawer).not.toHaveTextContent('عرض خاص للكابتن فلان');
    expect(drawer).not.toHaveTextContent('رفض الكابتن العرض');
    expect(within(drawer).getAllByRole('listitem')).toHaveLength(2); // creation + the one real status change
  });

  it('a missing customer phone reads «غير مضاف»', () => {
    render(<MerchantOrderDetail order={order} onClose={() => {}} />);
    expect(screen.getByText('هاتف العميل').nextSibling).toHaveTextContent('غير مضاف');
  });

  it('renders nothing without an order', () => {
    const { container } = render(<MerchantOrderDetail order={null} onClose={() => {}} />);
    expect(container).toBeEmptyDOMElement();
  });
});
