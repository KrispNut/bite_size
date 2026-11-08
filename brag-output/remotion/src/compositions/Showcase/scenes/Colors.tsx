import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {AnimatedText} from '../../../components/AnimatedText';
import {framesPerBeat} from '../../../lib/beat';
import {useLayout} from '../../../lib/layout';
import {EASE, SPRING, enter, tween} from '../../../lib/motion';
import {readableOn, sameColor, setHsl, toHex, toHsl, toRgb, withAlpha} from '../../../theme/colors';
import type {Palette} from '../../../theme/schemes';
import {textStyle} from '../../../theme/typography';

const AS_RGB = 'rgb(13, 13, 13)';
const AS_HSL = 'hsl(0, 0%, 5%)';
const CARD = 'hsl(40, 25%, 94%)';
const CARD_INK = 'rgb(13, 13, 13)';
const STEPS = 9;

export const Colors: React.FC<{palette: Palette}> = ({palette}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {unit, safe, isPortrait, width} = useLayout();
  const beat = framesPerBeat(fps);

  // A lightness ramp of the accent's own hue, built in HSL.
  const ramp = Array.from({length: STEPS}, (_, i) => setHsl(palette.accent, {l: 14 + i * 9}));

  // The cursor steps one tile per eighth note, starting on beat 2.
  const steps = (frame - beat * 2) / (beat / 2);
  const index = Math.min(STEPS - 1, Math.max(0, Math.floor(steps)));
  const glide =
    index === 0 || steps >= STEPS ? 1 : tween(steps - index, [0, 0.45], [0, 1], EASE.inOut);
  const cursor = Math.max(0, index - 1 + glide);
  const current = ramp[Math.round(cursor)];

  const card = enter(frame, fps, {delay: Math.round(beat * 0.5), config: SPRING.snappy});
  const readout = enter(frame, fps, {delay: Math.round(beat * 2)});
  const columnWidth = isPortrait ? width - safe * 2 : 860 * unit;
  const tileGap = 12 * unit;
  const tile = (columnWidth - tileGap * (STEPS - 1)) / STEPS;
  const swatch = (isPortrait ? 230 : 200) * unit;

  const readoutLines = [
    ['hsl', toHsl(current)],
    ['rgb', toRgb(current)],
    ['hex', toHex(current)],
  ];

  return (
    <AbsoluteFill
      style={{
        padding: safe,
        flexDirection: isPortrait ? 'column' : 'row',
        alignItems: isPortrait ? 'stretch' : 'center',
        justifyContent: isPortrait ? 'center' : 'space-between',
        gap: (isPortrait ? 64 : 80) * unit,
      }}
    >
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: 40 * unit,
          flex: isPortrait ? undefined : 1,
        }}
      >
        <AnimatedText
          text={'One color,\nany notation.'}
          stagger={Math.round(beat / 4)}
          style={{...textStyle('heading', unit), color: palette.text}}
        />
        <div style={{display: 'flex', flexDirection: 'column', gap: 10 * unit, opacity: readout}}>
          {readoutLines.map(([key, value], i) => (
            <div
              key={key}
              style={{
                ...textStyle('code', unit, {fontSize: 30 * unit}),
                display: 'flex',
                gap: 20 * unit,
                transform: `translateX(${(1 - readout) * (20 + i * 12) * unit}px)`,
              }}
            >
              <span style={{color: palette.muted, width: 70 * unit}}>{key}</span>
              <span style={{color: palette.text}}>{value}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{display: 'flex', flexDirection: 'column', gap: 40 * unit, width: columnWidth}}>
        <div
          style={{
            background: CARD,
            color: CARD_INK,
            borderRadius: 36 * unit,
            padding: 40 * unit,
            boxShadow: `0 ${30 * unit}px ${80 * unit}px ${withAlpha('rgb(0, 0, 0)', 0.35)}`,
            display: 'flex',
            flexDirection: 'column',
            gap: 28 * unit,
            opacity: Math.min(1, card * 1.4),
            transform: `translateY(${(1 - card) * 60 * unit}px) scale(${0.94 + 0.06 * card})`,
          }}
        >
          <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-around'}}>
            {[AS_RGB, AS_HSL].map((color, i) => (
              <div
                key={color}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: 18 * unit,
                }}
              >
                <div
                  style={{
                    width: swatch,
                    height: swatch,
                    borderRadius: 28 * unit,
                    background: color,
                    transform: `scale(${enter(frame, fps, {delay: Math.round(beat * (1 + i * 0.5)), config: SPRING.bouncy})})`,
                  }}
                />
                <div style={{...textStyle('code', unit, {fontSize: 27 * unit, fontWeight: 560})}}>
                  {color}
                </div>
              </div>
            ))}
          </div>
          <div
            style={{
              ...textStyle('label', unit, {fontSize: 21 * unit}),
              display: 'flex',
              justifyContent: 'center',
              gap: 18 * unit,
              color: withAlpha(CARD_INK, 0.6),
            }}
          >
            <span>Both are {toHex(AS_RGB)}</span>
            <span>·</span>
            <span>sameColor() → {String(sameColor(AS_RGB, AS_HSL))}</span>
          </div>
        </div>

        <div style={{position: 'relative', display: 'flex', gap: tileGap}}>
          {ramp.map((color, i) => {
            const p = enter(frame, fps, {
              delay: Math.round(beat * 1.5) + i * 2,
              config: SPRING.snappy,
            });
            const active = Math.round(cursor) === i && readout > 0.5;
            return (
              <div
                key={color}
                style={{
                  width: tile,
                  height: tile * 1.3,
                  borderRadius: 18 * unit,
                  background: color,
                  transform: `translateY(${(1 - p) * 40 * unit}px) scale(${active ? 1.06 : 1})`,
                  opacity: p,
                  display: 'flex',
                  alignItems: 'flex-end',
                  justifyContent: 'center',
                  paddingBottom: 12 * unit,
                  ...textStyle('label', unit, {fontSize: 15 * unit, letterSpacing: '0.04em'}),
                  color: withAlpha(readableOn(color), 0.75),
                }}
              >
                L{14 + i * 9}
              </div>
            );
          })}
          <div
            style={{
              position: 'absolute',
              left: cursor * (tile + tileGap) - 7 * unit,
              top: -7 * unit,
              width: tile + 14 * unit,
              height: tile * 1.3 + 14 * unit,
              borderRadius: 24 * unit,
              border: `${3 * unit}px solid ${palette.text}`,
              opacity: readout,
            }}
          />
        </div>
      </div>
    </AbsoluteFill>
  );
};
