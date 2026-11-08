import {loadFont} from '@remotion/fonts';
import type {CSSProperties} from 'react';
import {staticFile} from 'remotion';

/**
 * Two variable fonts ship in public/fonts (both OFL): Inter for everything you read and
 * JetBrains Mono for labels, numbers and code. Both are loaded once, here. Remotion
 * holds every frame until they're ready, so text never flashes in a fallback font.
 */
loadFont({family: 'Inter', url: staticFile('fonts/Inter-Variable.woff2'), weight: '100 900'});
loadFont({
  family: 'JetBrains Mono',
  url: staticFile('fonts/JetBrainsMono-Variable.woff2'),
  weight: '100 800',
});

export const fonts = {
  sans: '"Inter", "Segoe UI", system-ui, sans-serif',
  mono: '"JetBrains Mono", "Cascadia Mono", ui-monospace, monospace',
} as const;

/**
 * Type scale in px for a 1080px short edge. Multiply by `unit` from useLayout() so the
 * same design holds in 1920×1080, 1080×1920 and 4K.
 * Big type gets tighter tracking and line height. Small caps labels get looser.
 */
export const TYPE = {
  display: {fontSize: 156, fontWeight: 740, letterSpacing: '-0.048em', lineHeight: 0.96},
  title: {fontSize: 108, fontWeight: 700, letterSpacing: '-0.04em', lineHeight: 1},
  heading: {fontSize: 80, fontWeight: 680, letterSpacing: '-0.032em', lineHeight: 1.02},
  body: {fontSize: 34, fontWeight: 430, letterSpacing: '-0.012em', lineHeight: 1.42},
  label: {fontSize: 22, fontWeight: 520, letterSpacing: '0.14em', lineHeight: 1.2},
  code: {fontSize: 28, fontWeight: 460, letterSpacing: '-0.01em', lineHeight: 1.3},
} as const;

export type TypeRole = keyof typeof TYPE;

/** Fills text with a gradient. Works on inline-block spans, including AnimatedText highlights. */
export const gradientText = (from: string, to: string, angle = 100): CSSProperties => ({
  backgroundImage: `linear-gradient(${angle}deg, ${from}, ${to})`,
  WebkitBackgroundClip: 'text',
  backgroundClip: 'text',
  WebkitTextFillColor: 'transparent',
  color: 'transparent',
});

const MONO_ROLES: TypeRole[] = ['label', 'code'];

export const textStyle = (
  role: TypeRole,
  unit: number,
  overrides: CSSProperties = {},
): CSSProperties => {
  const t = TYPE[role];
  return {
    fontFamily: MONO_ROLES.includes(role) ? fonts.mono : fonts.sans,
    fontSize: t.fontSize * unit,
    fontWeight: t.fontWeight,
    letterSpacing: t.letterSpacing,
    lineHeight: t.lineHeight,
    textTransform: role === 'label' ? 'uppercase' : undefined,
    // Tabular figures keep counters from jittering. cv11 is Inter's single-storey "a".
    fontFeatureSettings: MONO_ROLES.includes(role) ? '"zero"' : '"tnum", "cv11"',
    textWrap: 'balance',
    margin: 0,
    ...overrides,
  };
};
