import {interpolateColors} from 'remotion';

/**
 * Color helpers that work in RGB and HSL.
 *
 * Any CSS color string goes in: hex, rgb()/rgba(), hsl()/hsla() and named colors.
 * Strings come out in the legacy comma syntax, `rgb(13, 13, 13)` and `hsl(0, 0%, 5%)`,
 * because that's what Remotion's interpolateColors() parses.
 *
 *   rgb(13, 13, 13) and hsl(0, 0%, 5%) are the same pixel: 5% of 255 is 12.75, which rounds to 13.
 */

export type RGBA = {r: number; g: number; b: number; a: number}; // channels 0–255, alpha 0–1
export type HSLA = {h: number; s: number; l: number; a: number}; // hue 0–360°, s and l 0–100

const clamp = (n: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, n));
const round = (n: number, digits = 0) => {
  const p = 10 ** digits;
  return Math.round(n * p) / p;
};
const wrapHue = (h: number) => ((h % 360) + 360) % 360;

/** `rgb(13, 13, 13)` or, when alpha < 1, `rgba(13, 13, 13, 0.5)`. */
export const rgb = (r: number, g: number, b: number, a = 1): string => {
  const [R, G, B] = [r, g, b].map((c) => round(clamp(c, 0, 255)));
  return a >= 1 ? `rgb(${R}, ${G}, ${B})` : `rgba(${R}, ${G}, ${B}, ${round(clamp(a, 0, 1), 3)})`;
};

/** `hsl(0, 0%, 5%)` or, when alpha < 1, `hsla(0, 0%, 5%, 0.5)`. */
export const hsl = (h: number, s: number, l: number, a = 1): string => {
  const H = round(wrapHue(h), 1);
  const S = round(clamp(s, 0, 100), 1);
  const L = round(clamp(l, 0, 100), 1);
  return a >= 1
    ? `hsl(${H}, ${S}%, ${L}%)`
    : `hsla(${H}, ${S}%, ${L}%, ${round(clamp(a, 0, 1), 3)})`;
};

export const hslToRgb = ({h, s, l, a}: HSLA): RGBA => {
  const S = s / 100;
  const L = l / 100;
  const k = (n: number) => (n + wrapHue(h) / 30) % 12;
  const f = (n: number) =>
    L - S * Math.min(L, 1 - L) * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1));
  return {r: f(0) * 255, g: f(8) * 255, b: f(4) * 255, a};
};

export const rgbToHsl = ({r, g, b, a}: RGBA): HSLA => {
  const R = r / 255;
  const G = g / 255;
  const B = b / 255;
  const max = Math.max(R, G, B);
  const min = Math.min(R, G, B);
  const d = max - min;
  const l = (max + min) / 2;
  if (d === 0) return {h: 0, s: 0, l: l * 100, a};
  const s = d / (1 - Math.abs(2 * l - 1));
  let h = max === R ? ((G - B) / d) % 6 : max === G ? (B - R) / d + 2 : (R - G) / d + 4;
  h = wrapHue(h * 60);
  return {h, s: s * 100, l: l * 100, a};
};

const parseHex = (hex: string): RGBA => {
  let h = hex.slice(1);
  if (h.length === 3 || h.length === 4) h = [...h].map((c) => c + c).join('');
  if (!/^[0-9a-f]{6}([0-9a-f]{2})?$/i.test(h)) throw new Error(`Invalid hex color: ${hex}`);
  const n = (i: number) => parseInt(h.slice(i, i + 2), 16);
  return {r: n(0), g: n(2), b: n(4), a: h.length === 8 ? n(6) / 255 : 1};
};

const parseAlpha = (v: string) =>
  clamp(v.endsWith('%') ? parseFloat(v) / 100 : parseFloat(v), 0, 1);

const parseHue = (v: string) => {
  const n = parseFloat(v);
  if (v.endsWith('turn')) return n * 360;
  if (v.endsWith('grad')) return n * 0.9;
  if (v.endsWith('rad')) return (n * 180) / Math.PI;
  return n; // plain numbers and `deg`
};

