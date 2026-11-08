// React ports of the app's core widgets (lib/core/widgets/*, plus the small
// dashboard pieces they compose). Sizes are Flutter logical pixels; the phone
// frame scales the whole screen.
import React, {useEffect, useState} from 'react';
import {continueRender, delayRender, Img, staticFile} from 'remotion';
import {Lottie, LottieAnimationData} from '@remotion/lottie';
import {
  AC,
  AppPack,
  AppText,
  decor,
  extraBold,
  ICON_FONT,
  medium,
  monoStyle,
  RAD,
  regular,
  SHADOW,
  SP,
  STROKE,
  tint,
} from './flutter';

/** A Material Icons Round glyph — Flutter's Icons.*_rounded. */
export const MIcon: React.FC<{name: string; size?: number; color?: string; style?: React.CSSProperties}> = ({
  name,
  size = 24,
  color = AC.text,
  style,
}) => (
  <span
    style={{
      fontFamily: ICON_FONT,
      fontSize: size,
      lineHeight: 1,
      width: size,
      height: size,
      display: 'inline-block',
      color,
      fontWeight: 'normal',
      fontStyle: 'normal',
      letterSpacing: 0,
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      flexShrink: 0,
      fontFeatureSettings: '"liga"',
      ...style,
    }}
  >
    {name}
  </span>
);

/** AppIcon: one of the app's own SVG marks. */
export const AppIcon: React.FC<{asset: string; size?: number; style?: React.CSSProperties}> = ({asset, size = 20, style}) => (
  <Img src={staticFile(`app/svg/${asset}.svg`)} style={{width: size, height: size, flexShrink: 0, ...style}} />
);

const lottieCache: Record<string, Promise<LottieAnimationData>> = {};
const useLottie = (name: string) => {
  const [data, setData] = useState<LottieAnimationData | null>(null);
  const [handle] = useState(() => delayRender(`lottie:${name}`));
  useEffect(() => {
    lottieCache[name] ??= fetch(staticFile(`app/lottie/${name}.json`)).then((r) => r.json());
    lottieCache[name]
      .then((d) => {
        setData(d);
        continueRender(handle);
      })
      .catch((e) => {
        console.error(e);
        continueRender(handle);
      });
  }, [handle, name]);
  return data;
};

