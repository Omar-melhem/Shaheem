// @vitest-environment jsdom
import { describe, expect, it, vi } from 'vitest';
import { useState } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DateTimeInput, Field, Input, PasswordField, PhoneField, Select, Toggle } from '@/shared/components/ui';

describe('DateTimeInput (native date/time with an empty state)', () => {
  it('shows the Arabic hint and an LTR native input while empty', () => {
    const { container } = render(<DateTimeInput type="date" value="" emptyHint="اختر التاريخ" onChange={() => {}} aria-label="التاريخ" />);
    const input = screen.getByLabelText('التاريخ');
    expect(input).toHaveAttribute('type', 'date');
    expect(input).toHaveAttribute('dir', 'ltr');
    expect(input).toHaveAttribute('data-empty', 'true');
    expect(input).toHaveClass('shahm-datetime', 'h-12', 'text-base');
    expect(screen.getByText('اختر التاريخ')).toHaveAttribute('aria-hidden');
    expect(container.querySelector('svg')).toBeInTheDocument();
  });

  it('hides the hint once a value is set, and passes the machine value through', () => {
    render(<DateTimeInput type="time" value="14:30" emptyHint="اختر الوقت" onChange={() => {}} aria-label="الوقت" />);
    const input = screen.getByLabelText('الوقت') as HTMLInputElement;
    expect(input.value).toBe('14:30');
    expect(input).not.toHaveAttribute('data-empty');
    expect(screen.queryByText('اختر الوقت')).not.toBeInTheDocument();
  });

  it('reports changes as YYYY-MM-DD', () => {
    const onChange = vi.fn();
    render(<DateTimeInput type="date" value="" emptyHint="اختر التاريخ" onChange={(e) => onChange(e.target.value)} aria-label="التاريخ" />);
    fireEvent.change(screen.getByLabelText('التاريخ'), { target: { value: '2026-11-16' } });
    expect(onChange).toHaveBeenCalledWith('2026-11-16');
  });

  it('the hint and icon never take taps from the input', () => {
    const { container } = render(<DateTimeInput type="date" value="" emptyHint="اختر التاريخ" onChange={() => {}} />);
    expect(screen.getByText('اختر التاريخ')).toHaveClass('pointer-events-none');
    expect(container.querySelector('svg')).toHaveClass('pointer-events-none');
  });
});

describe('Field', () => {
  it('links its label to a single control automatically', () => {
    render(<Field label="الاسم"><Input /></Field>);
    expect(screen.getByLabelText('الاسم')).toBeInstanceOf(HTMLInputElement);
  });

  it('shows required/optional badges', () => {
    const { rerender } = render(<Field label="أ" required><Input /></Field>);
    expect(screen.getByText('مطلوب')).toBeInTheDocument();
    rerender(<Field label="أ" optional><Input /></Field>);
    expect(screen.getByText('اختياري')).toBeInTheDocument();
  });

  it('describes the control with the hint, and the error replaces the hint as an alert', () => {
    const { rerender } = render(<Field label="الهاتف" hint="عشرة أرقام"><Input /></Field>);
    const input = screen.getByLabelText('الهاتف');
    expect(input).toHaveAccessibleDescription('عشرة أرقام');
    rerender(<Field label="الهاتف" hint="عشرة أرقام" error="رقم غير صالح"><Input /></Field>);
    expect(screen.getByRole('alert')).toHaveTextContent('رقم غير صالح');
    expect(screen.queryByText('عشرة أرقام')).not.toBeInTheDocument();
  });

  it('uses htmlFor when given instead of cloning', () => {
    render(<Field label="مخصص" htmlFor="x"><div><input id="x" /></div></Field>);
    expect(screen.getByLabelText('مخصص')).toHaveAttribute('id', 'x');
  });
});

describe('PhoneField', () => {
  function Controlled({ onValue }: { onValue: (v: string) => void }) {
    const [v, setV] = useState('');
    return <PhoneField aria-label="هاتف" value={v} onChange={(d) => { setV(d); onValue(d); }} />;
  }

  it('keeps digits only, converts Arabic-Indic digits and caps at 10', () => {
    const seen = vi.fn();
    render(<Controlled onValue={seen} />);
    fireEvent.change(screen.getByLabelText('هاتف'), { target: { value: '٠٧٩ ١٢٣-٤٥٦٧ 99' } });
    expect(seen).toHaveBeenLastCalledWith('0791234567');
    expect(screen.getByLabelText('هاتف')).toHaveValue('0791234567');
  });

  it('is a tel input, LTR, numeric keypad', () => {
    render(<PhoneField aria-label="هاتف" value="" onChange={() => {}} />);
    const input = screen.getByLabelText('هاتف');
    expect(input).toHaveAttribute('type', 'tel');
    expect(input).toHaveAttribute('inputmode', 'numeric');
    expect(input).toHaveAttribute('dir', 'ltr');
  });
});

describe('PasswordField', () => {
  it('toggles visibility with an accessible button', async () => {
    render(<PasswordField aria-label="كلمة المرور" defaultValue="secret" />);
    const input = screen.getByLabelText('كلمة المرور');
    expect(input).toHaveAttribute('type', 'password');
    await userEvent.click(screen.getByRole('button', { name: 'إظهار كلمة المرور' }));
    expect(input).toHaveAttribute('type', 'text');
    expect(screen.getByRole('button', { name: 'إخفاء كلمة المرور' })).toHaveAttribute('aria-pressed', 'true');
  });
});

describe('Select', () => {
  it('renders the shared dropdown with its chevron and reports changes', () => {
    const onChange = vi.fn();
    const { container } = render(
      <Select aria-label="الحالة" defaultValue="" onChange={(e) => onChange(e.target.value)}>
        <option value="">الكل</option>
        <option value="a">أ</option>
      </Select>,
    );
    fireEvent.change(screen.getByLabelText('الحالة'), { target: { value: 'a' } });
    expect(onChange).toHaveBeenCalledWith('a');
    expect(container.querySelector('svg')).toHaveClass('pointer-events-none');
  });
});

describe('Toggle', () => {
  it('is a switch that reports the next value and respects disabled', async () => {
    const onChange = vi.fn();
    const { rerender } = render(<Toggle checked={false} onChange={onChange} label="البث العام" />);
    const sw = screen.getByRole('switch', { name: 'البث العام' });
    expect(sw).toHaveAttribute('aria-checked', 'false');
    await userEvent.click(sw);
    expect(onChange).toHaveBeenCalledWith(true);
    rerender(<Toggle checked onChange={onChange} label="البث العام" disabled />);
    await userEvent.click(screen.getByRole('switch'));
    expect(onChange).toHaveBeenCalledTimes(1);
  });

  it('has a 44px hit area (::before) without changing its 28px look', () => {
    render(<Toggle checked onChange={() => {}} aria-label="مفتاح" />);
    expect(screen.getByRole('switch', { name: 'مفتاح' })).toHaveClass('h-7', 'before:absolute', 'before:-inset-y-2');
  });
});
