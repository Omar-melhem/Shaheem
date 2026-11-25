// @vitest-environment jsdom
import type { ReactNode } from 'react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { ORDER_TOTAL_ERROR } from '@/domain/orderTotal';
import { TOPUP_LIMIT_ERROR } from '@/domain/wallet';

// Leaflet needs a real layout engine: render map children plainly and markers as labelled items.
vi.mock('@/shared/components/map/BaseMap', () => ({
  BaseMap: ({ label, children }: { label: string; children?: ReactNode }) => <div aria-label={label}>{children}</div>,
  FitBounds: () => null,
  InvalidateSize: () => null,
  MapClickHandler: () => null,
}));
vi.mock('react-leaflet', () => ({
  Marker: ({ title, children, draggable }: { title?: string; children?: ReactNode; draggable?: boolean }) => <div data-testid="marker" data-draggable={String(!!draggable)} title={title}>{children}</div>,
  Tooltip: ({ children }: { children?: ReactNode }) => <span>{children}</span>,
  Polygon: () => null,
  useMap: () => ({ setView: () => {}, getZoom: () => 13 }),
}));

const { LiveMapPage } = await import('@/features/admin/live-map/LiveMapPage');
const { WalletsPage } = await import('@/features/admin/WalletsPage');
const { ServiceAreasPage } = await import('@/features/admin/service-areas/ServiceAreasPage');
const { DashboardPage } = await import('@/features/admin/dashboard/DashboardPage');
const { AdminSettingsPage } = await import('@/features/admin/AdminSettingsPage');
const { RequestCaptainPanel } = await import('@/features/merchant/request-captain/RequestCaptainPanel');

const S = () => useAppStore.getState();
const inRouter = (node: ReactNode) => render(<MemoryRouter>{node}</MemoryRouter>);

beforeEach(() => S().resetDemo());

describe('1 · «أرباح شهم» on the dashboard', () => {
  it('shows realised commission only, with Amman periods', async () => {
    S().rechargeWallet('c-ahmad', 5_000, 'op-ui-1'); // a top-up must not show as revenue
    inRouter(<DashboardPage />);
    const card = screen.getByRole('heading', { name: 'أرباح شهم' }).closest('section')!;
    expect(within(card).getByText(/العمولات المحصلة من الطلبات المسلّمة/)).toBeInTheDocument();
    expect(within(card).getByText(/0\.00/)).toBeInTheDocument();
    await userEvent.click(within(card).getByRole('button', { name: 'الإجمالي' }));
    expect(within(card).getByRole('button', { name: 'الإجمالي' })).toHaveAttribute('aria-pressed', 'true');
  });
});

describe('3 · live map shows only Available (recent report) and delivering Captains', () => {
  it('offline and suspended Captains get no pin, even with a stored coordinate', () => {
    S().tick(Date.now()); // the simulated 60 s reports
    inRouter(<LiveMapPage />);
    const pins = screen.getAllByTestId('marker').map((m) => m.getAttribute('title'));
    expect(pins).not.toContain('خالد النسور'); // offline, has an old coordinate
    expect(pins).not.toContain('ليث العبادي'); // suspended
    expect(pins).toContain('أحمد العمري');
    expect(screen.queryByRole('button', { name: /^غير متاح/ })).not.toBeInTheDocument();
  });
});

describe('5 · Admin has no «دعم شهم» contact page', () => {
  it('the nav and settings carry no support entry', () => {
    inRouter(<AdminSettingsPage />);
    expect(screen.queryByText(/بيانات الدعم/)).not.toBeInTheDocument();
  });
});

describe('6 · «مسار توصيل جديد» is gone from مناطق التوصيل, areas still work', () => {
  it('no route button and no empty routes card; area actions remain', () => {
    inRouter(<ServiceAreasPage />);
    expect(screen.queryByRole('button', { name: /مسار توصيل جديد/ })).not.toBeInTheDocument();
    expect(screen.queryByText(/مسارات التوصيل/)).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'منطقة جديدة' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'استيراد مناطق' })).toBeInTheDocument();
  });
});

