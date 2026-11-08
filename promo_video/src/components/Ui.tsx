import React from 'react';
import {c, mono, palette, sans, withAlpha} from '../theme';

export const cardShadow = `0 1px 2px ${withAlpha(palette.shadowLight, 0.04)}, 0 18px 40px -18px ${withAlpha(palette.shadowLight, 0.18)}`;

export const Card: React.FC<{
  style?: React.CSSProperties;
  children?: React.ReactNode;
  dashed?: boolean;
}> = ({style, children, dashed}) => (
  <div
    style={{
      position: 'absolute',
      background: dashed ? 'transparent' : c.surface,
      border: dashed ? `2px dashed ${c.border}` : `1.5px solid ${c.border}`,
      borderRadius: 30,
      boxShadow: dashed ? 'none' : cardShadow,
      boxSizing: 'border-box',
      overflow: 'hidden',
      ...style,
    }}
  >
    {children}
  </div>
);

export const Avatar: React.FC<{
  initial: string;
  bg: string;
  fg?: string;
  size?: number;
  ring?: string;
  style?: React.CSSProperties;
}> = ({initial, bg, fg = c.text, size = 52, ring, style}) => (
  <div
    style={{
      width: size,
      height: size,
      borderRadius: size,
      background: bg,
      color: fg,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: sans,
      fontWeight: 600,
      fontSize: size * 0.42,
      flexShrink: 0,
      boxShadow: ring ? `0 0 0 4px ${ring}` : undefined,
      ...style,
    }}
  >
    {initial}
  </div>
);

export const Pill: React.FC<{
  bg: string;
  fg: string;
  children: React.ReactNode;
  size?: number;
  style?: React.CSSProperties;
  border?: string;
}> = ({bg, fg, children, size = 22, style, border}) => (
  <div
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: size * 0.4,
      padding: `${size * 0.36}px ${size * 0.75}px`,
      borderRadius: 999,
      background: bg,
      color: fg,
      fontFamily: mono,
      fontWeight: 500,
      fontSize: size,
      letterSpacing: '0.02em',
      whiteSpace: 'nowrap',
      border: border ? `1.5px solid ${border}` : undefined,
      ...style,
    }}
  >
    {children}
  </div>
);

type IconProps = {size?: number; color?: string; stroke?: number; style?: React.CSSProperties};

const Svg: React.FC<IconProps & {children: React.ReactNode}> = ({
  size = 32,
  color = 'currentColor',
  stroke = 2.4,
  style,
  children,
}) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 32 32"
    fill="none"
    stroke={color}
    strokeWidth={stroke}
    strokeLinecap="round"
    strokeLinejoin="round"
    style={{flexShrink: 0, ...style}}
  >
    {children}
  </svg>
);

/** Tandoor roti: a disc with char spots. */
export const RotiIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <circle cx="16" cy="16" r="12" />
    <circle cx="11.5" cy="12.5" r="1.3" fill={p.color} stroke="none" />
    <circle cx="19" cy="11" r="1" fill={p.color} stroke="none" />
    <circle cx="20.5" cy="18.5" r="1.4" fill={p.color} stroke="none" />
    <circle cx="13" cy="20" r="1" fill={p.color} stroke="none" />
    <circle cx="16.5" cy="15.5" r="0.9" fill={p.color} stroke="none" />
  </Svg>
);

/** A bowl of salan with steam. */
export const BowlIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <path d="M4 16h24c0 6.2-5.4 11-12 11S4 22.2 4 16z" />
    <path d="M11 11c-1-1.4 1-2.6 0-4M16 11c-1-1.4 1-2.6 0-4M21 11c-1-1.4 1-2.6 0-4" />
  </Svg>
);

export const LockIcon: React.FC<IconProps & {open?: number}> = ({open = 0, ...p}) => (
  <Svg {...p}>
    <rect x="6" y="14" width="20" height="14" rx="3.5" />
    <path
      d="M10.5 14V10a5.5 5.5 0 0 1 11 0v4"
      style={{transform: `translateY(${-open * 3}px)`}}
    />
    <circle cx="16" cy="21" r="1.4" fill={p.color} stroke="none" />
  </Svg>
);

