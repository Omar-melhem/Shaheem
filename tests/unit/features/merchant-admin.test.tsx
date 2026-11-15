// @vitest-environment jsdom
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { ScheduleFields } from '@/features/merchant/request-captain/ScheduleFields';
import { BroadcastConfirmDialog } from '@/features/admin/BroadcastConfirmDialog';
import { useAppStore } from '@/app/state';

describe('ScheduleFields (طلب مؤجل)', () => {
  const props = { date: '', time: '', minDate: '2026-11-15', onChange: vi.fn() };

  it('labels both fields, links them to the Amman-time note, and shows hints while empty', () => {
    render(<ScheduleFields {...props} />);
    const date = screen.getByLabelText(/تاريخ الاستلام/);
    const time = screen.getByLabelText(/وقت وصول الكابتن إلى المتجر/);
    expect(date).toHaveAttribute('type', 'date');
    expect(date).toHaveAttribute('min', '2026-11-15');
    expect(time).toHaveAttribute('type', 'time');
    for (const el of [date, time]) expect(el).toHaveAccessibleDescription(/بتوقيت عمّان/);
    expect(screen.getByText('اختر التاريخ')).toBeInTheDocument();
    expect(screen.getByText('اختر الوقت')).toBeInTheDocument();
  });

  it('reports date and time separately', () => {
    const onChange = vi.fn();
    render(<ScheduleFields {...props} onChange={onChange} />);
    fireEvent.change(screen.getByLabelText(/تاريخ الاستلام/), { target: { value: '2026-11-16' } });
    fireEvent.change(screen.getByLabelText(/وقت وصول/), { target: { value: '14:30' } });
    expect(onChange).toHaveBeenNthCalledWith(1, { date: '2026-11-16' });
    expect(onChange).toHaveBeenNthCalledWith(2, { time: '14:30' });
  });

  it('an error replaces the note, marks both fields invalid and is announced', () => {
    render(<ScheduleFields {...props} date="2020-01-01" time="10:00" error="اختر وقتاً في المستقبل" />);
    expect(screen.getByRole('alert')).toHaveTextContent('اختر وقتاً في المستقبل');
    expect(screen.getByLabelText(/تاريخ الاستلام/)).toHaveAttribute('aria-invalid', 'true');
    expect(screen.getByLabelText(/وقت وصول/)).toHaveAccessibleDescription('اختر وقتاً في المستقبل');
    expect(screen.queryByText('اختر التاريخ')).not.toBeInTheDocument();
  });
});

describe('BroadcastConfirmDialog (header switch)', () => {
  beforeEach(() => useAppStore.getState().resetDemo());

  it('stopping needs confirmation and explains the real effect', async () => {
    const onClose = vi.fn();
    render(<BroadcastConfirmDialog next={false} onClose={onClose} />);
    expect(screen.getByRole('dialog', { name: 'إيقاف البث العام؟' })).toHaveTextContent('تبقى في طابور الإدارة للتوزيع اليدوي');
    await userEvent.click(screen.getByRole('button', { name: 'تأكيد الإيقاف' }));
    expect(useAppStore.getState().settings.publicBroadcast).toBe(false);
    expect(onClose).toHaveBeenCalled();
  });

  it('cancel keeps the setting unchanged', async () => {
    render(<BroadcastConfirmDialog next={false} onClose={() => {}} />);
    await userEvent.click(screen.getByRole('button', { name: 'إلغاء' }));
    expect(useAppStore.getState().settings.publicBroadcast).toBe(true);
  });

  it('is closed when there is nothing to switch', () => {
    render(<BroadcastConfirmDialog next={null} onClose={() => {}} />);
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('enabling uses the same single setting', async () => {
    useAppStore.getState().setPublicBroadcast(false);
    render(<BroadcastConfirmDialog next onClose={() => {}} />);
    await userEvent.click(screen.getByRole('button', { name: 'تفعيل' }));
    expect(useAppStore.getState().settings.publicBroadcast).toBe(true);
  });
});