describe('7 · top-up dialog: no «المرجع / السبب», 5 JOD cap, receipt confirmation', () => {
  it('records exactly one credit', async () => {
    inRouter(<WalletsPage />);
    await userEvent.click(screen.getByRole('button', { name: 'شحن محفظة أحمد العمري' }));
    const dialog = screen.getByRole('dialog');
    expect(within(dialog).queryByText(/المرجع|السبب/)).not.toBeInTheDocument();
    const amount = within(dialog).getByPlaceholderText('5.000');
    await userEvent.type(amount, '6');
    await userEvent.click(within(dialog).getByRole('button', { name: 'مراجعة' }));
    expect(within(dialog).getByText(TOPUP_LIMIT_ERROR)).toBeInTheDocument();
    await userEvent.clear(amount);
    await userEvent.type(amount, '5');
    await userEvent.click(within(dialog).getByRole('button', { name: 'مراجعة' }));
    const confirm = within(dialog).getByRole('button', { name: 'تأكيد الشحن' });
    expect(confirm).toBeDisabled();
    await userEvent.click(within(dialog).getByRole('checkbox'));
    const before = S().walletTx.length;
    await userEvent.click(confirm);
    expect(S().walletTx.length).toBe(before + 1);
    expect(S().walletTx[0]).toMatchObject({ captainId: 'c-ahmad', amount: 5_000, type: 'recharge' });
    expect(S().walletTx[0].reason).toBeUndefined();
  });
});

describe('8 · commission rate and password reset in settings', () => {
  it('a rate change asks for confirmation with old and new values', async () => {
    inRouter(<AdminSettingsPage />);
    const rate = screen.getByLabelText('نسبة العمولة (%)');
    await userEvent.clear(rate);
    await userEvent.type(rate, '15');
    await userEvent.click(screen.getByRole('button', { name: 'حفظ' }));
    const dialog = screen.getByRole('dialog', { name: 'تغيير نسبة العمولة؟' });
    expect(within(dialog).getByText('20%')).toBeInTheDocument();
    expect(within(dialog).getByText('15%')).toBeInTheDocument();
    await userEvent.click(within(dialog).getByRole('button', { name: 'تأكيد التغيير' }));
    expect(S().settings.commissionBp).toBe(1500);
  });

  it('a reset shows a one-time password and never the current one', async () => {
    const merchant = S().merchants[0];
    inRouter(<AdminSettingsPage />);
    await userEvent.selectOptions(screen.getByLabelText('الحساب'), merchant.id);
    await userEvent.click(screen.getByRole('button', { name: 'إعادة تعيين كلمة المرور' }));
    await userEvent.click(within(screen.getByRole('dialog', { name: 'إعادة تعيين كلمة المرور؟' })).getByRole('button', { name: 'إعادة التعيين' }));
    const handoff = screen.getByRole('dialog', { name: 'كلمة المرور المؤقتة' });
    const temp = handoff.querySelector('code')!.textContent!;
    expect(temp).toMatch(/^[A-Za-z2-9]{10}$/);
    expect(handoff.textContent).not.toContain('demo1234');
    expect(S().authenticate(merchant.username, temp).ok).toBe(true);
  });
});

describe('9 · optional «مجموع الطلب» in طلب كابتن', () => {
  const sanabel = () => S().merchants.find((m) => m.id === 'm-sanabel')!;

  it('is optional, validated on blur, and shown in the review', async () => {
    render(<RequestCaptainPanel merchant={sanabel()} />);
    const total = screen.getByLabelText(/مجموع الطلب/);
    await userEvent.type(total, '-3');
    await userEvent.tab();
    expect(screen.getByText(ORDER_TOTAL_ERROR)).toBeInTheDocument();
    await userEvent.clear(total);
    await userEvent.type(total, '12.5');
    await userEvent.selectOptions(screen.getByLabelText('منطقة التوصيل'), 'a-khalda');
    await userEvent.click(screen.getByRole('button', { name: /تأكيد طلب كابتن/ }));
    const review = screen.getByRole('dialog');
    expect(within(review).getByText('مجموع الطلب')).toBeInTheDocument();
    expect(within(review).getByText(/12\.50/)).toBeInTheDocument();
  });
});

describe('1 · the Captain wallet shows the commission debit as a deduction', () => {
  it('after a delivery: one «عمولة شهم» line with a minus sign', async () => {
    const { WalletTab } = await import('@/features/captain/OtherTabs');
    const { id } = (S().createOrder('m-sanabel', { areaId: 'a-khalda' }) as { ok: true; value: { id: string } }).value;
    const offer = S().offers.find((o) => o.orderId === id && o.status === 'pending')!;
    S().acceptOffer(offer.id, offer.captainId);
    for (let i = 0; i < 4; i++) S().advanceDelivery(id, offer.captainId);
    const captain = S().captains.find((c) => c.id === offer.captainId)!;
    const order = S().orders.find((o) => o.id === id)!;
    render(<WalletTab view={{ captain, balance: 0, eligibility: { eligible: true, reasons: [] }, freshness: 'none', opStatus: 'available', presence: 'hidden' }} />);
    expect(screen.getByText(`عمولة شهم — الطلب ${order.reference}`)).toBeInTheDocument();
    expect(screen.getAllByText((t) => t.startsWith('−')).length).toBe(1);
  });
});

