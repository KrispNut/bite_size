import React from 'react';
import {AbsoluteFill} from 'remotion';

/**
 * Solid circle with soft concentric echo rings on its leading edge: the
 * reference's "question-mark dot grows into the next scene" wipe.
 */
export const CircleWipe: React.FC<{
  x: number;
  y: number;
  r: number;
  color: string;
  rings?: number;
}> = ({x, y, r, color, rings = 3}) => {
  if (r <= 0) return null;
  const ringEls = [];
  for (let i = rings; i >= 1; i--) {
    const rr = r * (1 + 0.035 * i) + 14 * i;
    ringEls.push(
      <div
        key={i}
        style={{
          position: 'absolute',
          left: x - rr,
          top: y - rr,
          width: rr * 2,
          height: rr * 2,
          borderRadius: '50%',
          background: color,
          opacity: 0.16 / i,
        }}
      />,
    );
  }
  return (
    <>
      {ringEls}
      <div
        style={{
          position: 'absolute',
          left: x - r,
          top: y - r,
          width: r * 2,
          height: r * 2,
          borderRadius: '50%',
          background: color,
        }}
      />
    </>
  );
};

/**
 * Halftone iris: a solid disc whose edge dissolves into a dot screen, the
 * dithered blob the reference uses to move between light and dark scenes.
 */
export const HalftoneIris: React.FC<{
  x: number;
  y: number;
  radius: number;
  color: string;
  feather?: number;
  spacing?: number;
  width?: number;
  height?: number;
}> = ({x, y, radius, color, feather = 300, spacing = 22, width = 1920, height = 1080}) => {
  if (radius <= 0) return null;
  const inner = Math.max(0, radius - feather);
  const dots: React.ReactNode[] = [];
  const cols = Math.ceil(width / spacing) + 1;
  const rows = Math.ceil(height / spacing) + 1;
  for (let j = 0; j < rows; j++) {
    // Offset alternate rows for a classic halftone screen.
    const off = j % 2 === 0 ? 0 : spacing / 2;
    for (let i = 0; i < cols; i++) {
      const px = i * spacing + off;
      const py = j * spacing;
      const d = Math.hypot(px - x, py - y);
      if (d <= inner - spacing || d >= radius) continue;
      const t = Math.min(1, (radius - d) / feather);
      const r = spacing * 0.74 * Math.pow(t, 0.85);
      if (r < 0.6) continue;
      dots.push(<circle key={`${i}-${j}`} cx={px} cy={py} r={r} />);
    }
  }
  return (
    <AbsoluteFill style={{pointerEvents: 'none'}}>
      <svg width={width} height={height} style={{position: 'absolute', inset: 0}}>
        <g fill={color}>
          {inner > 0 ? <circle cx={x} cy={y} r={inner} /> : null}
          {dots}
        </g>
      </svg>
    </AbsoluteFill>
  );
};
