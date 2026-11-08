import {useAudioData, visualizeAudio} from '@remotion/media-utils';
import {useMemo} from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {AnimatedText} from '../../../components/AnimatedText';
import {AUDIO, BEATS_PER_BAR, BPM} from '../../../config/audio';
import {useBeat} from '../../../lib/absolute-frame';
import {framesPerBeat} from '../../../lib/beat';
import {useLayout} from '../../../lib/layout';
import {SPRING, enter} from '../../../lib/motion';
import {mixHsl, withAlpha} from '../../../theme/colors';
import type {Palette} from '../../../theme/schemes';
import {textStyle} from '../../../theme/typography';

const BANDS = 24; // mirrored into 48 bars with the bass in the middle
const BARS = BANDS * 2;
const SAMPLES = 256;

// Spread the bands over the FFT bins on a roughly log scale, so bass and treble each get a
// fair share. Adding i keeps every band on its own bin.
const BIN_FOR_BAND = Array.from(
  {length: BANDS},
  (_, i) => 1 + i + Math.round(Math.pow(90, i / (BANDS - 1))),
);

// Magnitude to 0–1 on a decibel scale, tilted up a little so the quieter highs still move.
const level = (magnitude: number, band: number) =>
  Math.min(1, Math.max(0, (20 * Math.log10(Math.max(magnitude, 1e-6)) + 58 + band * 0.9) / 46));

export const Rhythm: React.FC<{palette: Palette}> = ({palette}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {unit, safe, isPortrait, width, height} = useLayout();
  const {frame: absolute, beatInBar, pulse} = useBeat(6);
  const beatLen = framesPerBeat(fps);

  // Remotion waits for the decoded audio before it renders this frame.
  const audioData = useAudioData(AUDIO.music);
  const spectrum = useMemo(() => {
    if (!audioData) return new Array<number>(BARS).fill(0);
    const loopFrames = Math.floor(audioData.durationInSeconds * fps);
    const bins = visualizeAudio({
      audioData,
      fps,
      frame: absolute % loopFrames,
      numberOfSamples: SAMPLES,
      optimizeFor: 'speed',
    });
    const bands = BIN_FOR_BAND.map((bin, i) => level(bins[bin], i));
    return Array.from(
      {length: BARS},
      (_, k) => bands[Math.round(Math.abs(k - (BARS - 1) / 2) - 0.5)],
    );
  }, [audioData, absolute, fps]);

  const colors = useMemo(
    () =>
      Array.from({length: BARS}, (_, i) => {
        const t = i / (BARS - 1);
        return t < 0.5
          ? mixHsl(palette.accent3, palette.accent, t * 2)
          : mixHsl(palette.accent, palette.accent2, t * 2 - 1);
      }),
    [palette],
  );

  const fieldWidth = width - safe * 2;
  const fieldHeight = isPortrait ? height * 0.34 : height * 0.36;
  const slot = fieldWidth / BARS;
  const counterIn = enter(frame, fps, {delay: Math.round(beatLen)});
  const dot = 84 * unit;

  return (
    <AbsoluteFill style={{padding: safe}}>
      <div
        style={{
          display: 'flex',
          flexDirection: isPortrait ? 'column' : 'row',
          justifyContent: 'space-between',
          alignItems: isPortrait ? 'flex-start' : 'flex-end',
          gap: 48 * unit,
        }}
      >
        <div style={{display: 'flex', flexDirection: 'column', gap: 28 * unit}}>
          <AnimatedText
            text={'Locked to\nthe beat.'}
            stagger={Math.round(beatLen / 4)}
            style={{...textStyle('heading', unit), color: palette.text}}
          />
          <div style={{...textStyle('label', unit), color: palette.muted, opacity: counterIn}}>
            {BPM} BPM · {Number(beatLen.toFixed(2))} frames per beat · {fps} fps
          </div>
        </div>
        <div style={{display: 'flex', gap: 18 * unit, opacity: counterIn}}>
          {Array.from({length: BEATS_PER_BAR}, (_, i) => {
            const active = i === beatInBar;
            const p = enter(frame, fps, {
              delay: Math.round(beatLen + i * 3),
              config: SPRING.bouncy,
            });
            return (
              <div
                key={i}
                style={{
                  width: dot,
                  height: dot,
                  borderRadius: '50%',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  ...textStyle('code', unit, {fontSize: 32 * unit, fontWeight: 650}),
                  color: active ? palette.onAccent : palette.muted,
                  background: active ? palette.accent : 'transparent',
                  border: `${2 * unit}px solid ${active ? palette.accent : palette.line}`,
                  boxShadow: active
                    ? `0 0 ${50 * unit * pulse}px ${withAlpha(palette.accent, 0.7)}`
                    : undefined,
                  transform: `scale(${p * (active ? 1 + 0.18 * pulse : 1)})`,
                }}
              >
                {i + 1}
              </div>
            );
          })}
        </div>
      </div>

      <div style={{flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <div style={{position: 'relative', width: fieldWidth, height: fieldHeight}}>
          <div
            style={{
              position: 'absolute',
              left: 0,
              right: 0,
              top: fieldHeight / 2,
              height: 1.5 * unit,
              background: palette.line,
            }}
          />
          {spectrum.map((v, i) => {
            const grow = enter(frame, fps, {
              delay: Math.abs(i - BARS / 2) * 0.6,
              durationInFrames: Math.round(beatLen * 2),
            });
            const h = Math.max(slot * 0.55, v * fieldHeight * grow);
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: i * slot + slot * 0.2,
                  width: slot * 0.6,
                  top: (fieldHeight - h) / 2,
                  height: h,
                  borderRadius: slot,
                  background: colors[i],
                  boxShadow: `0 0 ${24 * unit * v}px ${withAlpha(colors[i], 0.5)}`,
                }}
              />
            );
          })}
        </div>
      </div>
    </AbsoluteFill>
  );
};
