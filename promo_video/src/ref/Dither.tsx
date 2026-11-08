// 1-bit ordered dithering — the reference film's art style. A source (the
// app's 3D mascot, an illustration, or a procedural drawing) is posed,
// downsampled to the dither grid, tone-mapped, thresholded against an 8×8
// Bayer matrix and scaled back up as hard square pixels. Posing happens
// *before* dithering, so the screen stays fixed and the pattern crawls as
// the subject moves, exactly like the reference.
import React, {useEffect, useLayoutEffect, useRef, useState} from 'react';
import {continueRender, delayRender, staticFile} from 'remotion';

const BAYER8 = [
  [0, 48, 12, 60, 3, 51, 15, 63],
  [32, 16, 44, 28, 35, 19, 47, 31],
  [8, 56, 4, 52, 11, 59, 7, 55],
  [40, 24, 36, 20, 43, 27, 39, 23],
  [2, 50, 14, 62, 1, 49, 13, 61],
  [34, 18, 46, 30, 33, 17, 45, 29],
  [10, 58, 6, 54, 9, 57, 5, 53],
  [42, 26, 38, 22, 41, 25, 37, 21],
];

const images: Record<string, Promise<HTMLImageElement>> = {};
const loadImage = (src: string) => {
  images[src] ??= new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = staticFile(src);
  });
  return images[src];
};

export type Pose = {
  x?: number; // px, in the component's own space
  y?: number;
  rotate?: number; // deg
  scale?: number;
  scaleX?: number;
  scaleY?: number;
};

export type Tone = {
  black?: number; // luminance mapped to solid ink
  white?: number; // luminance mapped to bare paper
  gamma?: number;
};

const hexRgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));

