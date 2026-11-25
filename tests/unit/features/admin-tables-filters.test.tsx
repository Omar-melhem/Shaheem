// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';
import { OrdersPage } from '@/features/admin/OrdersPage';
import { MerchantsPage } from '@/features/admin/MerchantsPage';
import { CaptainsPage } from '@/features/admin/captains/CaptainsPage';
import { ORDER_STATUS_LABEL } from '@/domain/orderStatus';

beforeEach(() => {
  useAppStore.getState().resetDemo();
  useSession.getState().signIn({ role: 'admin', id: 'admin' });
});
afterEach(() => vi.unstubAllGlobals());

const inRouter = (ui: React.ReactNode, path = '/') => render(<MemoryRouter initialEntries={[path]}>{ui}</MemoryRouter>);
const count = () => screen.getAllByText(/^\d+ طلب$/)[0].textContent;

describe('merchant and captain tables: one ⓘ legend above each table', () => {
  it('merchants: every row keeps its five labelled actions and the legend names them', async () => {
    inRouter(<MerchantsPage />);
    const rows = screen.getAllByRole('row').slice(1);
    expect(within(rows[0]).getAllByRole('button').length + within(rows[0]).getAllByRole('link').length).toBe(5);
    expect(within(rows[0]).getByRole('button', { name: 'عرض التفاصيل' })).toBeInTheDocument();
    expect(within(rows[0]).getByRole('link', { name: 'المناطق والأسعار' })).toBeInTheDocument();
    expect(screen.getAllByRole('button', { name: 'شرح إجراءات الجدول' })).toHaveLength(1);
    await userEvent.click(screen.getByRole('button', { name: 'شرح إجراءات الجدول' }));
    const legend = screen.getByRole('dialog', { name: 'شرح إجراءات التجار' });
    expect(within(legend).getAllByRole('listitem')).toHaveLength(5);
  });

  it('merchants: the power action still asks for confirmation', async () => {
    inRouter(<MerchantsPage />);
    await userEvent.click(screen.getAllByRole('button', { name: /إيقاف الحساب|تفعيل الحساب/ })[0]);
    expect(screen.getByRole('dialog', { name: /حساب .*؟/ })).toBeInTheDocument();
  });

  it('captains: six actions, the legend has six entries, a missing location explains itself', async () => {
    const [first] = useAppStore.getState().captains;
    useAppStore.setState((s) => ({ captains: s.captains.map((c) => (c.id === first.id ? { ...c, lastLocation: undefined } : c)) }));
    inRouter(<CaptainsPage />);
    expect(screen.getAllByRole('button', { name: /فتح الموقع على الخريطة — لا يظهر على الخريطة الحية/ }).length).toBeGreaterThan(0);
    await userEvent.click(screen.getByRole('button', { name: 'شرح إجراءات الجدول' }));
    expect(within(screen.getByRole('dialog', { name: 'شرح إجراءات الكباتن' })).getAllByRole('listitem')).toHaveLength(6);
  });

  it('empty results offer a reset path', async () => {
    inRouter(<MerchantsPage />);
    await userEvent.type(screen.getByRole('searchbox'), 'لا يوجد تاجر بهذا الاسم');
    await userEvent.click(screen.getByRole('button', { name: 'مسح الفلاتر' }));
    expect(screen.getAllByRole('row').length).toBeGreaterThan(1);
  });
});

describe('orders page: phone filter sheet shares the applied state', () => {
  const someStatus = () => useAppStore.getState().orders[0].status;

  it('a draft changes nothing until «تطبيق الفلاتر»; closing discards it', async () => {
    inRouter(<OrdersPage />);
    const before = count();
    await userEvent.click(screen.getByRole('button', { name: 'تصفية' }));
    const sheet = screen.getByRole('dialog', { name: 'تصفية الطلبات' });
    await userEvent.selectOptions(within(sheet).getByRole('combobox', { name: 'الحالة' }), someStatus());
    expect(count()).toBe(before);
    await userEvent.click(within(sheet).getByRole('button', { name: 'إغلاق' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'تصفية' })).toHaveFocus();
    expect(count()).toBe(before);
  });

  it('applying shows the badge, chips and the same value in the inline select', async () => {
    inRouter(<OrdersPage />);
    const status = someStatus();
    const expected = useAppStore.getState().orders.filter((o) => o.status === status).length;
    await userEvent.click(screen.getByRole('button', { name: 'تصفية' }));
    const sheet = screen.getByRole('dialog');
    await userEvent.selectOptions(within(sheet).getByRole('combobox', { name: 'الحالة' }), status);
    await userEvent.click(within(sheet).getByRole('button', { name: 'تطبيق الفلاتر' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(count()).toBe(`${expected} طلب`);
    expect(screen.getByRole('button', { name: 'تصفية، 1 فلاتر مطبّقة' })).toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'الحالة' })).toHaveValue(status);
    const chips = screen.getByRole('list', { name: 'الفلاتر المطبّقة' });
    expect(chips).toHaveTextContent(ORDER_STATUS_LABEL[status]);
    await userEvent.click(within(chips).getByRole('button', { name: /إزالة فلتر/ }));
    expect(screen.queryByRole('list', { name: 'الفلاتر المطبّقة' })).not.toBeInTheDocument();
    expect(screen.getByRole('combobox', { name: 'الحالة' })).toHaveValue('');
  });

  it('reset clears the draft; «مسح الكل» clears applied filters; URL pre-filter is honoured', async () => {
    const merchantId = useAppStore.getState().merchants[0].id;
    inRouter(<OrdersPage />, `/admin/orders?merchant=${merchantId}`);
    expect(screen.getByRole('combobox', { name: 'التاجر' })).toHaveValue(merchantId);
    await userEvent.click(screen.getByRole('button', { name: /^تصفية، 1/ }));
    const sheet = screen.getByRole('dialog');
    expect(within(sheet).getByRole('combobox', { name: 'التاجر' })).toHaveValue(merchantId);
    await userEvent.click(within(sheet).getByRole('button', { name: 'إعادة ضبط' }));
    expect(within(sheet).getByRole('combobox', { name: 'التاجر' })).toHaveValue('');
    await userEvent.click(within(sheet).getByRole('button', { name: 'إغلاق' }));
    expect(screen.getByRole('combobox', { name: 'التاجر' })).toHaveValue(merchantId); // closing kept the applied value
    await userEvent.click(screen.getByRole('button', { name: 'مسح الكل' }));
    expect(screen.getByRole('combobox', { name: 'التاجر' })).toHaveValue('');
  });

  it('zero results show a reset that clears search and filters', async () => {
    inRouter(<OrdersPage />);
    const before = count();
    await userEvent.type(screen.getByRole('searchbox'), 'zzz-no-such-order');
    expect(screen.getByText('لا توجد طلبات مطابقة')).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'مسح البحث والفلاتر' }));
    expect(count()).toBe(before);
    expect(screen.getByRole('searchbox')).toHaveValue('');
  });

  it('widening to the inline layout closes an open sheet without touching the filters', async () => {
    let listener: (() => void) | undefined;
    const mq = { matches: false, addEventListener: (_: string, l: () => void) => (listener = l), removeEventListener: vi.fn() };
    vi.stubGlobal('matchMedia', () => mq);
    inRouter(<OrdersPage />);
    await userEvent.click(screen.getByRole('button', { name: 'تصفية' }));
    expect(screen.getByRole('dialog')).toBeInTheDocument();
    mq.matches = true;
    act(() => listener?.());
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
