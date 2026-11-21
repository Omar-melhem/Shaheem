// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest';
import { act, render, renderHook, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useAppStore } from '@/app/state';
import { LOCATION_REQUIRED, PIN_OUTSIDE_COVERAGE, detectAreaForPin } from '@/domain/destination';
import { polygonCentroid } from '@/domain/geo';
import { CUSTOMER_PHONE_ERROR, isValidOptionalPhone } from '@/domain/phone';
import type { ServiceArea } from '@/domain/types';
import { RequestCaptainPanel } from '@/features/merchant/request-captain/RequestCaptainPanel';
import { useRequestCaptainForm } from '@/features/merchant/request-captain/useRequestCaptainForm';

beforeEach(() => useAppStore.getState().resetDemo());

const sanabel = () => useAppStore.getState().merchants.find((m) => m.id === 'm-sanabel')!;
const area = (id: string) => useAppStore.getState().areas.find((a) => a.id === id)!;
const renderPanel = () => render(<RequestCaptainPanel merchant={sanabel()} />);
const submit = () => userEvent.click(screen.getByRole('button', { name: /تأكيد طلب كابتن/ }));

describe('customer phone rule (issue 8)', () => {
  it('blank is valid; a supplied number must be 10 digits starting with 07', () => {
    expect(isValidOptionalPhone('')).toBe(true);
    expect(isValidOptionalPhone('0791234567')).toBe(true);
    expect(isValidOptionalPhone('٠٧٩١٢٣٤٥٦٧')).toBe(true);
    expect(isValidOptionalPhone('07912')).toBe(false);
    expect(isValidOptionalPhone('0691234567')).toBe(false);
    expect(isValidOptionalPhone('1234567890')).toBe(false);
  });

  it('shows the inline error on blur, clears it while editing, and blocks submit', async () => {
    renderPanel();
    const phone = screen.getByPlaceholderText('07XXXXXXXX');
    await userEvent.type(phone, '07912');
    expect(screen.queryByText(CUSTOMER_PHONE_ERROR)).not.toBeInTheDocument(); // not while typing
    await userEvent.tab();
    expect(screen.getByText(CUSTOMER_PHONE_ERROR)).toBeInTheDocument();
    expect(phone).toHaveAttribute('aria-invalid', 'true');

    await userEvent.type(phone, '34567');
    expect(screen.queryByText(CUSTOMER_PHONE_ERROR)).not.toBeInTheDocument();
    await userEvent.tab();
    expect(screen.queryByText(CUSTOMER_PHONE_ERROR)).not.toBeInTheDocument();

    await userEvent.clear(phone);
    await userEvent.type(phone, '07912');
    await userEvent.selectOptions(screen.getByLabelText(/منطقة التوصيل/, { selector: 'select' }), 'a-khalda');
    await submit();
    expect(screen.getByText(CUSTOMER_PHONE_ERROR)).toBeInTheDocument();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('an empty phone stays valid on blur', async () => {
    renderPanel();
    await userEvent.click(screen.getByPlaceholderText('07XXXXXXXX'));
    await userEvent.tab();
    expect(screen.queryByText(CUSTOMER_PHONE_ERROR)).not.toBeInTheDocument();
  });
});

describe('location is required: area or map pin (issue 7)', () => {
  it('labels say the location is required and either input satisfies it', () => {
    renderPanel();
    const group = screen.getByRole('group', { name: /موقع التوصيل/ });
    expect(group).toHaveTextContent('مطلوب');
    expect(group).toHaveTextContent('اختر المنطقة من القائمة أو اضغط على الخريطة — يكفي أحدهما.');
    expect(group).not.toHaveTextContent('اختياري');
  });

  it('cannot be submitted without a location', async () => {
    renderPanel();
    await submit();
    expect(screen.getByText(LOCATION_REQUIRED)).toBeInTheDocument();
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('with an area and no phone it reaches the review step', async () => {
    renderPanel();
    await userEvent.selectOptions(screen.getByLabelText(/منطقة التوصيل/, { selector: 'select' }), 'a-khalda');
    await submit();
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('a pin dropped first selects the merchant area that contains it', () => {
    const { result } = renderHook(() => useRequestCaptainForm(sanabel()));
    act(() => result.current.setPin({ position: polygonCentroid(area('a-khalda').polygon) }));
    expect(result.current.form.areaId).toBe('a-khalda');
    expect(result.current.form.location).not.toBeNull();
    expect(result.current.pinNotice).toContain('خلدا');
    expect(result.current.resolution?.kind).toBe('ok');
    let opened = false;
    act(() => { opened = result.current.openReview(); });
    expect(opened).toBe(true);
  });

  it('a pin outside every merchant area is refused with a clear message', () => {
    const { result } = renderHook(() => useRequestCaptainForm(sanabel()));
    act(() => result.current.setPin({ position: { lat: 31.5, lng: 36.5 } }));
    expect(result.current.form.areaId).toBeNull();
    expect(result.current.form.location).toBeNull();
    expect(result.current.areaError).toBe(PIN_OUTSIDE_COVERAGE);
  });

  it('a pin in an area the merchant cannot order to (unpriced) is not used', () => {
    // Sanabel has no price for Abdoun in the seed.
    const { result } = renderHook(() => useRequestCaptainForm(sanabel()));
    act(() => result.current.setPin({ position: polygonCentroid(area('a-abdoun').polygon) }));
    expect(result.current.form.areaId).toBeNull();
    expect(result.current.areaError).toBe(PIN_OUTSIDE_COVERAGE);
  });
});

describe('detectAreaForPin', () => {
  const box = (id: string, lat: number, lng: number): ServiceArea =>
    ({ id, name: id, polygon: [{ lat, lng }, { lat, lng: lng + 1 }, { lat: lat + 1, lng: lng + 1 }, { lat: lat + 1, lng }] }) as ServiceArea;

  it('returns the single containing area, and never guesses', () => {
    const a = box('a', 0, 0);
    const b = box('b', 0, 2);
    expect(detectAreaForPin([a, b], { lat: 0.5, lng: 2.5 })?.id).toBe('b');
    expect(detectAreaForPin([a, b], { lat: 5, lng: 5 })).toBeNull();
    expect(detectAreaForPin([a, box('overlap', 0, 0.5)], { lat: 0.5, lng: 0.75 })).toBeNull();
    expect(detectAreaForPin([{ ...a, polygon: [] }], { lat: 0.5, lng: 0.5 })).toBeNull();
  });
});
