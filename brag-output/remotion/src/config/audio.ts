import {staticFile} from 'remotion';

/**
 * Tempo of public/audio/music-loop.wav. Its first downbeat is at 0s.
 * If you change it, regenerate the loop with `npm run audio -- --bpm <n>`.
 */
export const BPM = 120;
export const BEATS_PER_BAR = 4;

export const AUDIO = {
  music: staticFile('audio/music-loop.wav'),
  whoosh: staticFile('audio/whoosh.wav'),
  hit: staticFile('audio/hit.wav'),
} as const;

/** Lengths of the one-shot effects, used to size their <Sequence>s. */
export const SFX_SECONDS = {whoosh: 1.5, hit: 2.4} as const;

/** The whoosh peaks this many seconds after it starts. Start it this early to land on a cut. */
export const WHOOSH_PEAK_SECONDS = 0.32;
