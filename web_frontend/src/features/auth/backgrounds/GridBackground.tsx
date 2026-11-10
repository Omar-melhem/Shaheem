import { useId } from 'react';
import './backgrounds.css';

const CELL = 48;
const COLS = 20;
const ROWS = 20;

// Fixed pseudo-random cells (same every render) so nothing reshuffles or shifts.
const CELLS = Array.from({ length: 34 }, (_, i) => ({
  x: (i * 7 + 3) % COLS,
  y: (i * 11 + 5 + Math.floor(i / COLS) * 7) % ROWS,
  fill: i % 3 === 0 ? '#8C2335' : '#263D34',
  delay: (i * 0.37) % 4,
}));

/** Variant C — sparse grid in sand, a few brand-colour cells fading slowly; quiet in the centre. */
export function GridBackground() {
  const patternId = useId();
  const size = CELL * COLS;
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      <svg className="grid-svg" viewBox={`0 0 ${size} ${CELL * ROWS}`} preserveAspectRatio="xMidYMid slice">
        <defs>
          <pattern id={patternId} width={CELL} height={CELL} patternUnits="userSpaceOnUse">
            <path d={`M ${CELL} 0 L 0 0 0 ${CELL}`} fill="none" stroke="#C8A98A" strokeOpacity="0.45" strokeWidth="1" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill={`url(#${patternId})`} />
        {CELLS.map((c, i) => (
          <rect
            key={i}
            className="grid-cell"
            x={c.x * CELL + 1}
            y={c.y * CELL + 1}
            width={CELL - 1}
            height={CELL - 1}
            fill={c.fill}
            fillOpacity="0.2"
            style={{ animationDelay: `${c.delay}s` }}
          />
        ))}
      </svg>
    </div>
  );
}