describe('A1/A3 · locations are chosen by map tap or search — no draggable pin', () => {
  it('merchant pickup and customer destination markers cannot be dragged', async () => {
    const { LocationPicker } = await import('@/features/admin/LocationPicker');
    const { DestinationMapPicker } = await import('@/features/merchant/location/DestinationMapPicker');
    const point = { lat: 31.99, lng: 35.83 };
    render(<><LocationPicker value={point} onChange={() => {}} /><DestinationMapPicker value={point} pickup={point} area={S().areas[0]} onChange={() => {}} /></>);
    const markers = screen.getAllByTestId('marker');
    expect(markers.length).toBeGreaterThan(0);
    expect(markers.every((m) => m.getAttribute('data-draggable') === 'false')).toBe(true);
    expect(document.body.textContent).not.toMatch(/اسحب/);
  });
});

describe('Create Merchant form: any non-empty password', () => {
  it('no «6 أحرف» hint; empty is required; a one-letter password is accepted as typed', async () => {
    const { MerchantFormDialog } = await import('@/features/admin/merchants/MerchantFormDialog');
    inRouter(<MerchantFormDialog merchant="new" onClose={() => {}} />);
    const dialog = screen.getByRole('dialog');
    expect(dialog.textContent).not.toContain('6 أحرف');
    await userEvent.click(within(dialog).getByRole('button', { name: 'إنشاء التاجر' }));
    expect(within(dialog).getByText('كلمة المرور مطلوبة')).toBeInTheDocument();
    const password = within(dialog).getByLabelText(/^كلمة المرور/, { selector: 'input' });
    await userEvent.type(password, ' أ ');
    expect(password).toHaveValue(' أ ');
    expect(within(dialog).queryByText('كلمة المرور مطلوبة')).not.toBeInTheDocument();
  });
});

describe('shared credentials: captain password like merchant, global unique usernames, inline errors', () => {
  it('captain form: no «6 أحرف» hint, masked password, a one-letter password creates the account', async () => {
    const { CaptainFormDialog } = await import('@/features/admin/captains/CaptainFormDialog');
    const onClose = vi.fn();
    inRouter(<CaptainFormDialog captain="new" onClose={onClose} />);
    const dialog = screen.getByRole('dialog');
    expect(dialog.textContent).not.toContain('6 أحرف');
    await userEvent.type(within(dialog).getByLabelText(/الاسم الكامل/), 'كابتن جديد');
    await userEvent.type(within(dialog).getByPlaceholderText('07XXXXXXXX'), '0795556677');
    await userEvent.type(within(dialog).getByLabelText(/اسم المستخدم لتسجيل الدخول/), 'newcap');
    const password = within(dialog).getByLabelText(/^كلمة المرور/, { selector: 'input' });
    expect(password).toHaveAttribute('type', 'password');
    await userEvent.type(password, 'a');
    await userEvent.click(within(dialog).getByRole('button', { name: 'إنشاء الكابتن' }));
    expect(onClose).toHaveBeenCalled();
    expect(S().captains.some((c) => c.username === 'newcap' && c.password === 'a')).toBe(true);
  });

  it('a username owned by a merchant shows the inline duplicate error on the captain form, keeps the values and focuses the field', async () => {
    const { CaptainFormDialog } = await import('@/features/admin/captains/CaptainFormDialog');
    inRouter(<CaptainFormDialog captain="new" onClose={() => {}} />);
    const dialog = screen.getByRole('dialog');
    await userEvent.type(within(dialog).getByLabelText(/الاسم الكامل/), 'كابتن');
    await userEvent.type(within(dialog).getByPlaceholderText('07XXXXXXXX'), '0795556677');
    const username = within(dialog).getByLabelText(/اسم المستخدم لتسجيل الدخول/);
    await userEvent.type(username, 'Merchant1');
    await userEvent.type(within(dialog).getByLabelText(/^كلمة المرور/, { selector: 'input' }), 'x');
    await userEvent.click(within(dialog).getByRole('button', { name: 'إنشاء الكابتن' }));
    expect(within(dialog).getByText('اسم المستخدم مستخدم مسبقاً. اختر اسم مستخدم آخر.')).toBeInTheDocument();
    expect(within(dialog).queryByText('كلمة المرور مطلوبة')).not.toBeInTheDocument();
    expect(username).toHaveValue('Merchant1');
    expect(username).toHaveFocus();
    expect(dialog.textContent).not.toContain('مطعم السنابل'); // never names the owner
  });
});
