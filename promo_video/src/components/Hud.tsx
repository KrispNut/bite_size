import React from 'react';
import {useCurrentFrame} from 'remotion';
import {T, timecode} from '../anim';
import {MonoLabel} from './Type';
import {c, mono} from '../theme';

// HUD tone per stretch of the film: light paper, emerald field, dark stage.
const toneAt = (f: number) => {
  if (f >= T.chat.wipeFull && f < 150) return 'rgba(255,255,255,0.72)';
  if (f >= 204 && f < 220) return 'rgba(255,255,255,0.72)';
  if (f >= T.packs.irisFull && f < T.end.irisFull) return c.darkTextSecondary;
  return c.textTertiary;
};

type Chapter = {from: number; label: string};

/** Chapter slug top-left, brand + running timecode top-right, as in the reference. */
export const Hud: React.FC<{
  chapters?: Chapter[];
  tone?: (f: number) => string;
  /** A soft plate behind the right-hand group, for when a phone runs under it. */
  backing?: (f: number) => string | undefined;
}> = ({chapters = T.chapters, tone = toneAt, backing}) => {
  const frame = useCurrentFrame();
  const chapter = [...chapters].reverse().find((ch) => frame >= ch.from) ?? chapters[0];
  const color = tone(frame);
  const plate = backing?.(frame);
  return (
    <>
      <div style={{position: 'absolute', left: 56, top: 40}}>
        <MonoLabel key={chapter.from} at={chapter.from} text={chapter.label} color={color} size={21} cps={2} />
      </div>
      <div
        style={{
          position: 'absolute',
          right: plate ? 44 : 56,
          top: plate ? 32 : 40,
          fontFamily: mono,
          fontSize: 21,
          color,
          display: 'flex',
          gap: 26,
          letterSpacing: '0.02em',
          zIndex: 200,
          ...(plate ? {background: plate, padding: '8px 12px', borderRadius: 10} : null),
        }}
      >
        <span>BITE SIZE</span>
        <span>{timecode(frame, T.fps)}</span>
      </div>
    </>
  );
};
