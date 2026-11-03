import './backgrounds.css';

/** Variant A — soft brand-colour light (maroon, forest, sand) drifting slowly behind a calm centre. */
export function AuroraBackground() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      <div className="aurora-blob aurora-blob--primary" />
      <div className="aurora-blob aurora-blob--secondary" />
      <div className="aurora-blob aurora-blob--sand" />
      <div className="bg-calm-centre" />
    </div>
  );
}
