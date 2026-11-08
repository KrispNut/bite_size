import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {useLayout} from '../lib/layout';
import {tween} from '../lib/motion';
import type {Palette} from '../theme/schemes';
import {textStyle} from '../theme/typography';

/** SMPTE-style timecode, mm:ss:ff. */
export const timecode = (frame: number, fps: number) => {
  const pad = (n: number) => String(Math.floor(n)).padStart(2, '0');
  const seconds = Math.floor(frame / fps);
  return `${pad(seconds / 60)}:${pad(seconds % 60)}:${pad(frame % fps)}`;
};

/** A small overlay with the composition id, timecode, frame number and a progress line. */
export const Hud: React.FC<{palette: Palette}> = ({palette}) => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames, id} = useVideoConfig();
  const {unit, safe} = useLayout();
  const appear = tween(frame, [fps * 0.4, fps * 1.2]);

  return (
    <AbsoluteFill style={{pointerEvents: 'none'}}>
      <div
        style={{
          ...textStyle('label', unit, {fontSize: 17 * unit}),
          position: 'absolute',
          left: safe,
          right: safe,
          bottom: safe * 0.42,
          display: 'flex',
          justifyContent: 'space-between',
          color: palette.muted,
          opacity: appear * 0.75,
        }}
      >
        <span>{id}</span>
        <span>
          {timecode(frame, fps)} · F{String(frame).padStart(4, '0')}
        </span>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 0,
          bottom: 0,
          height: 4 * unit,
          width: `${(frame / Math.max(1, durationInFrames - 1)) * 100}%`,
          background: `linear-gradient(to right, ${palette.accent}, ${palette.accent2})`,
          opacity: appear,
        }}
      />
    </AbsoluteFill>
  );
};
