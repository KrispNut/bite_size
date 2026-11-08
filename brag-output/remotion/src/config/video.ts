import type {CalculateMetadataFunction} from 'remotion';
import {z} from 'zod';

/**
 * Resolution, frame rate and duration are props on every composition:
 *   format             one of the keys below
 *   fps                frames per second
 *   durationInSeconds  length of the video
 *
 * Set them in each <Composition>'s defaultProps in src/Root.tsx, edit them live in the
 * Studio's props panel (Save writes them back to Root.tsx), or override them for one
 * render with --props. Add or change resolutions here.
 */
export const FORMATS = {
  landscape: {width: 1920, height: 1080},
  portrait: {width: 1080, height: 1920},
  square: {width: 1080, height: 1080},
} as const;

export type Format = keyof typeof FORMATS;

export const videoSchema = z.object({
  format: z.enum(['landscape', 'portrait', 'square']),
  fps: z.number().int().min(1).max(120),
  durationInSeconds: z.number().min(5).max(600),
});

export type VideoProps = z.infer<typeof videoSchema>;

/**
 * Turns the props above into width, height, fps and durationInFrames.
 * Pass it as `calculateMetadata` on any <Composition> whose schema extends videoSchema.
 */
export const calculateVideoMetadata = <T extends VideoProps>({
  props,
}: Parameters<CalculateMetadataFunction<T>>[0]) => ({
  ...FORMATS[props.format],
  fps: props.fps,
  durationInFrames: Math.max(1, Math.round(props.durationInSeconds * props.fps)),
});
