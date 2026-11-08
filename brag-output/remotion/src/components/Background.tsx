import {noise2D} from '@remotion/noise';
import {AbsoluteFill, random} from 'remotion';
import {useAbsoluteFrame} from '../lib/absolute-frame';
import {useLayout} from '../lib/layout';
import {withAlpha} from '../theme/colors';
import type {Palette} from '../theme/schemes';

type Props = {
  palette: Palette;
  /** Rotates which accent glows where, so each scene gets its own tint. */
  tint?: number;
  grid?: boolean;
  grain?: boolean;
};

const BLOBS = [
  {x: 0.16, y: 0.2, size: 0.95, seed: 'a'},
  {x: 0.88, y: 0.86, size: 0.85, seed: 'b'},
  {x: 0.78, y: 0.08, size: 0.55, seed: 'c'},
] as const;

// One noise tile, rasterized once by the browser and reused on every frame.
const GRAIN_TILE = 256;
const GRAIN_SVG = `url("data:image/svg+xml,${encodeURIComponent(
  `<svg xmlns="http://www.w3.org/2000/svg" width="${GRAIN_TILE}" height="${GRAIN_TILE}"><filter id="n"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter><rect width="100%" height="100%" filter="url(#n)"/></svg>`,
)}")`;

/**
 * Background: soft colored light drifting on noise, a faint grid, a vignette and film
 * grain. It stays cheap enough for real-time preview:
 *  - the glows are radial gradients moved with transforms, never `filter: blur()`
 *  - the grain is one cached noise tile, jittered by a seeded offset
 * The clock is the absolute frame, so the drift doesn't jump at cuts.
 */
export const Background: React.FC<Props> = ({palette, tint = 0, grid = true, grain = true}) => {
  const frame = useAbsoluteFrame();
  const {width, height, unit} = useLayout();
  const accents = [palette.accent, palette.accent2, palette.accent3];
  const t = frame / 120;
  const glow = palette.isDark ? 0.26 : 0.2;
  const cell = 120 * unit;
  const grainStep = Math.floor(frame / 2);

  return (
    <AbsoluteFill style={{backgroundColor: palette.background, overflow: 'hidden'}}>
      {BLOBS.map((b, i) => {
        const color = accents[(i + tint) % accents.length];
        const size = Math.max(width, height) * b.size;
        const x = (b.x + noise2D(`${b.seed}x`, t, tint) * 0.07) * width - size / 2;
        const y = (b.y + noise2D(`${b.seed}y`, tint, t) * 0.07) * height - size / 2;
        return (
          <div
            key={b.seed}
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              width: size,
              height: size,
              transform: `translate(${x}px, ${y}px)`,
              background: `radial-gradient(circle closest-side, ${withAlpha(color, glow)} 0%, ${withAlpha(color, glow * 0.4)} 46%, ${withAlpha(color, 0)} 100%)`,
            }}
          />
        );
      })}
      {grid ? (
        <AbsoluteFill
          style={{
            backgroundImage: `linear-gradient(to right, ${palette.line} 1px, transparent 1px), linear-gradient(to bottom, ${palette.line} 1px, transparent 1px)`,
            backgroundSize: `${cell}px ${cell}px`,
            backgroundPosition: `${(frame * 0.25 * unit) % cell}px ${(width % cell) / 2}px`,
            opacity: 0.55,
            maskImage: 'radial-gradient(ellipse at center, black 20%, transparent 78%)',
          }}
        />
      ) : null}
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse at center, transparent 50%, ${withAlpha('rgb(0, 0, 0)', palette.isDark ? 0.5 : 0.08)} 100%)`,
        }}
      />
      {grain ? (
        <AbsoluteFill
          style={{
            backgroundImage: GRAIN_SVG,
            backgroundSize: `${GRAIN_TILE}px ${GRAIN_TILE}px`,
            backgroundPosition: `${Math.floor(random(`gx${grainStep}`) * GRAIN_TILE)}px ${Math.floor(random(`gy${grainStep}`) * GRAIN_TILE)}px`,
            opacity: palette.isDark ? 0.07 : 0.05,
            mixBlendMode: 'overlay',
          }}
        />
      ) : null}
    </AbsoluteFill>
  );
};
