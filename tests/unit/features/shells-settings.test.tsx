// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';

// Leaflet needs a real layout engine; the map itself is not under test here.
vi.mock('@/shared/components/map/BaseMap', () => ({ BaseMap: ({ label }: { label: string }) => <div aria-label={label} /> }));
vi.mock('react-leaflet', () => ({ Marker: () => null }));

const { MerchantLayout } = await import('@/features/merchant/MerchantLayout');
const { MerchantSettingsPage } = await import('@/features/merchant/MerchantSettingsPage');
const { AdminLayout } = await import('@/features/admin/AdminLayout');
const { AdminSettingsPage } = await import('@/features/admin/AdminSettingsPage');

function renderMerchant(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/login" element={<p>صفحة الدخول</p>} />
        <Route path="/merchant" element={<MerchantLayout />}>
          <Route index element={<p>نموذج الطلب</p>} />
          <Route path="orders" element={<p>سجل الطلبات</p>} />
          <Route path="areas" element={<p>المناطق</p>} />
          <Route path="settings" element={<MerchantSettingsPage />} />
        </Route>
      </Routes>
    </MemoryRouter>,
  );
}

function renderAdmin(path: string) {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <Routes>
        <Route path="/login" element={<p>صفحة الدخول</p>} />
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<p>لوحة</p>} />
          <Route path="settings" element={<AdminSettingsPage />} />
        </Route>
      </Routes>
    </MemoryRouter>,
  );
}

beforeEach(() => {
  useAppStore.getState().resetDemo();
});

describe('Merchant navigation (right sidebar)', () => {
  beforeEach(() => useSession.getState().signIn({ role: 'merchant', id: 'm-sanabel' }));

  it('shows the merchant identity and the existing destinations in the sidebar', () => {
    renderMerchant('/merchant');
    const sidebar = screen.getByTestId('shell-sidebar');
    expect(within(sidebar).getByText('مطعم السنابل')).toBeInTheDocument();
    const nav = within(sidebar).getByRole('navigation', { name: 'تنقل بوابة التاجر' });
    expect(within(nav).getAllByRole('listitem').map((li) => li.textContent)).toEqual(['طلب كابتن', 'الطلبات', 'المناطق والأسعار', 'دعم شهم', 'الإعدادات']);
    expect(within(nav).getByRole('link', { name: 'طلب كابتن' })).toHaveAttribute('aria-current', 'page');
  });

  it('has no standalone «خروج» anywhere in the shell', () => {
    renderMerchant('/merchant');
    expect(screen.queryByRole('button', { name: /خروج/ })).not.toBeInTheDocument();
    expect(screen.queryByRole('link', { name: /خروج/ })).not.toBeInTheDocument();
  });

  it('sidebar links open the existing routes', async () => {
    renderMerchant('/merchant');
    const sidebar = screen.getByTestId('shell-sidebar');
    await userEvent.click(within(sidebar).getByRole('link', { name: 'الطلبات' }));
    expect(screen.getByText('سجل الطلبات')).toBeInTheDocument();
    await userEvent.click(within(sidebar).getByRole('link', { name: 'المناطق والأسعار' }));
    expect(screen.getByText('المناطق')).toBeInTheDocument();
  });

  it('«دعم شهم» opens the official support dialog', async () => {
    renderMerchant('/merchant');
    await userEvent.click(within(screen.getByTestId('shell-sidebar')).getByRole('button', { name: 'دعم شهم' }));
    expect(screen.getByRole('dialog', { name: 'تواصل مع شهم' })).toBeInTheDocument();
  });
});

describe('Merchant settings', () => {
  beforeEach(() => useSession.getState().signIn({ role: 'merchant', id: 'm-sanabel' }));

  it('contains only store info, account and sign-out (no duplicated areas or support sections)', () => {
    renderMerchant('/merchant/settings');
    const headings = screen.getAllByRole('heading', { level: 2 }).map((h) => h.textContent);
    expect(headings).toEqual(['معلومات المتجر', 'الحساب والأمان', 'تسجيل الخروج']);
    expect(screen.getByText('merchant1')).toBeInTheDocument();
  });

  it('sign-out asks first; cancel keeps the session', async () => {
    renderMerchant('/merchant/settings');
    await userEvent.click(screen.getByRole('button', { name: 'تسجيل الخروج' }));
    const dialog = screen.getByRole('dialog', { name: 'تأكيد تسجيل الخروج' });
    expect(dialog).toHaveTextContent('هل أنت متأكد أنك تريد تسجيل الخروج؟');
    await userEvent.click(within(dialog).getByRole('button', { name: 'إلغاء' }));
    expect(useSession.getState().session).toEqual({ role: 'merchant', id: 'm-sanabel' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('confirming signs out and goes to the login page', async () => {
    renderMerchant('/merchant/settings');
    await userEvent.click(screen.getByRole('button', { name: 'تسجيل الخروج' }));
    await userEvent.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'تسجيل الخروج' }));
    expect(useSession.getState().session).toBeNull();
    expect(screen.getByText('صفحة الدخول')).toBeInTheDocument();
  });
});

describe('Admin shell and settings', () => {
  beforeEach(() => useSession.getState().signIn({ role: 'admin', id: 'admin' }));

  it('keeps every Admin destination, the broadcast pill and notifications, without a header «خروج»', () => {
    renderAdmin('/admin');
    const nav = within(screen.getByTestId('shell-sidebar')).getByRole('navigation', { name: 'التنقل الرئيسي للإدارة' });
    const labels = within(nav).getAllByRole('link').map((a) => a.textContent?.replace(/\d+$/, ''));
    expect(labels).toEqual(['لوحة التحكم', 'مركز التوزيع', 'الخريطة الحية', 'الطلبات', 'التجار', 'الكباتن', 'مناطق التوصيل', 'أسعار التجار', 'محافظ الكباتن', 'الإعدادات']);
    const header = screen.getByRole('banner');
    expect(within(header).getByRole('button', { name: /البث العام للطلبات/ })).toBeInTheDocument();
    expect(within(header).getByRole('button', { name: /التنبيهات التشغيلية/ })).toBeInTheDocument();
    expect(within(header).queryByRole('button', { name: /خروج/ })).not.toBeInTheDocument();
  });

  it('settings: operation, commission, account, password reset and sign-out only; the toggle is the same single setting', async () => {
    renderAdmin('/admin/settings');
    expect(screen.getAllByRole('heading', { level: 2 }).map((h) => h.textContent)).toEqual(['إعدادات التشغيل', 'إعدادات العمولة', 'الحساب والأمان', 'إعادة تعيين كلمة المرور', 'تسجيل الخروج']);
    await userEvent.click(screen.getByRole('switch', { name: 'البث العام للطلبات' }));
    await userEvent.click(within(screen.getByRole('dialog', { name: 'إيقاف البث العام؟' })).getByRole('button', { name: 'تأكيد الإيقاف' }));
    expect(useAppStore.getState().settings.publicBroadcast).toBe(false);
    expect(within(screen.getByRole('banner')).getByRole('button', { name: /الحالة الآن: متوقف/ })).toBeInTheDocument();
  });

  it('admin sign-out from settings asks first', async () => {
    renderAdmin('/admin/settings');
    await userEvent.click(screen.getByRole('button', { name: 'تسجيل الخروج' }));
    await userEvent.click(within(screen.getByRole('dialog', { name: 'تأكيد تسجيل الخروج' })).getByRole('button', { name: 'تسجيل الخروج' }));
    expect(useSession.getState().session).toBeNull();
  });
});
