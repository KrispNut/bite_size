import {useVideoConfig} from 'remotion';

export type Orientation = 'landscape' | 'portrait' | 'square';

/**
 * Size everything from `unit` (1 at a 1080px short edge) so one design scales to any
 * resolution, and branch on `orientation` when the layout itself should change.
 */
export const useLayout = () => {
  const {width, height} = useVideoConfig();
  const unit = Math.min(width, height) / 1080;
  const orientation: Orientation =
    width > height ? 'landscape' : width < height ? 'portrait' : 'square';
  // Title-safe margin: keep text at least this far from every edge.
  const safe = Math.round((orientation === 'landscape' ? 120 : 88) * unit);
  return {width, height, unit, orientation, isPortrait: orientation === 'portrait', safe};
};
