import './vehicle.css';

const BODY = '#8C2335'; // SHAHM primary
const BODY_DARK = '#641826';
const GLASS = '#263D34'; // SHAHM secondary, tinted glass

function Wheel({ cx }: { cx: number }) {
  return (
    <g>
      <circle cx={cx} cy={58} r={14} fill="#1f1f1f" />
      <circle cx={cx} cy={58} r={9} fill="#d9d4cc" />
      <g className="vehicle-rim" style={{ transformOrigin: `${cx}px 58px` }}>
        {[0, 72, 144, 216, 288].map((a) => (
          <rect key={a} x={cx - 1.2} y={50} width={2.4} height={8} rx={1.2} fill="#8a8580" transform={`rotate(${a} ${cx} 58)`} />
        ))}
      </g>
      <circle cx={cx} cy={58} r={2.6} fill="#4a4a4a" />
    </g>
  );
}

/**
 * Decorative SHAHM car (original vector, no third-party marks) driving right→left —
 * forward for an Arabic reader — along a faint road line, then a quiet pause.
 * CSS transform only; wheels turn while moving; parked under reduced motion.
 * Sits behind the watermark and all copy.
 */
export function VehicleAnimation({ className = 'top-[71%]' }: { className?: string }) {
  return (
    <div className={`vehicle-lane pointer-events-none absolute inset-x-0 ${className}`} aria-hidden="true">
      <div className="vehicle-road" />
      <div className="vehicle-track">
        <svg className="vehicle" viewBox="0 0 220 80" role="presentation">
          {/* ground shadow */}
          <ellipse cx={112} cy={73} rx={92} ry={4} fill="#000" fillOpacity={0.14} />
          {/* body — front faces left */}
          <path
            d="M14 58c-4 0-6-4-5-8l3-8c1-4 5-6 10-7l40-5c10-10 24-18 42-19h36c16 0 28 7 38 17l18 4c8 2 12 6 12 14v8c0 3-2 4-5 4z"
            fill={BODY}
          />
          {/* shoulder highlight */}
          <path d="M22 41l40-5h134" stroke="#fff" strokeOpacity={0.22} strokeWidth={2} fill="none" strokeLinecap="round" />
          {/* windows */}
          <path d="M70 30c8-8 20-14 34-14h14v14z" fill={GLASS} fillOpacity={0.9} />
          <path d="M124 16h16c12 0 22 5 30 14h-46z" fill={GLASS} fillOpacity={0.9} />
          <path d="M78 27c6-5 13-8 20-9" stroke="#fff" strokeOpacity={0.35} strokeWidth={1.5} fill="none" strokeLinecap="round" />
          {/* door line + mirror */}
          <path d="M121 31v24" stroke={BODY_DARK} strokeWidth={1.2} />
          <ellipse cx={67} cy={31} rx={4} ry={2.5} fill={BODY_DARK} />
          {/* lights */}
          <path d="M12 43l10-1.5v4l-11 1z" fill="#F5E6C8" />
          <rect x={203} y={37} width={4} height={8} rx={1.5} fill="#E2555F" />
          {/* wheel arches + wheels */}
          <circle cx={52} cy={58} r={17} fill={BODY_DARK} />
          <circle cx={172} cy={58} r={17} fill={BODY_DARK} />
          <Wheel cx={52} />
          <Wheel cx={172} />
        </svg>
      </div>
    </div>
  );
}
