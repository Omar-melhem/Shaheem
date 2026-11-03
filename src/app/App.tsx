import { useEffect } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { enableCrossTabSync } from '@/application/store';
import { useSimulationClock } from '@/application/hooks';
import { Toaster } from '@/shared/components/toast';
import { DemoToolsButton } from '@/features/demo/DemoToolsButton';
import { LoginPage } from '@/features/auth/LoginPage';
import { HomeRedirect, RequireSession } from '@/features/auth/RequireSession';
import { AdminLayout } from '@/features/admin/AdminLayout';
import { DashboardPage } from '@/features/admin/DashboardPage';
import { DispatchPage } from '@/features/admin/DispatchPage';
import { LiveMapPage } from '@/features/admin/LiveMapPage';
import { OrdersPage } from '@/features/admin/OrdersPage';
import { MerchantsPage } from '@/features/admin/MerchantsPage';
import { MerchantZonesPage } from '@/features/admin/MerchantZonesPage';
import { CaptainsPage } from '@/features/admin/CaptainsPage';
import { ServiceAreasPage } from '@/features/admin/ServiceAreasPage';
import { PricingPage } from '@/features/admin/PricingPage';
import { WalletsPage } from '@/features/admin/WalletsPage';
import { SupportSettingsPage } from '@/features/admin/SupportSettingsPage';
import { AdminSettingsPage } from '@/features/admin/AdminSettingsPage';
import { MerchantPortal } from '@/features/merchant/MerchantPortal';
import { MerchantSettingsPage } from '@/features/merchant/MerchantSettingsPage';
import { CaptainApp } from '@/features/captain/CaptainApp';

export function App() {
  useSimulationClock();
  useEffect(() => enableCrossTabSync(), []);

  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<HomeRedirect />} />
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/admin"
          element={
            <RequireSession role="admin">
              <AdminLayout />
            </RequireSession>
          }
        >
          <Route index element={<DashboardPage />} />
          <Route path="dispatch" element={<DispatchPage />} />
          <Route path="map" element={<LiveMapPage />} />
          <Route path="orders" element={<OrdersPage />} />
          <Route path="merchants" element={<MerchantsPage />} />
          <Route path="merchants/:merchantId/zones" element={<MerchantZonesPage />} />
          <Route path="captains" element={<CaptainsPage />} />
          <Route path="areas" element={<ServiceAreasPage />} />
          <Route path="pricing" element={<PricingPage />} />
          <Route path="wallets" element={<WalletsPage />} />
          <Route path="support" element={<SupportSettingsPage />} />
          <Route path="settings" element={<AdminSettingsPage />} />
        </Route>
        <Route
          path="/merchant"
          element={
            <RequireSession role="merchant">
              <MerchantPortal />
            </RequireSession>
          }
        />
        <Route
          path="/merchant/settings"
          element={
            <RequireSession role="merchant">
              <MerchantSettingsPage />
            </RequireSession>
          }
        />
        <Route
          path="/captain"
          element={
            <RequireSession role="captain">
              <CaptainApp />
            </RequireSession>
          }
        />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
      <DemoToolsButton />
      <Toaster />
    </BrowserRouter>
  );
}