/** Parses any CSS color Remotion understands into RGBA. */
export const parseColor = (input: string): RGBA => {
  const str = input.trim().toLowerCase();
  if (str === 'transparent') return {r: 0, g: 0, b: 0, a: 0};
  if (str.startsWith('#')) return parseHex(str);

  const fn = /^(rgba?|hsla?)\((.+)\)$/.exec(str);
  if (fn) {
    const parts = fn[2].split(/[\s,/]+/).filter(Boolean);
    if (parts.length < 3 || parts.length > 4) throw new Error(`Invalid color: ${input}`);
    const a = parts[3] === undefined ? 1 : parseAlpha(parts[3]);
    if (fn[1].startsWith('rgb')) {
      const ch = (v: string) =>
        clamp(v.endsWith('%') ? parseFloat(v) * 2.55 : parseFloat(v), 0, 255);
      return {r: ch(parts[0]), g: ch(parts[1]), b: ch(parts[2]), a};
    }
    return hslToRgb({
      h: parseHue(parts[0]),
      s: clamp(parseFloat(parts[1]), 0, 100),
      l: clamp(parseFloat(parts[2]), 0, 100),
      a,
    });
  }

  // Named colors ("tomato") resolve through Remotion's own color table, which returns rgba().
  const resolved = interpolateColors(0, [0, 1], [str, str]);
  if (resolved === str) throw new Error(`Invalid color: ${input}`);
  return parseColor(resolved);
};

export const toRgb = (color: string) => {
  const {r, g, b, a} = parseColor(color);
  return rgb(r, g, b, a);
};

export const toHsl = (color: string) => {
  const {h, s, l, a} = rgbToHsl(parseColor(color));
  return hsl(h, s, l, a);
};

export const toHex = (color: string) => {
  const {r, g, b, a} = parseColor(color);
  const hex = (n: number) => Math.round(n).toString(16).padStart(2, '0');
  return `#${hex(r)}${hex(g)}${hex(b)}${a < 1 ? hex(a * 255) : ''}`.toUpperCase();
};

export const withAlpha = (color: string, alpha: number) => {
  const {r, g, b} = parseColor(color);
  return rgb(r, g, b, alpha);
};

/** Shifts hue, saturation and lightness by the given amounts: `adjust(c, {h: 40, l: -10})`. */
export const adjust = (color: string, {h = 0, s = 0, l = 0}: Partial<Omit<HSLA, 'a'>>) => {
  const c = rgbToHsl(parseColor(color));
  return hsl(c.h + h, c.s + s, c.l + l, c.a);
};

/** Replaces hue, saturation or lightness: `setHsl(accent, {l: 20})`. */
export const setHsl = (color: string, values: Partial<Omit<HSLA, 'a'>>) => {
  const c = {...rgbToHsl(parseColor(color)), ...values};
  return hsl(c.h, c.s, c.l, c.a);
};

/** Blends in RGB space, the same as interpolateColors(). Fine for fades and tints. */
export const mix = (a: string, b: string, t: number) =>
  toRgb(interpolateColors(clamp(t, 0, 1), [0, 1], [a, b]));

/** Blends around the hue wheel along the shortest path, so a hue sweep stays saturated instead of going grey. */
export const mixHsl = (a: string, b: string, t: number) => {
  const A = rgbToHsl(parseColor(a));
  const B = rgbToHsl(parseColor(b));
  const T = clamp(t, 0, 1);
  // A grey has no hue; borrow the other color's so the blend doesn't spin.
  const hA = A.s < 1 ? B.h : A.h;
  const hB = B.s < 1 ? A.h : B.h;
  const dh = ((hB - hA + 540) % 360) - 180;
  const lerp = (x: number, y: number) => x + (y - x) * T;
  return hsl(hA + dh * T, lerp(A.s, B.s), lerp(A.l, B.l), lerp(A.a, B.a));
};

/** WCAG relative luminance, 0 (black) to 1 (white). */
export const luminance = (color: string) => {
  const {r, g, b} = parseColor(color);
  const lin = (c: number) => {
    const v = c / 255;
    return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
};

/** WCAG contrast ratio, 1 to 21. Body text wants at least 4.5. */
export const contrastRatio = (a: string, b: string) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

/** Picks whichever of `dark` and `light` reads better on `background`. */
export const readableOn = (
  background: string,
  dark = 'rgb(13, 13, 13)',
  light = 'rgb(255, 255, 255)',
) => (contrastRatio(background, dark) >= contrastRatio(background, light) ? dark : light);

/** True when two colors render to the same 8-bit pixel, whatever notation they're written in. */
export const sameColor = (a: string, b: string) => {
  const A = parseColor(a);
  const B = parseColor(b);
  return (
    Math.round(A.r) === Math.round(B.r) &&
    Math.round(A.g) === Math.round(B.g) &&
    Math.round(A.b) === Math.round(B.b) &&
    Math.abs(A.a - B.a) < 0.005
  );
};
