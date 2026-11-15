// @vitest-environment jsdom
import { describe, expect, it, vi } from 'vitest';
import { fireEvent, render, renderHook, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import {
  Card, CardHeader, DetailRow, Drawer, EmptyState, IconAction, OpenDecision, PageHeader, SearchField, SettingsRow, SettingsSection, SimTag, StatCard,
} from '@/shared/components/ui';
import { DeliveryProgress, OrderHistoryList } from '@/shared/components/OrderTimeline';
import { useCaptainViews } from '@/shared/hooks/application';
import { useAppStore } from '@/app/state';
import type { DeliveryOrder } from '@/domain/types';

describe('layout primitives', () => {
  it('PageHeader renders a level-1 heading, description and actions', () => {
    render(<PageHeader title="الطلبات" description="وصف" actions={<button>إضافة</button>} />);
    expect(screen.getByRole('heading', { level: 1, name: 'الطلبات' })).toBeInTheDocument();
    expect(screen.getByText('وصف')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'إضافة' })).toBeInTheDocument();
  });

  it('Card + CardHeader render a level-2 heading and optional parts', () => {
    render(<Card data-testid="card"><CardHeader title="العروض" description="الجولة الحالية" actions={<button>تحديث</button>} icon={<svg />} /></Card>);
    expect(screen.getByRole('heading', { level: 2, name: 'العروض' })).toBeInTheDocument();
    expect(screen.getByTestId('card')).toHaveClass('min-w-0', 'break-words');
  });

  it('StatCard shows label, value and hint', () => {
    render(<StatCard label="بانتظار التوزيع" value={3} hint="لم تُعرض بعد" tone="warning" icon={<svg />} />);
    expect(screen.getByText('بانتظار التوزيع')).toBeInTheDocument();
    expect(screen.getByText('3')).toBeInTheDocument();
    expect(screen.getByText('لم تُعرض بعد')).toBeInTheDocument();
  });

  it('EmptyState: full version with action, compact version only the title', () => {
    const { rerender } = render(<EmptyState title="لا توجد طلبات" description="ستظهر هنا" action={<button>إنشاء</button>} icon={<svg />} />);
    expect(screen.getByText('ستظهر هنا')).toBeInTheDocument();
    rerender(<EmptyState compact title="لا توجد عروض" description="لن تظهر" />);
    expect(screen.getByText('لا توجد عروض')).toBeInTheDocument();
    expect(screen.queryByText('لن تظهر')).not.toBeInTheDocument();
  });

  it('DetailRow is a dt/dd pair', () => {
    render(<dl><DetailRow label="التاجر">السنابل</DetailRow></dl>);
    expect(screen.getByText('التاجر').tagName).toBe('DT');
    expect(screen.getByText('السنابل').tagName).toBe('DD');
  });

  it('settings rows mark read-only values', () => {
    render(<SettingsSection title="الإعدادات"><SettingsRow label="العمولة" readOnly>20%</SettingsRow><SettingsRow label="بدون قيمة" /></SettingsSection>);
    expect(screen.getByLabelText('للعرض فقط')).toBeInTheDocument();
    expect(screen.getByText('20%')).toBeInTheDocument();
  });

  it('demo labels: SimTag default text, OpenDecision shows its O-ID', () => {
    render(<><SimTag /><OpenDecision id="O-032">قرار مفتوح</OpenDecision></>);
    expect(screen.getByText('محاكاة')).toBeInTheDocument();
    expect(screen.getByText('O-032')).toHaveAttribute('dir', 'ltr');
  });

  it('SearchField is a labelled search input', () => {
    render(<SearchField label="بحث في الطلبات" />);
    expect(screen.getByRole('searchbox', { name: 'بحث في الطلبات' })).toBeInTheDocument();
  });
});