export const Dither: React.FC<{
  src?: string;
  draw?: (ctx: CanvasRenderingContext2D, w: number, h: number) => void;
  width: number;
  height: number;
  pixel?: number;
  /** Size of the source as a fraction of the box (contain-fit, centred). */
  fit?: number;
  /** Where the source's centre sits, as a fraction of the box. */
  anchor?: {x: number; y: number};
  pose?: Pose;
  tone?: Tone;
  /** Canvas filter applied while drawing the source, e.g. 'contrast(1.3)'. */
  filter?: string;
  /** Channel weights for the grey conversion — a 'colour filter', as in B&W photography. */
  weights?: [number, number, number];
  /** Unsharp mask on the dither grid before thresholding. */
  sharpen?: {radius: number; amount: number};
  ink?: string;
  paper?: string;
  style?: React.CSSProperties;
}> = ({
  src,
  draw,
  width,
  height,
  pixel = 5,
  fit = 1,
  anchor = {x: 0.5, y: 0.5},
  pose = {},
  tone = {},
  filter = 'none',
  weights = [0.2126, 0.7152, 0.0722],
  sharpen,
  ink = '#0F172A',
  paper = '#FFFFFF',
  style,
}) => {
  const canvas = useRef<HTMLCanvasElement>(null);
  const work = useRef<HTMLCanvasElement | null>(null);
  const [img, setImg] = useState<HTMLImageElement | null>(null);
  const [handle] = useState(() => (src ? delayRender(`dither:${src}`) : null));

  useEffect(() => {
    if (!src || handle === null) return;
    loadImage(src)
      .then((i) => {
        setImg(i);
        continueRender(handle);
      })
      .catch((e) => {
        console.error(e);
        continueRender(handle);
      });
  }, [src, handle]);

  const cols = Math.ceil(width / pixel);
  const rows = Math.ceil(height / pixel);

  useLayoutEffect(() => {
    const out = canvas.current;
    if (!out) return;
    if (src && !img) return;
    work.current ??= document.createElement('canvas');
    const w = work.current;
    w.width = cols;
    w.height = rows;
    const ctx = w.getContext('2d', {willReadFrequently: true})!;
    ctx.clearRect(0, 0, cols, rows);
    ctx.imageSmoothingEnabled = true;
    ctx.imageSmoothingQuality = 'high';

    // Pose, in grid units.
    const k = 1 / pixel;
    ctx.save();
    ctx.filter = filter;
    ctx.translate((anchor.x * width + (pose.x ?? 0)) * k, (anchor.y * height + (pose.y ?? 0)) * k);
    ctx.rotate(((pose.rotate ?? 0) * Math.PI) / 180);
    const s = pose.scale ?? 1;
    ctx.scale(s * (pose.scaleX ?? 1), s * (pose.scaleY ?? 1));
    if (img) {
      const box = Math.min(width, height) * fit * k;
      const ar = img.naturalWidth / img.naturalHeight;
      const dw = ar >= 1 ? box : box * ar;
      const dh = ar >= 1 ? box / ar : box;
      ctx.drawImage(img, -dw / 2, -dh / 2, dw, dh);
    } else if (draw) {
      const box = Math.min(width, height) * fit * k;
      ctx.translate(-box / 2, -box / 2);
      draw(ctx, box, box);
    }
    ctx.restore();

    const data = ctx.getImageData(0, 0, cols, rows);
    const px = data.data;
    const black = tone.black ?? 0.12;
    const white = tone.white ?? 0.85;
    const gamma = tone.gamma ?? 1;
    const [ir, ig, ib] = hexRgb(ink);
    const [pr, pg, pb] = hexRgb(paper);

    // Grey, through the colour filter. Transparent cells read as paper.
    const n = cols * rows;
    const lum = new Float32Array(n);
    for (let j = 0; j < n; j++) {
      const i = j * 4;
      lum[j] = px[i + 3] < 128 ? 1 : (weights[0] * px[i] + weights[1] * px[i + 1] + weights[2] * px[i + 2]) / 255;
    }
    // Unsharp mask: lift local contrast so small features (eyes, teeth, the
    // nose) survive the drop to one bit instead of melting into the fur.
    const sharp = lum.slice();
    if (sharpen && sharpen.amount > 0) {
      const r = Math.max(1, Math.round(sharpen.radius));
      const tmp = new Float32Array(n);
      const blur = new Float32Array(n);
      for (let y = 0; y < rows; y++) {
        let acc = 0;
        for (let x = -r; x <= r; x++) acc += lum[y * cols + Math.min(cols - 1, Math.max(0, x))];
        for (let x = 0; x < cols; x++) {
          tmp[y * cols + x] = acc / (2 * r + 1);
          acc += lum[y * cols + Math.min(cols - 1, x + r + 1)] - lum[y * cols + Math.max(0, x - r)];
        }
      }
      for (let x = 0; x < cols; x++) {
        let acc = 0;
        for (let y = -r; y <= r; y++) acc += tmp[Math.min(rows - 1, Math.max(0, y)) * cols + x];
        for (let y = 0; y < rows; y++) {
          blur[y * cols + x] = acc / (2 * r + 1);
          acc += tmp[Math.min(rows - 1, y + r + 1) * cols + x] - tmp[Math.max(0, y - r) * cols + x];
        }
      }
      for (let j = 0; j < n; j++) sharp[j] = lum[j] + sharpen.amount * (lum[j] - blur[j]);
    }

    for (let y = 0; y < rows; y++) {
      for (let x = 0; x < cols; x++) {
        const i = (y * cols + x) * 4;
        const a = px[i + 3] / 255;
        if (a < 0.5) {
          px[i + 3] = 0;
          continue;
        }
        const l = sharp[y * cols + x];
        const t = Math.pow(Math.min(1, Math.max(0, (l - black) / (white - black))), gamma);
        const threshold = (BAYER8[y % 8][x % 8] + 0.5) / 64;
        const on = t > threshold;
        px[i] = on ? pr : ir;
        px[i + 1] = on ? pg : ig;
        px[i + 2] = on ? pb : ib;
        px[i + 3] = 255;
      }
    }
    out.width = cols;
    out.height = rows;
    out.getContext('2d')!.putImageData(data, 0, 0);
  });

  return (
    <canvas
      ref={canvas}
      style={{
        width: cols * pixel,
        height: rows * pixel,
        imageRendering: 'pixelated',
        display: 'block',
        ...style,
      }}
    />
  );
};