/** RunnerCard's _RunnerAnimation: 66×66 tile, runner Lottie at 3.8×. */
export const RunnerTile: React.FC<{hasRunner: boolean; pal: AppPack['palette']}> = ({hasRunner, pal}) => {
  const runner = useLottie(hasRunner ? 'runner' : 'idle');
  return (
    <div
      style={{
        width: 66,
        height: 66,
        boxSizing: 'border-box',
        background: hasRunner ? AC.surface : tint(pal.primary, 0.18),
        borderRadius: RAD.xs,
        border: `${STROKE}px solid ${AC.ink}`,
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}
    >
      {runner ? (
        <div style={{width: 56, height: 56, transform: hasRunner ? 'scale(3.8)' : 'translateX(-8px) scale(1.6)'}}>
          <Lottie animationData={runner} loop style={{width: 56, height: 56}} />
        </div>
      ) : null}
    </div>
  );
};

/** CustomButton: ink-stroked, uppercase, presses down onto its own shadow. */
export const CustomButton: React.FC<{
  text: string;
  bg: string;
  fg?: string;
  icon?: string;
  svg?: string;
  height?: number;
  elevated?: boolean;
  press?: number;
  disabled?: boolean;
  style?: React.CSSProperties;
}> = ({text, bg, fg = AC.white, icon, svg, height = 52, elevated = true, press = 0, disabled = false, style}) => {
  const filled = bg !== 'transparent';
  const bgc = disabled ? (filled ? AC.btnDisabled : bg) : bg;
  const fgc = disabled ? AC.textTertiary : fg;
  const down = disabled ? 1 : press;
  const shadow = elevated ? SHADOW.raised : SHADOW.card;
  return (
    <div
      style={{
        height,
        boxSizing: 'border-box',
        borderRadius: RAD.sm,
        border: `${STROKE}px solid ${AC.ink}`,
        background: bgc,
        boxShadow: down > 0.5 ? 'none' : shadow,
        transform: `translate(${2 * down}px, ${4 * down}px)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: SP.xs,
        ...style,
      }}
    >
      {svg ? <AppIcon asset={svg} size={22} style={{opacity: disabled ? 0.4 : 1}} /> : icon ? <MIcon name={icon} size={20} color={fgc} /> : null}
      <span style={{...extraBold(15, fgc, 0.8), whiteSpace: 'nowrap', textTransform: 'uppercase'}}>{text}</span>
    </div>
  );
};

/** PillButton: the tinted chip at the end of a section header. */
export const PillButton: React.FC<{label: string; icon?: string; color: string}> = ({label, icon, color}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 5,
      padding: '6px 12px',
      background: tint(color, 0.22),
      borderRadius: RAD.xs,
      border: `${STROKE}px solid ${AC.ink}`,
      boxShadow: SHADOW.card,
    }}
  >
    {icon ? <MIcon name={icon} size={14} color={color} /> : null}
    <span style={{...AppText.monoLabel, color, textTransform: 'uppercase'}}>{label}</span>
  </div>
);

/** Pill: square-cornered status chip. */
export const Pill: React.FC<{label: string; color: string}> = ({label, color}) => (
  <div
    style={{
      padding: '3px 6px',
      background: tint(color, 0.24),
      borderRadius: RAD.xs,
      border: `1px solid ${AC.ink}`,
      flexShrink: 0,
    }}
  >
    <span style={{...monoStyle({fontSize: 10, ls: 0.8}), textTransform: 'uppercase', whiteSpace: 'nowrap'}}>{label}</span>
  </div>
);

/** UserAvatar: a rounded square with the initial (nobody here has a photo). */
export const UserAvatar: React.FC<{name: string; size?: number; dimmed?: boolean; tintColor: string}> = ({
  name,
  size = 42,
  dimmed = false,
  tintColor,
}) => {
  const t = dimmed ? AC.textTertiary : tintColor;
  return (
    <div
      style={{
        width: size,
        height: size,
        boxSizing: 'border-box',
        borderRadius: RAD.xs,
        background: tint(t, 0.2),
        border: `${STROKE}px solid ${AC.ink}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: 0,
      }}
    >
      <span style={monoStyle({fontSize: size * 0.38, weight: 800, color: t})}>{name.trim()[0]?.toUpperCase()}</span>
    </div>
  );
};

/** UnitBadge: a bare count with the unit name underneath. */
export const UnitBadge: React.FC<{
  count: number;
  pack: AppPack;
  suffix?: string;
  fontSize?: number;
  onBrand?: boolean;
}> = ({count, pack, suffix = '', fontSize = 22, onBrand = false}) => {
  const unitName = count === 1 ? pack.unit : pack.unitPlural;
  const numberColor = onBrand ? AC.white : count === 0 ? AC.textTertiary : AC.text;
  const captionColor = onBrand ? AC.textOnBrandMuted : AC.textTertiary;
  return (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-end', flexShrink: 0}}>
      <span style={monoStyle({fontSize, weight: 800, color: numberColor, h: 1.0})}>{count}</span>
      <span
        style={{
          ...monoStyle({fontSize: 8.5, color: captionColor, ls: 0.9}),
          marginTop: 2,
          textTransform: 'uppercase',
          whiteSpace: 'nowrap',
        }}
      >
        {`${unitName} ${suffix}`.trim()}
      </span>
    </div>
  );
};

/** DashedDivider: the torn-receipt rule. */
export const DashedDivider: React.FC = () => (
  <svg width="100%" height={1} style={{display: 'block'}}>
    <line x1={0} y1={0.5} x2="100%" y2={0.5} stroke={AC.textTertiary} strokeWidth={1.2} strokeDasharray="4 4" />
  </svg>
);

/** AppIconButton: the square icon chip. */
export const AppIconButton: React.FC<{icon: string; size?: number; enabled?: boolean; background?: string}> = ({
  icon,
  size = 20,
  enabled = true,
  background,
}) => (
  <div
    style={{
      padding: 8,
      boxSizing: 'border-box',
      background: background ?? AC.surface,
      borderRadius: RAD.xs,
      border: `${STROKE}px solid ${AC.ink}`,
      boxShadow: enabled ? SHADOW.card : 'none',
      transform: enabled ? undefined : `translate(${0.05 * (size + 18)}px, ${0.1 * (size + 18)}px)`,
      display: 'flex',
      flexShrink: 0,
    }}
  >
    <MIcon name={icon} size={size} color={enabled ? AC.text : AC.textTertiary} />
  </div>
);

/** SectionHeader: title left, count badge + action right. */
export const SectionHeader: React.FC<{title: string; count?: number; action?: React.ReactNode}> = ({title, count, action}) => (
  <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
    <span style={AppText.h3}>{title}</span>
    <div style={{display: 'flex', alignItems: 'center', gap: SP.xs}}>
      {count !== undefined ? (
        <div
          style={{
            padding: '2px 7px',
            background: AC.surfaceAlt,
            borderRadius: RAD.xs,
            border: `${STROKE}px solid ${AC.ink}`,
          }}
        >
          <span style={monoStyle({fontSize: 11})}>{count}</span>
        </div>
      ) : null}
      {action}
    </div>
  </div>
);

/** ShowToastDialog's toast: success-tinted card under the status bar. */
export const Toast: React.FC<{message: string; t: number; top: number}> = ({message, t, top}) => {
  if (t <= 0) return null;
  return (
    <div
      style={{
        position: 'absolute',
        top: top + SP.sm,
        left: SP.md,
        right: SP.md,
        display: 'flex',
        justifyContent: 'center',
        opacity: Math.min(1, t),
        transform: `translateY(${(1 - Math.min(1, t)) * -12}px)`,
        zIndex: 50,
      }}
    >
      <div
        style={{
          ...decor.card({color: tint(AC.success, 0.14), radius: RAD.sm}),
          padding: `${SP.sm}px ${SP.sm + 2}px`,
          display: 'flex',
          alignItems: 'center',
          gap: SP.xs,
        }}
      >
        <MIcon name="check_circle" size={19} color={AC.success} />
        <span style={{...medium(13.5, AC.text), whiteSpace: 'nowrap'}}>{message}</span>
      </div>
    </div>
  );
};

/** _DialogShell from core/alerts/dialogs.dart. */
export const ConfirmDialog: React.FC<{
  icon: string;
  accent: string;
  title: string;
  content: string;
  confirmLabel: string;
  cancelLabel?: string;
  confirmPress?: number;
}> = ({icon, accent, title, content, confirmLabel, cancelLabel = 'Cancel', confirmPress = 0}) => (
  <div style={{...decor.card({radius: RAD.lg}), padding: SP.lg, display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
    <div
      style={{
        ...decor.tinted(accent, {radius: RAD.sm, shadow: false}),
        width: 54,
        height: 54,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      <MIcon name={icon} size={25} color={accent} />
    </div>
    <div style={{...AppText.h3, textAlign: 'center', marginTop: SP.md}}>{title}</div>
    <div style={{...regular(13.5, AC.textSecondary), textAlign: 'center', marginTop: 6}}>{content}</div>
    <div style={{display: 'flex', gap: SP.sm, marginTop: SP.lg, alignSelf: 'stretch'}}>
      <CustomButton text={cancelLabel} bg="transparent" fg={AC.textSecondary} height={46} elevated={false} style={{flex: 1}} />
      <CustomButton text={confirmLabel} bg={accent} fg={AC.white} height={46} elevated={false} press={confirmPress} style={{flex: 1}} />
    </div>
  </div>
);
