import React from 'react';
import {useCurrentFrame} from 'remotion';
import {expoOut, prog, quintOut} from '../anim';
import {mono, serif} from '../theme';

/**
 * Masked rise: the word slides up out of its own line box, the reference's
 * signature text entrance ("Got" / "something" / "to").
 */
export const Rise: React.FC<{
  at: number;
  dur?: number;
  children: React.ReactNode;
  style?: React.CSSProperties;
  tilt?: number;
}> = ({at, dur = 16, children, style, tilt = 5}) => {
  const frame = useCurrentFrame();
  const p = prog(frame, at, dur, expoOut);
  return (
    <span
      style={{
        display: 'inline-block',
        overflow: 'hidden',
        verticalAlign: 'bottom',
        padding: '0 0.18em 0.16em 0.06em',
        margin: '0 -0.18em -0.16em -0.06em',
        ...style,
      }}
    >
      <span
        style={{
          display: 'inline-block',
          transform: `translateY(${(1 - p) * 130}%) rotate(${(1 - p) * tilt}deg)`,
          transformOrigin: '0% 100%',
          willChange: 'transform',
        }}
      >
        {children}
      </span>
    </span>
  );
};

/** A run of words, each rising in turn. */
export const Words: React.FC<{
  text: string;
  at: number;
  stagger?: number;
  style?: React.CSSProperties;
}> = ({text, at, stagger = 4, style}) => {
  const words = text.split(' ');
  return (
    <>
      {words.map((w, i) => (
        <React.Fragment key={i}>
          <Rise at={at + i * stagger} style={style}>
            {w}
          </Rise>
          {i < words.length - 1 ? ' ' : null}
        </React.Fragment>
      ))}
    </>
  );
};

/**
 * The emphasised word: italic display serif in the pack colour, rising with a
 * de-blur, then a hand-drawn underline sweeping under it.
 */
export const Accent: React.FC<{
  at: number;
  color: string;
  children: React.ReactNode;
  underline?: boolean;
  underlineColor?: string;
  sizeEm?: number;
  style?: React.CSSProperties;
}> = ({
  at,
  color,
  children,
  underline = true,
  underlineColor,
  sizeEm = 1.22,
  style,
}) => {
  const frame = useCurrentFrame();
  const p = prog(frame, at, 20, expoOut);
  const u = prog(frame, at + 9, 14, quintOut);
  return (
    <span
      style={{
        display: 'inline-block',
        position: 'relative',
        fontFamily: serif,
        fontStyle: 'italic',
        fontWeight: 400,
        fontSize: `${sizeEm}em`,
        letterSpacing: '-0.01em',
        lineHeight: 0.9,
        color,
        ...style,
      }}
    >
      <span
        style={{
          display: 'inline-block',
          overflow: 'hidden',
          verticalAlign: 'bottom',
          padding: '0.05em 0.22em 0.12em 0.08em',
          margin: '-0.05em -0.22em -0.12em -0.08em',
        }}
      >
        <span
          style={{
            display: 'inline-block',
            transform: `translateY(${(1 - p) * 140}%) rotate(${(1 - p) * -7}deg) scale(${0.92 + 0.08 * p})`,
            transformOrigin: '0% 100%',
            filter: `blur(${(1 - p) * 6}px)`,
            // The blur would bleed past the mask before the rise starts.
            opacity: Math.min(1, p * 4),
          }}
        >
          {children}
        </span>
      </span>
      {underline ? (
        <svg
          viewBox="0 0 200 20"
          preserveAspectRatio="none"
          style={{
            position: 'absolute',
            left: '4%',
            bottom: '-0.12em',
            width: '86%',
            height: '0.16em',
            overflow: 'visible',
            // A zero-length dash still draws its round cap; hide until drawing.
            opacity: u > 0.001 ? 1 : 0,
          }}
        >
          <path
            d="M2 13 C 50 6, 120 5, 198 9"
            fill="none"
            stroke={underlineColor ?? color}
            strokeWidth={5}
            strokeLinecap="round"
            pathLength={1}
            strokeDasharray={1}
            strokeDashoffset={1 - u}
            vectorEffect="non-scaling-stroke"
          />
        </svg>
      ) : null}
    </span>
  );
};

/** "// mono label" typed on character by character. */
export const MonoLabel: React.FC<{
  at: number;
  text: string;
  color: string;
  size?: number;
  cps?: number;
  style?: React.CSSProperties;
}> = ({at, text, color, size = 24, cps = 1.6, style}) => {
  const frame = useCurrentFrame();
  const n = Math.max(0, Math.min(text.length, Math.floor((frame - at) * cps * 1.5)));
  const visible = frame >= at;
  return (
    <div
      style={{
        fontFamily: mono,
        fontSize: size,
        color,
        letterSpacing: '0.01em',
        whiteSpace: 'pre',
        opacity: visible ? 1 : 0,
        ...style,
      }}
    >
      {text.slice(0, n)}
      <span style={{opacity: 0}}>{text.slice(n)}</span>
    </div>
  );
};
