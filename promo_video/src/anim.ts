import {Easing, interpolate} from 'remotion';
import T from './timeline.json';

export {T};

// Eases lifted from the reference's feel: fast-out entrances, symmetric
// camera moves, and a hard accelerate for whip pushes.
export const expoOut = Easing.bezier(0.16, 1, 0.3, 1);
export const quintOut = Easing.bezier(0.22, 1, 0.36, 1);
export const inOut = Easing.bezier(0.65, 0, 0.35, 1);
export const expoIn = Easing.bezier(0.7, 0, 0.84, 0);
export const backOut = Easing.bezier(0.34, 1.56, 0.64, 1);

/** 0→1 progress of a tween that starts at `start` and lasts `dur` frames. */
export const prog = (
  frame: number,
  start: number,
  dur: number,
  ease: (t: number) => number = expoOut,
) =>
  interpolate(frame, [start, start + dur], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: ease,
  });

export const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

export const clamp01 = (v: number) => Math.max(0, Math.min(1, v));

/** Damped punch: 0 at rest, peaks right after `start`, settles by `dur`. */
export const punch = (frame: number, start: number, dur = 14, amount = 1) => {
  const t = (frame - start) / dur;
  if (t < 0 || t > 1) return 0;
  return amount * Math.sin(t * Math.PI * 2.5) * Math.pow(1 - t, 2.2);
};

export const timecode = (frame: number, fps: number) => {
  const s = Math.floor(frame / fps);
  const f = frame % fps;
  const pad = (n: number) => n.toString().padStart(2, '0');
  return `00:00:${pad(s)}:${pad(f)}`;
};
