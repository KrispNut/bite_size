import {loadFont as loadGeist} from '@remotion/google-fonts/Geist';
import {loadFont as loadGeistMono} from '@remotion/google-fonts/GeistMono';
import {loadFont as loadInstrumentSerif} from '@remotion/google-fonts/InstrumentSerif';

// Typography mirrors the reference: a geometric grotesk for statements, an
// italic display serif for the single emphasised word, and a mono for the
// "// code-comment" micro labels and every figure.
export const sans = loadGeist('normal', {
  weights: ['400', '500', '600', '700'],
  subsets: ['latin'],
}).fontFamily;
export const mono = loadGeistMono('normal', {
  weights: ['400', '500', '600'],
  subsets: ['latin'],
}).fontFamily;
export const serif = loadInstrumentSerif('italic', {
  weights: ['400'],
  subsets: ['latin'],
}).fontFamily;

// --- lib/core/theme/app_colors.dart --------------------------------------
// Values copied verbatim from _Palette / AppColors (light + dark getters).
export const palette = {
  ink: '#1E293B',
  grey0: '#FFFFFF',
  grey25: '#F4FAFF',
  grey50: '#E7F6FF',
  grey100: '#DFF1FB',
  grey200: '#D9EBF5',
  grey300: '#D4E5EF',
  grey400: '#CBDDE7',
  grey500: '#6E7976',
  grey600: '#3E4946',
  navy900: '#18181B',
  navy800: '#27272A',
  navy700: '#3F3F46',
  navy600: '#52525B',
  success: '#1F7A48',
  warning: '#B45309',
  danger: '#BA1A1A',
  info: '#0E7490',
  // Pack seeds: "the single source of truth".
  biteSizePrimary: '#145C44', // emerald
  biteSizeAccent: '#B5652B', // terracotta copper
  groundPrimary: '#1F3F80', // royal navy
  groundAccent: '#A8792A', // antique gold
  shadowLight: '#0F172A',
} as const;

// Semantic roles, resolved the way AppColors resolves them in light mode
// (and dark mode for the pack scene).
export const c = {
  bg: palette.grey25, // AppColors.bgColor
  surface: palette.grey0, // AppColors.surface
  surfaceAlt: palette.grey50, // AppColors.surfaceAlt
  surfacePale: palette.grey200,
  divider: palette.grey300,
  text: palette.ink, // AppColors.textColor
  textSecondary: palette.grey600,
  textTertiary: palette.grey500,
  border: '#CBD5E1', // AppColors.border (light)
  borderStrong: '#94A3B8',
  // dark
  darkBg: palette.navy900,
  darkSurface: palette.navy800,
  darkText: '#F4F4F5',
  darkTextSecondary: '#A1A1AA',
  darkTextTertiary: '#71717A',
  darkBorder: '#3F3F46',
};

export type Pack = {
  id: 'lunch' | 'ground';
  name: string;
  primary: string;
  accent: string;
};

export const lunchPack: Pack = {
  id: 'lunch',
  name: 'Office Lunch',
  primary: palette.biteSizePrimary,
  accent: palette.biteSizeAccent,
};

export const groundPack: Pack = {
  id: 'ground',
  name: 'Cricket Ground',
  primary: palette.groundPrimary,
  accent: palette.groundAccent,
};

const hexToRgb = (hex: string): [number, number, number] => {
  const h = hex.replace('#', '');
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
};

const toHex = (rgb: number[]) =>
  '#' +
  rgb
    .map((v) =>
      Math.round(Math.max(0, Math.min(255, v)))
        .toString(16)
        .padStart(2, '0'),
    )
    .join('');

// AppColors.tint(): alphaBlend(accent @ amount) over a base (surface by default).
export const tint = (accent: string, amount: number, base: string = c.surface) => {
  const a = hexToRgb(accent);
  const b = hexToRgb(base);
  return toHex(a.map((v, i) => v * amount + b[i] * (1 - amount)));
};

// Linear blend between two colours, used for the pack theme morph.
export const mix = (from: string, to: string, t: number) => {
  const a = hexToRgb(from);
  const b = hexToRgb(to);
  return toHex(a.map((v, i) => v + (b[i] - v) * t));
};

export const withAlpha = (hex: string, alpha: number) => {
  const [r, g, b] = hexToRgb(hex);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

export const rs = (n: number) => {
  const sign = n < 0 ? '−' : '';
  const abs = Math.abs(Math.round(n));
  return `${sign}Rs ${abs.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
};
