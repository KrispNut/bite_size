import type {CSSProperties} from 'react';
import {useLayout} from '../lib/layout';
import {withAlpha} from '../theme/colors';
import type {Palette} from '../theme/schemes';
import {textStyle} from '../theme/typography';

/** A small monospaced pill for specs, commands and tags. */
export const Chip: React.FC<{
  palette: Palette;
  children: React.ReactNode;
  prefix?: string;
  style?: CSSProperties;
}> = ({palette, children, prefix, style}) => {
  const {unit} = useLayout();
  return (
    <div
      style={{
        ...textStyle('code', unit, {fontSize: 26 * unit}),
        display: 'inline-flex',
        alignItems: 'center',
        gap: 14 * unit,
        padding: `${14 * unit}px ${24 * unit}px`,
        borderRadius: 999,
        border: `${1.5 * unit}px solid ${palette.line}`,
        background: withAlpha(palette.surface, 0.7),
        color: palette.text,
        whiteSpace: 'nowrap',
        ...style,
      }}
    >
      {prefix ? <span style={{color: palette.accent}}>{prefix}</span> : null}
      {children}
    </div>
  );
};

/** A small caps label with a beat-synced dot and a rule that draws in. */
export const Kicker: React.FC<{
  palette: Palette;
  children: React.ReactNode;
  /** 0–1: how far the label is in. */
  progress: number;
  /** 0–1 decaying beat pulse for the dot. */
  pulse?: number;
}> = ({palette, children, progress, pulse = 0}) => {
  const {unit} = useLayout();
  const dot = 14 * unit;
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 20 * unit,
        opacity: progress,
        transform: `translateY(${(1 - progress) * 16 * unit}px)`,
      }}
    >
      <div
        style={{
          width: dot,
          height: dot,
          borderRadius: '50%',
          background: palette.accent,
          boxShadow: `0 0 ${(12 + 28 * pulse) * unit}px ${withAlpha(palette.accent, 0.4 + 0.5 * pulse)}`,
          transform: `scale(${1 + 0.35 * pulse})`,
        }}
      />
      <div style={{...textStyle('label', unit), color: palette.muted}}>{children}</div>
      <div
        style={{
          height: 1.5 * unit,
          width: 220 * unit * progress,
          background: `linear-gradient(to right, ${palette.line}, transparent)`,
        }}
      />
    </div>
  );
};
