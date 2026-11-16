// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest';
import { act, fireEvent, render, renderHook, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button, ConfirmDialog, DataTable, Dialog, InfoTooltip, RowActions, Tabs } from '@/shared/components/ui';
import { reportResult, toast, Toaster } from '@/shared/components/toast';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { useNow } from '@/shared/hooks/application';

afterEach(() => vi.useRealTimers());

describe('Button', () => {
  it('is type=button by default and busy+disabled while loading', () => {
    const { rerender } = render(<Button>حفظ</Button>);
    expect(screen.getByRole('button', { name: 'حفظ' })).toHaveAttribute('type', 'button');
    rerender(<Button loading>حفظ</Button>);
    expect(screen.getByRole('button', { name: 'حفظ' })).toBeDisabled();
    expect(screen.getByRole('button', { name: 'حفظ' })).toHaveAttribute('aria-busy', 'true');
  });
});

describe('Dialog', () => {
  it('renders nothing when closed', () => {
    render(<Dialog open={false} onClose={() => {}} title="عنوان" />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('is a labelled modal that closes on Escape, the close button and the backdrop', async () => {
    const onClose = vi.fn();
    render(<Dialog open onClose={onClose} title="تأكيد" description="وصف">محتوى</Dialog>);
    const dialog = screen.getByRole('dialog', { name: 'تأكيد' });
    expect(dialog).toHaveAttribute('aria-modal', 'true');
    expect(document.body.style.overflow).toBe('hidden');
    fireEvent.keyDown(document, { key: 'Escape' });
    await userEvent.click(screen.getByRole('button', { name: 'إغلاق' }));
    fireEvent.click(dialog.previousElementSibling!);
    expect(onClose).toHaveBeenCalledTimes(3);
  });

  it('keeps Tab inside the panel', () => {
    render(<Dialog open onClose={() => {}} title="t" footer={<button>آخر</button>}><button>أول</button></Dialog>);
    const last = screen.getByRole('button', { name: 'آخر' });
    last.focus();
    fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Tab' });
    expect(document.activeElement).toBe(screen.getByRole('button', { name: 'إغلاق' }));
  });
});

describe('ConfirmDialog', () => {
  it('cancel closes without confirming', async () => {
    const onConfirm = vi.fn();
    const onClose = vi.fn();
    render(<ConfirmDialog open onClose={onClose} onConfirm={onConfirm} title="إيقاف؟" cancelLabel="إلغاء" />);
    await userEvent.click(screen.getByRole('button', { name: 'إلغاء' }));
    expect(onConfirm).not.toHaveBeenCalled();
    expect(onClose).toHaveBeenCalled();
  });

  it('confirms once even on a double click, then closes', async () => {
    let resolve!: () => void;
    const onConfirm = vi.fn(() => new Promise<void>((r) => { resolve = r; }));
    const onClose = vi.fn();
    render(<ConfirmDialog open onClose={onClose} onConfirm={onConfirm} title="t" confirmLabel="تأكيد الإيقاف" />);
    const confirm = screen.getByRole('button', { name: 'تأكيد الإيقاف' });
    fireEvent.click(confirm);
    fireEvent.click(confirm);
    expect(onConfirm).toHaveBeenCalledTimes(1);
    await act(async () => resolve());
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it('stays open when the action returns false', async () => {
    const onClose = vi.fn();
    render(<ConfirmDialog open onClose={onClose} onConfirm={() => false} title="t" />);
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد' }));
    expect(onClose).not.toHaveBeenCalled();
  });

  it('shows an Arabic error and stays open when the action throws', async () => {
    const onClose = vi.fn();
    render(<ConfirmDialog open onClose={onClose} onConfirm={() => Promise.reject(new Error('x'))} title="t" />);
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('تعذّر تنفيذ العملية. حاول مرة أخرى.');
    expect(onClose).not.toHaveBeenCalled();
  });
});

describe('InfoTooltip', () => {
  it('opens on focus, describes the button, and closes on Escape', async () => {
    render(<InfoTooltip text="شرح" label="معلومة" />);
    const button = screen.getByRole('button', { name: 'معلومة' });
    act(() => button.focus());
    expect(button).toHaveAttribute('aria-expanded', 'true');
    expect(button).toHaveAccessibleDescription('شرح');
    fireEvent.keyDown(document, { key: 'Escape' });
    expect(button).toHaveAttribute('aria-expanded', 'false');
  });

  it('has a 44px hit area around its 24px icon', () => {
    render(<InfoTooltip text="x" label="معلومة" />);
    expect(screen.getByRole('button', { name: 'معلومة' })).toHaveClass('h-6', 'w-6', 'before:-inset-2.5');
  });
});

describe('Tabs', () => {
  it('marks the selected tab and reports clicks', async () => {
    const onChange = vi.fn();
    render(<Tabs value="a" onChange={onChange} items={[{ value: 'a', label: 'الكل', count: 3 }, { value: 'b', label: 'نشط' }]} />);
    expect(screen.getByRole('tab', { name: /الكل/ })).toHaveAttribute('aria-selected', 'true');
    await userEvent.click(screen.getByRole('tab', { name: 'نشط' }));
    expect(onChange).toHaveBeenCalledWith('b');
  });
});

describe('DataTable', () => {
  it('labels every cell with its header for the phone layout and adds the actions legend', () => {
    render(
      <DataTable headers={['الطلب', 'الحالة']} actionsLegend={[{ icon: <span />, label: 'عرض' }]}>
        <tr><td>SH-1</td><td>جديد</td><RowActions><button aria-label="عرض">o</button></RowActions></tr>
      </DataTable>,
    );
    const headers = screen.getAllByRole('columnheader').map((h) => h.textContent ?? '');
    expect(headers.slice(0, 2)).toEqual(['الطلب', 'الحالة']);
    expect(headers[2].startsWith('الإجراءات')).toBe(true); // followed by the legend inside its tooltip
    const cells = screen.getAllByRole('cell');
    expect(cells[0]).toHaveTextContent('الطلبSH-1');
    expect(cells[1]).toHaveTextContent('الحالةجديد');
    expect(screen.getByRole('button', { name: 'شرح أيقونات الإجراءات' })).toBeInTheDocument();
  });

  it('with legendTitle: one ⓘ above the table opens the legend; the header stays plain', async () => {
    render(
      <DataTable headers={['الاسم']} actionsLegend={[{ icon: <span />, label: 'تعديل البيانات', description: 'الاسم والهاتف.' }]} legendTitle="شرح إجراءات التجار" toolbar="3 تاجر">
        <tr><td>السنابل</td><RowActions><button aria-label="تعديل البيانات">o</button></RowActions></tr>
      </DataTable>,
    );
    expect(screen.getAllByRole('columnheader')[1]).toHaveTextContent(/^الإجراءات$/);
    expect(screen.queryByRole('button', { name: 'شرح أيقونات الإجراءات' })).not.toBeInTheDocument();
    expect(screen.getByText('3 تاجر')).toBeInTheDocument();
    const trigger = screen.getByRole('button', { name: 'شرح إجراءات الجدول' });
    expect(trigger).toHaveAttribute('aria-expanded', 'false');
    await userEvent.click(trigger);
    const legend = screen.getByRole('dialog', { name: 'شرح إجراءات التجار' });
    expect(legend).toHaveTextContent('تعديل البيانات');
    expect(legend).toHaveTextContent('الاسم والهاتف.');
    await userEvent.keyboard('{Escape}');
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();
    await userEvent.click(trigger);
    fireEvent.pointerDown(document.body);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
    await userEvent.click(trigger);
    await userEvent.click(screen.getByRole('button', { name: 'إغلاق الشرح' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});

describe('status badges', () => {
  it('order status uses the scheduled wording only for scheduled orders', () => {
    const { rerender } = render(<OrderStatusBadge status="pending_dispatch" />);
    expect(screen.getByText('بانتظار التوزيع')).toBeInTheDocument();
    rerender(<OrderStatusBadge status="pending_dispatch" scheduled />);
    expect(screen.getByText('بانتظار تنسيق الإدارة')).toBeInTheDocument();
    rerender(<OrderStatusBadge status="delivered" scheduled />);
    expect(screen.getByText('تم التسليم')).toBeInTheDocument();
  });

  it('freshness and captain status show their Arabic labels', () => {
    render(<><FreshnessBadge freshness="demo" /><CaptainStatusBadge status="busy" /></>);
    expect(screen.getByText('موقع تجريبي — غير متتبَّع')).toBeInTheDocument();
    expect(screen.getByText('في توصيل')).toBeInTheDocument();
  });
});

describe('toasts and reportResult', () => {
  it('shows success only when a message is given, and errors always', () => {
    vi.useFakeTimers();
    render(<Toaster />);
    act(() => { expect(reportResult({ ok: true }, 'تم الحفظ')).toBe(true); });
    act(() => { expect(reportResult({ ok: true })).toBe(true); });
    act(() => { expect(reportResult({ ok: false, error: 'فشل' })).toBe(false); });
    act(() => { expect(reportResult({ ok: false })).toBe(false); });
    expect(screen.getAllByRole('status').map((t) => t.querySelector('p')?.textContent)).toEqual(['تم الحفظ', 'فشل', 'تعذّر تنفيذ العملية']);
  });

  it('a toast disappears after its duration and can be dismissed', async () => {
    vi.useFakeTimers();
    render(<Toaster />);
    act(() => toast.info('معلومة', { durationMs: 1_000 }));
    expect(screen.getByText('معلومة')).toBeInTheDocument();
    act(() => vi.advanceTimersByTime(1_001));
    expect(screen.queryByText('معلومة')).not.toBeInTheDocument();
    act(() => toast.success('تم', { description: 'تفاصيل' }));
    expect(screen.getByText('تفاصيل')).toBeInTheDocument();
    act(() => screen.getAllByRole('button', { name: 'إغلاق التنبيه' }).slice(-1)[0].click());
    expect(screen.queryByText('تفاصيل')).not.toBeInTheDocument();
  });
});

describe('useNow', () => {
  it('re-renders on its interval', () => {
    vi.useFakeTimers();
    vi.setSystemTime(1_000_000);
    const { result } = renderHook(() => useNow(500));
    expect(result.current).toBe(1_000_000);
    act(() => vi.advanceTimersByTime(500));
    expect(result.current).toBe(1_000_500);
  });
});
