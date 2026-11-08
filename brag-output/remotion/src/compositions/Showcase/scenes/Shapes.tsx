import {evolvePath, getBoundingBox, translatePath} from '@remotion/paths';
import {
  makeCircle,
  makeHeart,
  makePolygon,
  makeRect,
  makeStar,
  makeTriangle,
} from '@remotion/shapes';
import {useMemo} from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {AnimatedText} from '../../../components/AnimatedText';
import {Chip} from '../../../components/Chip';
import {useBeat} from '../../../lib/absolute-frame';
import {framesPerBeat} from '../../../lib/beat';
import {makeMorph} from '../../../lib/morph';
import {useLayout} from '../../../lib/layout';
import {EASE, SPRING, enter, tween} from '../../../lib/motion';
import {withAlpha} from '../../../theme/colors';
import type {Palette} from '../../../theme/schemes';
import {textStyle} from '../../../theme/typography';

/** Moves a path so its bounding box is centered on (0, 0). */
const centered = (d: string) => {
  const box = getBoundingBox(d);
  return translatePath(d, -(box.x1 + box.x2) / 2, -(box.y1 + box.y2) / 2);
};

const makeShapes = (s: number) =>
  [
    {
      name: 'makeStar()',
      d: makeStar({points: 5, innerRadius: s * 0.22, outerRadius: s * 0.5, cornerRadius: s * 0.03})
        .path,
    },
    {name: 'makeCircle()', d: makeCircle({radius: s * 0.42}).path},
    {name: 'makeHeart()', d: makeHeart({height: s * 0.78}).path},
    {
      name: 'makePolygon()',
      d: makePolygon({points: 6, radius: s * 0.47, cornerRadius: s * 0.07}).path,
    },
    {
      name: 'makeRect()',
      d: makeRect({width: s * 0.74, height: s * 0.74, cornerRadius: s * 0.17}).path,
    },
  ].map((shape) => ({...shape, d: centered(shape.d)}));

export const Shapes: React.FC<{palette: Palette}> = ({palette}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {unit, safe, isPortrait, width, height} = useLayout();
  const {pulse} = useBeat(6);
  const beatLen = framesPerBeat(fps);

  const stage = isPortrait
    ? Math.min(width - safe * 2, height * 0.46)
    : Math.min(height - safe * 2, width * 0.42);
  const shapes = useMemo(() => makeShapes(stage * 0.6), [stage]);
  const morphs = useMemo(
    () => shapes.map((shape, i) => makeMorph(shape.d, shapes[(i + 1) % shapes.length].d)),
    [shapes],
  );
  const ring = useMemo(() => centered(makeCircle({radius: stage * 0.46}).path), [stage]);
  const satellites = useMemo(
    () => [
      centered(
        makeTriangle({length: stage * 0.1, direction: 'up', cornerRadius: stage * 0.012}).path,
      ),
      centered(makeStar({points: 4, innerRadius: stage * 0.02, outerRadius: stage * 0.055}).path),
      centered(makeCircle({radius: stage * 0.035}).path),
    ],
    [stage],
  );

  // Morph once per beat from beat 1, spending the first 55% of each beat on the move.
  const beat = frame / beatLen;
  const step = Math.max(0, Math.floor(beat) - 1);
  const morph = beat < 1 ? 0 : tween(beat - 1 - step, [0, 0.55], [0, 1], EASE.inOut);
  const from = shapes[step % shapes.length];
  const to = shapes[(step + 1) % shapes.length];
  const d = morphs[step % shapes.length](morph);
  const label = beat < 1 || morph < 0.5 ? from.name : to.name;

  const pop = enter(frame, fps, {config: SPRING.bouncy});
  const ringDraw = tween(frame, [0, beatLen * 3], [0, 1], EASE.inOut);
  const spin = (step + morph) * 36 + frame * 0.15;
  const textIn = enter(frame, fps, {delay: Math.round(beatLen * 1.5)});

  return (
    <AbsoluteFill
      style={{
        padding: safe,
        flexDirection: isPortrait ? 'column' : 'row',
        alignItems: 'center',
        justifyContent: isPortrait ? 'center' : 'space-between',
        gap: 48 * unit,
      }}
    >
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 36 * unit,
          flex: isPortrait ? undefined : 1,
        }}
      >
        <AnimatedText
          text={'Shapes that\nmorph on the beat.'}
          stagger={Math.round(beatLen / 4)}
          style={{...textStyle('heading', unit), color: palette.text}}
        />
        <p
          style={{
            ...textStyle('body', unit),
            color: palette.muted,
            maxWidth: 680 * unit,
            opacity: textIn,
            transform: `translateY(${(1 - textIn) * 20 * unit}px)`,
          }}
        >
          Primitives from @remotion/shapes, morphed point by point with @remotion/paths and drawn on
          with evolvePath().
        </p>
        <div style={{opacity: textIn}}>
          <Chip palette={palette} prefix="→">
            {label}
          </Chip>
        </div>
      </div>

      <svg
        width={stage}
        height={stage}
        viewBox={`${-stage / 2} ${-stage / 2} ${stage} ${stage}`}
        style={{overflow: 'visible', flexShrink: 0}}
      >
        <defs>
          <linearGradient id="shape-fill" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={palette.accent} />
            <stop offset="100%" stopColor={palette.accent2} />
          </linearGradient>
          <radialGradient id="shape-glow">
            <stop offset="0%" stopColor={withAlpha(palette.accent, 0.45)} />
            <stop offset="100%" stopColor={withAlpha(palette.accent, 0)} />
          </radialGradient>
        </defs>
        <circle r={stage * 0.5} fill="url(#shape-glow)" opacity={0.6 + 0.4 * pulse} />
        <path
          d={ring}
          fill="none"
          stroke={withAlpha(palette.text, 0.22)}
          strokeWidth={2 * unit}
          {...evolvePath(ringDraw, ring)}
          transform="rotate(-90)"
        />
        <g transform={`rotate(${spin}) scale(${pop * (1 + 0.045 * pulse)})`}>
          <path d={d} fill="url(#shape-fill)" />
        </g>
        {satellites.map((sd, i) => {
          const p = enter(frame, fps, {
            delay: Math.round(beatLen * (0.5 + i * 0.5)),
            config: SPRING.bouncy,
          });
          const angle = ((i * 120 + frame * 0.9) * Math.PI) / 180;
          const r = stage * 0.46;
          const fill = [palette.accent3, palette.accent2, palette.text][i];
          return (
            <g
              key={i}
              transform={`translate(${Math.cos(angle) * r} ${Math.sin(angle) * r}) rotate(${frame * 2 + i * 40}) scale(${p})`}
            >
              <path d={sd} fill={fill} />
            </g>
          );
        })}
      </svg>
    </AbsoluteFill>
  );
};
