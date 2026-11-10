import './backgrounds.css';

/** Variant B — muted satin sheen: two low-contrast gradient layers sliding very slowly. */
export function SilkBackground() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      <div className="silk-layer silk-layer--a" />
      <div className="silk-layer silk-layer--b" />
      <div className="bg-calm-centre" />
    </div>
  );
}
