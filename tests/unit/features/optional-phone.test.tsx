// @vitest-environment jsdom
import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { PHONE_ERROR } from '@/domain/phone';
import { OrderReviewDialog } from '@/features/merchant/request-captain/OrderReviewDialog';
import { failureOf, newStore, valueOf } from '../application/storeHarness';

const orderOf = (s: ReturnType<typeof newStore>, id: string) => s.state().orders.find((o) => o.id === id)!;

describe('customer phone is optional (owner decision 2026-11-15)', () => {
  it('an immediate order without a phone succeeds and stores no phone', () => {
    const s = newStore();
    const { id } = valueOf(s.state().createOrder('m-sanabel', { areaId: 'a-khalda' }));
    expect(orderOf(s, id).customerPhone).toBeUndefined();
  });

  it('a scheduled order without a phone succeeds', () => {
    const s = newStore();
    const { id } = valueOf(s.state().createOrder('m-sanabel', { areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: Date.now() + 3_600_000 }));
    expect(orderOf(s, id)).toMatchObject({ requestType: 'scheduled', customerPhone: undefined });
  });

  it('blank or whitespace input is stored as absent, never as a fake number', () => {
    const s = newStore();
    const { id } = valueOf(s.state().createOrder('m-sanabel', { customerPhone: '   ', areaId: 'a-khalda' }));
    expect(orderOf(s, id).customerPhone).toBeUndefined();
  });

  it('a supplied phone must still be 10 digits', () => {
    const s = newStore();
    expect(failureOf(s.state().createOrder('m-sanabel', { customerPhone: '07912', areaId: 'a-khalda' }))).toBe(PHONE_ERROR);
  });

  it('a valid phone is normalised and saved', () => {
    const s = newStore();
    const { id } = valueOf(s.state().createOrder('m-sanabel', { customerPhone: '٠٧٩ ١٢٣ ٤٥٦٧', areaId: 'a-khalda' }));
    expect(orderOf(s, id).customerPhone).toBe('0791234567');
  });

  it('older stored orders keep their phone', () => {
    const s = newStore();
    expect(s.state().orders.some((o) => o.customerPhone === '0790000304')).toBe(true);
  });

  it('no order carries a customer name', () => {
    const s = newStore();
    valueOf(s.state().createOrder('m-sanabel', { areaId: 'a-khalda' }));
    for (const o of s.state().orders) expect(Object.keys(o)).not.toContain('customerName');
  });
});

describe('review dialog with and without a phone', () => {
  const base = { review: { fee: 1_500, requestType: 'immediate' as const }, submitting: false, error: null, onClose: () => {}, onConfirm: () => {} };
  const details = { pickupName: 'السنابل', pickupAddress: 'الجبيهة', areaName: 'خلدا', exactLocation: null };

  it('shows «غير مضاف» instead of a blank or a call link', () => {
    render(<OrderReviewDialog {...base} details={details} />);
    expect(screen.getByText('هاتف العميل').nextSibling).toHaveTextContent('غير مضاف');
    expect(screen.queryByRole('link')).not.toBeInTheDocument();
    expect(document.body.textContent).not.toMatch(/undefined|null/);
  });

  it('shows the phone when given', () => {
    render(<OrderReviewDialog {...base} details={{ ...details, customerPhone: '0791234567' }} />);
    expect(screen.getByText('0791234567')).toHaveAttribute('dir', 'ltr');
  });
});
