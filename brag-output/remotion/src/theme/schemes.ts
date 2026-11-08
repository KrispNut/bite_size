import {adjust, luminance, readableOn, withAlpha} from './colors';

/**
 * Color schemes. Write each value in whatever notation reads best, RGB or HSL.
 * Every helper in ./colors accepts both.
 */
type BaseScheme = {
  background: string;
  surface: string;
  text: string;
  muted: string;
};

export const SCHEMES = {
  midnight: {
    background: 'rgb(13, 13, 13)', // the same pixel as hsl(0, 0%, 5%)
    surface: 'hsl(0, 0%, 9%)',
    text: 'hsl(40, 23%, 95%)',
    muted: 'hsl(40, 6%, 62%)',
  },
  ocean: {
    background: 'hsl(224, 45%, 7%)',
    surface: 'hsl(224, 38%, 12%)',
    text: 'hsl(210, 40%, 96%)',
    muted: 'hsl(216, 18%, 66%)',
  },
  paper: {
    background: 'hsl(40, 30%, 95%)',
    surface: 'rgb(255, 255, 255)',
    text: 'rgb(13, 13, 13)',
    muted: 'hsl(30, 5%, 38%)',
  },
} satisfies Record<string, BaseScheme>;

export type SchemeName = keyof typeof SCHEMES;

export type Palette = BaseScheme & {
  isDark: boolean;
  line: string;
  accent: string;
  accent2: string;
  accent3: string;
  onAccent: string;
};

/** A scheme plus an accent. The two secondary accents are hue rotations of the main one. */
export const makePalette = (scheme: SchemeName, accent: string): Palette => {
  const base = SCHEMES[scheme];
  return {
    ...base,
    isDark: luminance(base.background) < 0.4,
    line: withAlpha(base.text, 0.12),
    accent,
    accent2: adjust(accent, {h: 48}),
    accent3: adjust(accent, {h: -72, l: 4}),
    onAccent: readableOn(accent),
  };
};
