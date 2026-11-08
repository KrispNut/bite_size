// A faithful port of the Flutter app's design system, so the phone screens in
// the app-accurate cut are built from the same tokens the app paints with.
//
//   lib/core/theme/app_colors.dart     -> palette / light-mode roles
//   lib/core/theme/activity_packs.dart -> PackPalette.seeded (ported exactly)
//   lib/core/theme/app_theme.dart      -> AppRadius / AppSpace / AppShadow / AppDecor
//   lib/core/theme/text_styles.dart    -> text styles, tracking + leading curves
import type React from 'react';
import {continueRender, delayRender, staticFile} from 'remotion';
import {loadFont as loadRoboto} from '@remotion/google-fonts/Roboto';
import {loadFont} from '@remotion/fonts';

// No fontFamily is set anywhere in the app, so Android draws it in Roboto.
// "Mono" styles are Roboto too, with tabular figures.
export const roboto = loadRoboto('normal', {
  weights: ['300', '400', '500', '600', '700', '800'],
  subsets: ['latin'],
}).fontFamily;

export const ICON_FONT = 'Material Icons Round';
const iconHandle = delayRender('Material Icons Round');
loadFont({family: ICON_FONT, url: staticFile('app/fonts/material-icons-round.woff2')})
  .then(() => continueRender(iconHandle))
  .catch((err) => {
    console.error(err);
    continueRender(iconHandle);
  });

// --- colour helpers --------------------------------------------------------
const hexToRgb01 = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
const toHex = (rgb: number[]) =>
  '#' + rgb.map((v) => Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16).padStart(2, '0')).join('').toUpperCase();

/** Color.alphaBlend(accent @ amount, base) — AppColors.tint(). */
export const tint = (accent: string, amount: number, base: string = '#FFFFFF') => {
  const a = hexToRgb01(accent);
  const b = hexToRgb01(base);
  return toHex(a.map((v, i) => v * amount + b[i] * (1 - amount)));
};

export const rgba = (hex: string, alpha: number) => {
  const [r, g, b] = hexToRgb01(hex).map((v) => Math.round(v * 255));
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

export const mixHex = (from: string, to: string, t: number) => {
  const a = hexToRgb01(from);
  const b = hexToRgb01(to);
  return toHex(a.map((v, i) => v + (b[i] - v) * t));
};

// --- PackPalette.seeded, ported -------------------------------------------
type HSL = {h: number; s: number; l: number};

const hslFromRgb = ([r, g, b]: number[]): HSL => {
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const d = max - min;
  let h = 0;
  if (d !== 0) {
    if (max === r) h = 60 * (((g - b) / d) % 6);
    else if (max === g) h = 60 * ((b - r) / d + 2);
    else h = 60 * ((r - g) / d + 4);
  }
  if (h < 0) h += 360;
  const l = (max + min) / 2;
  const s = l === 1 ? 0 : Math.min(1, Math.max(0, d / (1 - Math.abs(2 * l - 1))));
  return {h, s, l};
};

// HSLColor.toColor() rounds each channel to 8 bits.
const rgbFromHsl = ({h, s, l}: HSL) => {
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = l - c / 2;
  const [r, g, b] =
    h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
  return [r + m, g + m, b + m].map((v) => Math.round(v * 255) / 255);
};

const channel = (v: number) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
const luminance = ([r, g, b]: number[]) => 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);

/** PackPalette._at: seed hue, seed saturation × [saturation], at exact luminance. */
const at = (seed: string, target: number, saturation: number) => {
  const hsl = hslFromRgb(hexToRgb01(seed));
  const base = {h: hsl.h, s: Math.min(1, Math.max(0, hsl.s * saturation)), l: hsl.l};
  let lo = 0;
  let hi = 1;
  for (let i = 0; i < 24; i++) {
    const mid = (lo + hi) / 2;
    if (luminance(rgbFromHsl({...base, l: mid})) < target) lo = mid;
    else hi = mid;
  }
  return toHex(rgbFromHsl({...base, l: (lo + hi) / 2}));
};

export type PackPalette = {
  primary: string;
  primaryDark: string;
  primaryDeep: string;
  primarySoft: string;
  primaryFixed: string;
  accent: string;
  accentFill: string;
  accentSoft: string;
  onAccent: string;
  secondary: string;
};

