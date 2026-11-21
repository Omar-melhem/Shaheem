// @vitest-environment jsdom
import { beforeEach, describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { useAppStore } from '@/app/state';
import { useSession } from '@/app/session';
import { DashboardPage } from '@/features/admin/dashboard/DashboardPage';
import { DispatchSummary } from '@/features/admin/dispatch/DispatchSummary';
import { MerchantPortal } from '@/features/merchant/MerchantPortal';
import { ORDER_GROUP_LABEL } from '@/domain/orderStatus';

/** The value printed under a StatCard label (the label <p> is followed by the value <p>). */
const statValue = (label: string) => screen.getByText(label, { selector: 'p' }).nextSibling?.textContent;

beforeEach(() => useAppStore.getState().resetDemo());

describe('status labels and counts match across admin pages (issue 2)', () => {
  it('dashboard and distribution center show the same count for each shared label', () => {
    useSession.getState().signIn({ role: 'admin', id: 'admin' });
    const labels = [ORDER_GROUP_LABEL.pending_dispatch, ORDER_GROUP_LABEL.needs_admin, ORDER_GROUP_LABEL.offered, ORDER_GROUP_LABEL.active];
    const dash = render(<MemoryRouter><DashboardPage /></MemoryRouter>);
    const onDashboard = labels.map(statValue);
    dash.unmount();
    render(<DispatchSummary />);
    expect(labels.map(statValue)).toEqual(onDashboard);
    expect(statValue(ORDER_GROUP_LABEL.needs_admin)).toBe('1'); // the seeded failed-dispatch order
  });
});

describe('merchant «التوصيلات النشطة» only counts orders with a captain (issue 3)', () => {
  it('a merchant whose only open order has no captain sees it under «بانتظار كابتن»', () => {
    useSession.getState().signIn({ role: 'merchant', id: 'm-hail' }); // seed: one failed-dispatch order, no active delivery
    render(<MemoryRouter><MerchantPortal /></MemoryRouter>);
    expect(screen.getByText('التوصيلات النشطة (0)')).toBeInTheDocument();
    expect(screen.getByText('بانتظار كابتن (1)')).toBeInTheDocument();
  });

  it('the seeded delivery with a captain stays active', () => {
    useSession.getState().signIn({ role: 'merchant', id: 'm-sanabel' });
    render(<MemoryRouter><MerchantPortal /></MemoryRouter>);
    expect(screen.getByText('التوصيلات النشطة (1)')).toBeInTheDocument();
    expect(screen.queryByText(/بانتظار كابتن \(/)).not.toBeInTheDocument();
  });
});
