import {zColor} from '@remotion/zod-types';
import {z} from 'zod';
import {videoSchema} from '../../config/video';

// Every field shows up as a control in the Studio's props panel.
export const showcaseSchema = videoSchema.extend({
  title: z.string(),
  scheme: z.enum(['midnight', 'ocean', 'paper']),
  accent: zColor(),
  hud: z.boolean(),
});

export type ShowcaseProps = z.infer<typeof showcaseSchema>;
