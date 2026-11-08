import {BEATS_PER_BAR, BPM} from '../config/audio';

/** 15 at 30fps and 120 BPM. Never hard-code it: it changes with fps and tempo. */
export const framesPerBeat = (fps: number, bpm = BPM) => (fps * 60) / bpm;

export const beatToFrame = (beat: number, fps: number, bpm = BPM) =>
  Math.round(beat * framesPerBeat(fps, bpm));

export const barToFrame = (bar: number, fps: number, bpm = BPM) =>
  beatToFrame(bar * BEATS_PER_BAR, fps, bpm);

export const frameToBeat = (frame: number, fps: number, bpm = BPM) =>
  frame / framesPerBeat(fps, bpm);

/** 1 on every beat, decaying toward 0 before the next one. Use it for pulses and flashes. */
export const beatPulse = (frame: number, fps: number, decay = 5, bpm = BPM) => {
  const beat = frameToBeat(frame, fps, bpm);
  return Math.exp(-(beat - Math.floor(beat)) * decay);
};
