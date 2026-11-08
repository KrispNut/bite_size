import {framesPerBeat} from '../../lib/beat';

/**
 * One source of truth for when things happen. Scene lengths are weights, so the video
 * stretches to any duration. Every cut lands on a beat of the music, and the sound effects
 * read their cue frames from here too.
 */
export const SCENE_WEIGHTS = {intro: 3, shapes: 3, colors: 4, rhythm: 3, outro: 3} as const;
export type SceneId = keyof typeof SCENE_WEIGHTS;
export const SCENE_IDS = Object.keys(SCENE_WEIGHTS) as SceneId[];

/** Each transition lasts one beat. */
export const TRANSITION_BEATS = 1;

export type Timeline = {
  framesPerBeat: number;
  transitionFrames: number;
  /** `from` is the absolute frame where the scene takes over. `durationInFrames` includes
   * the transition out of it, which is how <TransitionSeries> counts. */
  scenes: Record<SceneId, {from: number; durationInFrames: number}>;
  /** Absolute frames where each transition starts. */
  cuts: number[];
};

export const makeTimeline = (fps: number, durationInFrames: number): Timeline => {
  const fpb = framesPerBeat(fps);
  const transitionFrames = Math.max(1, Math.round(TRANSITION_BEATS * fpb));
  const totalWeight = SCENE_IDS.reduce((sum, id) => sum + SCENE_WEIGHTS[id], 0);
  const totalBeats = durationInFrames / fpb;

  let weightSoFar = 0;
  const starts = SCENE_IDS.map((id) => {
    const beat = Math.round((weightSoFar / totalWeight) * totalBeats);
    weightSoFar += SCENE_WEIGHTS[id];
    return Math.round(beat * fpb);
  });

  const scenes = {} as Timeline['scenes'];
  SCENE_IDS.forEach((id, i) => {
    const isLast = i === SCENE_IDS.length - 1;
    const end = isLast ? durationInFrames : starts[i + 1];
    scenes[id] = {
      from: starts[i],
      durationInFrames: end - starts[i] + (isLast ? 0 : transitionFrames),
    };
  });

  return {framesPerBeat: fpb, transitionFrames, scenes, cuts: starts.slice(1)};
};