describe('IconAction', () => {
  it('is a labelled button that calls onClick', () => {
    const onClick = vi.fn();
    render(<IconAction icon={<svg />} label="عرض الطلب" onClick={onClick} tone="primary" />);
    fireEvent.click(screen.getByRole('button', { name: 'عرض الطلب' }));
    expect(onClick).toHaveBeenCalled();
  });

  it('becomes a link with `to`, and a disabled button when disabled', () => {
    const { rerender } = render(<MemoryRouter><IconAction icon={<svg />} label="الأسعار" to="/admin/pricing" /></MemoryRouter>);
    expect(screen.getByRole('link', { name: 'الأسعار' })).toHaveAttribute('href', '/admin/pricing');
    rerender(<MemoryRouter><IconAction icon={<svg />} label="الأسعار" to="/admin/pricing" disabled /></MemoryRouter>);
    expect(screen.getByRole('button', { name: 'الأسعار' })).toBeDisabled();
  });
});

describe('Drawer', () => {
  it('is a labelled modal side panel that closes on Escape', () => {
    const onClose = vi.fn();
    const { rerender } = render(<Drawer open={false} onClose={onClose} title="SH-1">x</Drawer>);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    rerender(<Drawer open onClose={onClose} title="SH-1" subtitle="تفاصيل" footer={<button>حفظ</button>}>محتوى</Drawer>);
    expect(screen.getByRole('dialog', { name: 'SH-1' })).toHaveTextContent('محتوى');
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(onClose).toHaveBeenCalled();
  });
});

describe('order timeline', () => {
  const at = Date.UTC(2026, 10, 9, 9);
  const order = {
    status: 'picked_up',
    history: [
      { to: 'pending_dispatch', actor: { role: 'merchant', name: 'السنابل' }, at, note: 'تم إنشاء الطلب' },
      { from: 'pending_dispatch', to: 'accepted', actor: { role: 'captain', name: 'سامر' }, at: at + 60_000 },
      { from: 'accepted', to: 'accepted', actor: { role: 'system', name: 'النظام' }, at: at + 90_000, note: 'ملاحظة داخلية' },
      { from: 'accepted', to: 'heading_to_pickup', actor: { role: 'captain', name: 'سامر' }, at: at + 120_000 },
      { from: 'heading_to_pickup', to: 'picked_up', actor: { role: 'captain', name: 'سامر' }, at: at + 300_000 },
    ],
  } as unknown as DeliveryOrder;

  it('history lists newest first, notes shown for same-status entries', () => {
    render(<OrderHistoryList order={order} />);
    const items = screen.getAllByRole('listitem');
    expect(items[0]).toHaveTextContent('تم الاستلام من التاجر');
    expect(items[2]).toHaveTextContent('ملاحظة داخلية');
    expect(items[0]).toHaveTextContent('الكابتن — سامر');
  });

  it('progress marks the stages reached so far and renders nothing outside delivery', () => {
    const { container, rerender } = render(<DeliveryProgress order={order} />);
    expect(screen.getAllByRole('listitem')).toHaveLength(5);
    rerender(<DeliveryProgress order={{ ...order, status: 'cancelled' } as DeliveryOrder} />);
    expect(container).toBeEmptyDOMElement();
  });
});

describe('useCaptainViews (derived captain status)', () => {
  it('derives busy / available / offline / inactive from store data', () => {
    useAppStore.getState().resetDemo();
    const { result } = renderHook(() => useCaptainViews(Date.now()));
    const byId = Object.fromEntries(result.current.map((v) => [v.captain.id, v]));
    expect(byId['c-samer'].opStatus).toBe('busy');
    expect(byId['c-samer'].activeOrderId).toBeTruthy();
    expect(byId['c-ahmad'].opStatus).toBe('available');
    expect(byId['c-khaled'].opStatus).toBe('offline');
    expect(byId['c-laith'].opStatus).toBe('inactive');
    expect(byId['c-laith'].freshness).toBe('none');
    expect(byId['c-ahmad'].balance).toBeGreaterThan(0);
  });
});