/** Runner: an arrow heading out the door. */
export const RunnerIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <path d="M13 6H8a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h5" />
    <path d="M14 16h13M22 11l5 5-5 5" />
  </Svg>
);

export const CricketBallIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <circle cx="16" cy="16" r="12" />
    <path d="M9.5 6.5c3.2 2.6 4.8 5.8 4.8 9.5s-1.6 6.9-4.8 9.5" />
    <path d="M22.5 6.5c-3.2 2.6-4.8 5.8-4.8 9.5s1.6 6.9 4.8 9.5" />
  </Svg>
);

/** Stumps and bails. */
export const StumpsIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <path d="M9 9v19M16 9v19M23 9v19" />
    <path d="M8 6h7M17 6h7" />
  </Svg>
);

export const ClockIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <circle cx="16" cy="16" r="12" />
    <path d="M16 9v7l5 3" />
  </Svg>
);

export const CheckIcon: React.FC<IconProps & {draw?: number}> = ({draw = 1, ...p}) => (
  <Svg {...p}>
    <path
      d="M8 16.5l5.5 5.5L24 10.5"
      pathLength={1}
      strokeDasharray={1}
      strokeDashoffset={1 - draw}
    />
  </Svg>
);

/** Ledger page with ruled lines. */
export const LedgerIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <rect x="7" y="4" width="18" height="24" rx="3" />
    <path d="M11 11h10M11 16h10M11 21h6" />
  </Svg>
);

export const PlusIcon: React.FC<IconProps> = (p) => (
  <Svg {...p}>
    <path d="M16 8v16M8 16h16" />
  </Svg>
);

/** Round badge with a drawn check: pops onto finished cards. */
export const CheckBadge: React.FC<{
  size?: number;
  bg: string;
  pop: number;
  draw: number;
  style?: React.CSSProperties;
}> = ({size = 44, bg, pop, draw, style}) => (
  <div
    style={{
      position: 'absolute',
      width: size,
      height: size,
      borderRadius: size,
      background: bg,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      transform: `scale(${pop})`,
      boxShadow: `0 0 0 5px ${c.surface}`,
      ...style,
    }}
  >
    <CheckIcon size={size * 0.72} color="#FFFFFF" stroke={3.4} draw={draw} />
  </div>
);

/** macOS-style pointer, as in the reference's UI demos. */
export const Cursor: React.FC<{x: number; y: number; press?: number; opacity?: number}> = ({
  x,
  y,
  press = 0,
  opacity = 1,
}) => (
  <svg
    width={46}
    height={46}
    viewBox="0 0 32 32"
    style={{
      position: 'absolute',
      left: x,
      top: y,
      opacity,
      transform: `scale(${1 - press * 0.16})`,
      transformOrigin: '6px 4px',
      filter: `drop-shadow(0 4px 6px ${withAlpha(palette.shadowLight, 0.3)})`,
      overflow: 'visible',
    }}
  >
    <path
      d="M6 3 L6 25 L11.5 19.8 L15.4 28.4 L19.4 26.6 L15.6 18.2 L23 18.2 Z"
      fill="#111111"
      stroke="#FFFFFF"
      strokeWidth={2}
      strokeLinejoin="round"
    />
  </svg>
);

/** Ring that blooms out from a click point. */
export const ClickRing: React.FC<{x: number; y: number; t: number; color: string}> = ({
  x,
  y,
  t,
  color,
}) => {
  if (t <= 0 || t >= 1) return null;
  const r = 14 + t * 70;
  return (
    <div
      style={{
        position: 'absolute',
        left: x - r,
        top: y - r,
        width: r * 2,
        height: r * 2,
        borderRadius: r * 2,
        border: `3px solid ${color}`,
        opacity: (1 - t) * 0.9,
      }}
    />
  );
};