/** A cricket ball, lit from the top left, drawn for the dither to chew on. */
export const drawCricketBall = (ctx: CanvasRenderingContext2D, w: number, h: number) => {
  const r = Math.min(w, h) * 0.42;
  const cx = w / 2;
  const cy = h / 2;
  const g = ctx.createRadialGradient(cx - r * 0.38, cy - r * 0.42, r * 0.08, cx, cy, r);
  g.addColorStop(0, '#FFFFFF');
  g.addColorStop(0.35, '#B9B9B9');
  g.addColorStop(0.8, '#3C3C3C');
  g.addColorStop(1, '#151515');
  ctx.fillStyle = g;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fill();
  // The seam: two stitched curves across the ball.
  ctx.strokeStyle = '#F2F2F2';
  ctx.lineWidth = r * 0.06;
  for (const off of [-0.09, 0.09]) {
    ctx.beginPath();
    ctx.ellipse(cx + r * off, cy, r * 0.3, r * 0.98, -0.5, -Math.PI / 2, Math.PI / 2);
    ctx.stroke();
  }
  ctx.strokeStyle = '#111111';
  ctx.lineWidth = r * 0.03;
  for (let i = -6; i <= 6; i++) {
    const a = (i / 7) * (Math.PI / 2);
    const x = cx + r * 0.3 * Math.cos(a) * Math.cos(-0.5) - r * 0.98 * Math.sin(a) * Math.sin(-0.5);
    const y = cy + r * 0.3 * Math.cos(a) * Math.sin(-0.5) + r * 0.98 * Math.sin(a) * Math.cos(-0.5);
    ctx.beginPath();
    ctx.moveTo(x - r * 0.07, y);
    ctx.lineTo(x + r * 0.07, y);
    ctx.stroke();
  }
  // Floor shadow.
  ctx.fillStyle = 'rgba(0,0,0,0.35)';
  ctx.beginPath();
  ctx.ellipse(cx + r * 0.1, cy + r * 1.08, r * 0.8, r * 0.12, 0, 0, Math.PI * 2);
  ctx.fill();
};

/** A bowl of salan with a roti leaning on it, lit from the top left. */
export const drawSalanBowl = (ctx: CanvasRenderingContext2D, w: number, h: number) => {
  const cx = w / 2;
  const cy = h * 0.55;
  const rx = w * 0.4;
  const ry = h * 0.12;
  // Shadow.
  ctx.fillStyle = 'rgba(0,0,0,0.35)';
  ctx.beginPath();
  ctx.ellipse(cx + w * 0.04, cy + h * 0.33, rx * 0.85, ry * 0.6, 0, 0, Math.PI * 2);
  ctx.fill();
  // Bowl body.
  const body = ctx.createLinearGradient(cx - rx, 0, cx + rx, 0);
  body.addColorStop(0, '#F4F4F4');
  body.addColorStop(0.45, '#BDBDBD');
  body.addColorStop(1, '#2A2A2A');
  ctx.fillStyle = body;
  ctx.beginPath();
  ctx.moveTo(cx - rx, cy);
  ctx.bezierCurveTo(cx - rx, cy + h * 0.32, cx + rx, cy + h * 0.32, cx + rx, cy);
  ctx.closePath();
  ctx.fill();
  // Curry surface.
  const curry = ctx.createRadialGradient(cx - rx * 0.3, cy - ry * 0.3, 2, cx, cy, rx);
  curry.addColorStop(0, '#9A9A9A');
  curry.addColorStop(1, '#3A3A3A');
  ctx.fillStyle = curry;
  ctx.beginPath();
  ctx.ellipse(cx, cy, rx * 0.92, ry * 0.8, 0, 0, Math.PI * 2);
  ctx.fill();
  // Rim.
  ctx.strokeStyle = '#FFFFFF';
  ctx.lineWidth = h * 0.025;
  ctx.beginPath();
  ctx.ellipse(cx, cy, rx, ry, 0, 0, Math.PI * 2);
  ctx.stroke();
  // Chunks and a few highlights.
  for (const [dx, dy, r] of [[-0.35, -0.1, 0.07], [0.1, 0.15, 0.08], [0.4, -0.05, 0.06], [-0.05, -0.35, 0.05]]) {
    ctx.fillStyle = '#E8E8E8';
    ctx.beginPath();
    ctx.ellipse(cx + dx * rx, cy + dy * ry * 2, r * w * 0.5, r * w * 0.3, 0, 0, Math.PI * 2);
    ctx.fill();
  }
  // Steam.
  ctx.strokeStyle = '#7A7A7A';
  ctx.lineWidth = h * 0.03;
  ctx.lineCap = 'round';
  for (const dx of [-0.18, 0.05, 0.28]) {
    ctx.beginPath();
    ctx.moveTo(cx + dx * w, cy - h * 0.14);
    ctx.bezierCurveTo(cx + dx * w - w * 0.06, cy - h * 0.24, cx + dx * w + w * 0.06, cy - h * 0.3, cx + dx * w, cy - h * 0.42);
    ctx.stroke();
  }
};
