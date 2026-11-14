import { Navigate } from 'react-router-dom';
import { homePathFor } from '@/app/session';
import { useValidSession } from './RequireSession';
import { LoginLayout } from './components/LoginLayout';
import { BrandShowcase } from './components/BrandShowcase';
import { LoginHeader } from './components/LoginHeader';
import { LoginForm } from './components/LoginForm';
import { DemoAccountsPanel } from './components/DemoAccountsPanel';
import { BrandBackground } from './backgrounds/BrandBackground';
import { BackgroundPreviewBar } from './backgrounds/BackgroundPreviewBar';
import { useBackgroundPreview } from './backgrounds/useBackgroundPreview';

/** Login page: composition only. Credential check and routing live in hooks/useDemoSignIn. */
export function LoginPage() {
  const session = useValidSession();
  const bg = useBackgroundPreview();
  if (session) return <Navigate to={homePathFor(session)} replace />;

  return (
    <LoginLayout
      showcase={
        <BrandShowcase
          background={<BrandBackground variant={bg.variant} />}
          overlay={bg.showSelector && <BackgroundPreviewBar value={bg.variant} onChange={bg.setVariant} />}
        />
      }
      form={
        <div className="w-full max-w-[400px] motion-safe:animate-rise motion-safe:[animation-delay:80ms]">
          <LoginHeader />
          <LoginForm />
          <DemoAccountsPanel />
        </div>
      }
    />
  );
}
