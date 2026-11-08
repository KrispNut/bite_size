import {Easing, interpolate, spring, type SpringConfig} from 'remotion';

/** Easing curves. Entrances ease out, exits ease in, moves and morphs ease in and out. */
export const EASE = {
  out: Easing.bezier(0.16, 1, 0.3, 1),
  in: Easing.bezier(0.7, 0, 0.84, 0),
  inOut: Easing.bezier(0.65, 0, 0.35, 1),
  overshoot: Easing.bezier(0.34, 1.56, 0.64, 1),
} as const;

/** Spring presets. `smooth` never overshoots and suits text; `bouncy` suits shapes and logos. */
export const SPRING = {
  smooth: {damping: 200},
  snappy: {damping: 22, stiffness: 210, mass: 0.6},
  bouncy: {damping: 10, stiffness: 120, mass: 0.7},
} satisfies Record<string, Partial<SpringConfig>>;

/** A spring that goes from 0 to 1, starting `delay` frames in. */
export const enter = (
  frame: number,
  fps: number,
  {
    delay = 0,
    config = SPRING.smooth,
    durationInFrames,
  }: {delay?: number; config?: Partial<SpringConfig>; durationInFrames?: number} = {},
) => spring({frame: frame - delay, fps, config, durationInFrames});

/** Maps `frame` from [start, end] onto [from, to] with easing, clamped at both ends. */
export const tween = (
  frame: number,
  [start, end]: [number, number],
  [from, to]: [number, number] = [0, 1],
  easing: (t: number) => number = EASE.out,
) =>
  interpolate(frame, [start, end], [from, to], {
    easing,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