export const seeded = (primary: string, accent: string): PackPalette => ({
  primary: at(primary, 0.09, 1.0),
  primaryDark: at(primary, 0.3, 0.9),
  primaryDeep: at(primary, 0.045, 1.0),
  primarySoft: at(primary, 0.88, 0.5),
  primaryFixed: at(primary, 0.45, 0.8),
  accent: at(accent, 0.11, 0.9),
  accentFill: at(accent, 0.3, 0.95),
  accentSoft: at(accent, 0.85, 0.9),
  onAccent: at(accent, 0.025, 0.85),
  secondary: at(primary, 0.45, 0.8),
});

// --- the packs (lib/core/theme/activity_packs.dart: Packs) -----------------
export type AppPack = {
  id: 'office_lunch' | 'ground_booking';
  activityName: string;
  unit: string;
  unitPlural: string;
  contribution: string;
  errand: string;
  runner: string;
  expense: string;
  expensePlural: string;
  attendingOnly: string;
  tagline: string;
  arrival: string;
  advisorName: string;
  modules: {roster: boolean; units: boolean; errand: boolean; advisor: boolean; ping: boolean; coverage: boolean};
  palette: PackPalette;
};

export const officeLunch: AppPack = {
  id: 'office_lunch',
  activityName: 'Bite Size',
  unit: 'roti',
  unitPlural: 'rotis',
  contribution: 'dish',
  errand: 'tandoor run',
  runner: 'runner',
  expense: 'shared meal',
  expensePlural: 'shared meals',
  attendingOnly: 'Eating only',
  tagline: 'OFFICE LUNCH LOGISTICS, SORTED BEFORE NOON',
  arrival: 'Food arrived',
  advisorName: 'Chef AI',
  modules: {roster: true, units: true, errand: true, advisor: true, ping: true, coverage: false},
  palette: seeded('#145C44', '#B5652B'),
};

export const groundBooking: AppPack = {
  id: 'ground_booking',
  activityName: 'Ground Booking',
  unit: 'hour',
  unitPlural: 'hours',
  contribution: 'gear',
  errand: 'ground booking',
  runner: 'payer',
  expense: 'shared cost',
  expensePlural: 'shared costs',
  attendingOnly: 'Taking part only',
  tagline: 'BOOK THE GROUND, SPLIT THE BILL',
  arrival: 'Ground booked',
  advisorName: 'Advisor',
  modules: {roster: false, units: true, errand: true, advisor: false, ping: false, coverage: false},
  palette: seeded('#1F3F80', '#A8792A'),
};

export const titleCase = (s: string) => (s ? s[0].toUpperCase() + s.slice(1) : s);

/** _PackOption._summary in pack_picker_sheet.dart. */
export const packSummary = (p: AppPack) => {
  const parts = [
    p.modules.roster ? p.contribution : null,
    p.modules.units ? p.unitPlural : null,
    p.modules.errand ? p.errand : null,
    p.modules.advisor ? p.advisorName : null,
  ].filter(Boolean);
  return `${parts.join(' · ')} · ${p.expensePlural}`;
};

// --- light-mode roles (AppColors getters with _dark == false) --------------
export const AC = {
  ink: '#1E293B',
  bg: '#F4FAFF', // grey25
  surface: '#FFFFFF',
  surfaceAlt: '#E7F6FF', // grey50
  surfaceDim: '#CBDDE7', // grey400
  border: '#CBD5E1',
  borderStrong: '#94A3B8',
  divider: '#D4E5EF', // grey300
  text: '#1E293B',
  textSecondary: '#3E4946',
  textTertiary: '#6E7976',
  white: '#FFFFFF',
  textOnBrandMuted: 'rgba(255, 255, 255, 0.75)',
  success: '#1F7A48',
  warning: '#B45309',
  danger: '#BA1A1A',
  info: '#0E7490',
  btnDisabled: '#DFF1FB', // grey100
  shadowLight: '#0F172A',
  scrim: 'rgba(0, 0, 0, 0.32)',
};

// --- AppSpace / AppRadius (standard shape, radiusScale 1) -----------------
export const SP = {xxs: 4, xs: 8, sm: 12, md: 16, lg: 20, xl: 24, xxl: 32, huge: 40};
export const RAD = {xs: 4, sm: 8, md: 12, lg: 16, xl: 24};
export const STROKE = 1;

// --- AppShadow (ShapeDepth.soft, light) ------------------------------------
export const SHADOW = {
  card: `0 4px 10px -1px ${rgba(AC.shadowLight, 0.07)}`,
  pressed: `0 1px 4px 0 ${rgba(AC.shadowLight, 0.03)}`,
  raised: `0 6px 16px -2px ${rgba(AC.shadowLight, 0.12)}`,
  overlay: `0 -4px 16px 0 ${rgba(AC.shadowLight, 0.12)}`,
};

// --- AppDecor --------------------------------------------------------------
export const decor = {
  card: (o: {color?: string; radius?: number; borderColor?: string; shadow?: boolean} = {}): React.CSSProperties => ({
    background: o.color ?? AC.surface,
    borderRadius: o.radius ?? RAD.md,
    border: `${STROKE}px solid ${o.borderColor ?? AC.border}`,
    boxShadow: o.shadow === false ? undefined : SHADOW.card,
    boxSizing: 'border-box',
  }),
  well: (radius: number = RAD.sm): React.CSSProperties => ({
    background: AC.surfaceAlt,
    borderRadius: radius,
    border: `${STROKE}px solid ${AC.border}`,
    boxSizing: 'border-box',
  }),
  tinted: (accent: string, o: {radius?: number; shadow?: boolean} = {}): React.CSSProperties => ({
    background: tint(accent, 0.12),
    borderRadius: o.radius ?? RAD.md,
    border: `${STROKE}px solid ${tint(accent, 0.35, AC.border)}`,
    boxShadow: o.shadow === false ? undefined : SHADOW.card,
    boxSizing: 'border-box',
  }),
  filled: (fill: string, o: {radius?: number; shadow?: boolean} = {}): React.CSSProperties => ({
    background: fill,
    borderRadius: o.radius ?? RAD.md,
    border: `${STROKE}px solid ${rgba(AC.ink, 0.15)}`,
    boxShadow: o.shadow === false ? undefined : SHADOW.card,
    boxSizing: 'border-box',
  }),
  pill: (accent: string, alpha = 0.22): React.CSSProperties => ({
    background: tint(accent, alpha),
    borderRadius: RAD.xs,
    border: `1px solid ${AC.ink}`,
    boxSizing: 'border-box',
  }),
};

// --- text_styles.dart ------------------------------------------------------
const trackingFor = (fs: number) =>
  fs >= 40 ? -1.6 : fs >= 28 ? -0.8 : fs >= 20 ? -0.4 : fs >= 16 ? -0.1 : fs <= 11 ? 0.3 : 0;
const leadingFor = (fs: number) => (fs >= 40 ? 1.02 : fs >= 28 ? 1.12 : fs >= 20 ? 1.22 : fs >= 16 ? 1.32 : 1.38);

type TS = React.CSSProperties;
const style = (fontSize: number, fontWeight: number, color: string, ls?: number, h?: number): TS => ({
  fontFamily: roboto,
  fontSize,
  fontWeight,
  color,
  letterSpacing: ls ?? trackingFor(fontSize),
  lineHeight: h ?? leadingFor(fontSize),
});

export const regular = (fs: number, color: string, ls?: number, h?: number) => style(fs, 400, color, ls, h);
export const medium = (fs: number, color: string, ls?: number, h?: number) => style(fs, 500, color, ls, h);
export const semiBold = (fs: number, color: string, ls?: number, h?: number) => style(fs, 600, color, ls, h);
export const bold = (fs: number, color: string, ls?: number, h?: number) => style(fs, 700, color, ls, h);
export const extraBold = (fs: number, color: string, ls?: number, h?: number) => style(fs, 800, color, ls, h);

/** getMonoStyle: Roboto, tabular figures, semibold by default. */
export const monoStyle = (o: {fontSize?: number; color?: string; weight?: number; ls?: number; h?: number} = {}): TS => ({
  fontFamily: roboto,
  fontSize: o.fontSize ?? 13,
  fontWeight: o.weight ?? 600,
  color: o.color ?? AC.text,
  letterSpacing: o.ls ?? 0.6,
  lineHeight: o.h ?? 1.1,
  fontVariantNumeric: 'tabular-nums',
});

export const AppText = {
  h2: extraBold(22, AC.text),
  h3: bold(17, AC.text),
  titleMd: semiBold(15, AC.text),
  titleSm: semiBold(13, AC.text),
  bodyLg: regular(15, AC.text),
  bodyMd: regular(13.5, AC.text),
  bodySm: regular(12.5, AC.textSecondary),
  label: semiBold(12.5, AC.textSecondary),
  caption: regular(11.5, AC.textTertiary),
  monoLabel: monoStyle({fontSize: 11, color: AC.textSecondary, ls: 1.2}),
};

/** Currency.format for PKR with decimals: false → "Rs 1,234". */
export const rs = (major: number) => `Rs ${Math.round(major).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
