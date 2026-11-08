// The app's screens, rebuilt from the Flutter widgets that draw them:
//   splash_view.dart, dashboard_view/body, runner_card, pending_invites_card,
//   invite_row, roster_tile, shared_expense_tile, dashboard_bottom_bar,
//   roster_closed_notice, ledger_view, month_nav_bar, month_summary,
//   bento_tile, ledger_daily_strip_view, settle_month_sheet, bill_total_tile,
//   dashboard_drawer, drawer_tile, pack_picker_sheet.
// Everything is in Flutter logical pixels on a 412×915 Android screen.
import React from 'react';
import {Img, staticFile} from 'remotion';
import {
  AC,
  AppPack,
  AppText,
  bold,
  decor,
  extraBold,
  medium,
  monoStyle,
  packSummary,
  RAD,
  regular,
  rgba,
  rs,
  semiBold,
  SHADOW,
  SP,
  STROKE,
  tint,
  titleCase,
} from './flutter';
import {
  AppIcon,
  AppIconButton,
  ConfirmDialog,
  CustomButton,
  DashedDivider,
  MIcon,
  Pill,
  PillButton,
  RunnerTile,
  SectionHeader,
  Toast,
  UnitBadge,
  UserAvatar,
} from './widgets';

export const SCREEN = {w: 412, h: 915, status: 36, appBar: 68, gesture: 24};
const BODY_TOP = SCREEN.status + SCREEN.appBar + STROKE;

// --- device chrome ---------------------------------------------------------

export const DEVICE = {bezel: 11, radius: 54};
export const DEVICE_W = SCREEN.w + DEVICE.bezel * 2;
export const DEVICE_H = SCREEN.h + DEVICE.bezel * 2;

/** A plain Android handset: punch-hole camera, gesture bar. */
export const Phone: React.FC<{children: React.ReactNode; shadow?: boolean}> = ({children, shadow = true}) => (
  <div
    style={{
      position: 'absolute',
      left: 0,
      top: 0,
      width: DEVICE_W,
      height: DEVICE_H,
      borderRadius: DEVICE.radius,
      background: '#101114',
      boxShadow: shadow ? `0 50px 90px -40px ${rgba(AC.shadowLight, 0.55)}, 0 0 0 2px #2A2C31 inset` : undefined,
    }}
  >
    <div
      style={{
        position: 'absolute',
        left: DEVICE.bezel,
        top: DEVICE.bezel,
        width: SCREEN.w,
        height: SCREEN.h,
        borderRadius: DEVICE.radius - DEVICE.bezel,
        overflow: 'hidden',
        background: AC.bg,
      }}
    >
      {children}
      {/* punch-hole camera */}
      <div
        style={{
          position: 'absolute',
          left: SCREEN.w / 2 - 6,
          top: 12,
          width: 12,
          height: 12,
          borderRadius: 12,
          background: '#050506',
          zIndex: 100,
        }}
      />
    </div>
  </div>
);

export const StatusBar: React.FC<{light?: boolean; bg?: string}> = ({light = false, bg = 'transparent'}) => {
  const fg = light ? '#FFFFFF' : AC.text;
  return (
    <div
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: SCREEN.status,
        background: bg,
        display: 'flex',
        alignItems: 'center',
        padding: '0 22px',
        zIndex: 40,
      }}
    >
      <span style={{...medium(14, fg, 0.2, 1)}}>1:12</span>
      <div style={{flex: 1}} />
      <MIcon name="signal_cellular_alt" size={16} color={fg} />
      <MIcon name="wifi" size={16} color={fg} style={{marginLeft: 4}} />
      <MIcon name="battery_full" size={16} color={fg} style={{marginLeft: 2, transform: 'rotate(90deg)'}} />
    </div>
  );
};

const GestureHandle: React.FC<{light?: boolean}> = ({light}) => (
  <div
    style={{
      position: 'absolute',
      bottom: 8,
      left: SCREEN.w / 2 - 54,
      width: 108,
      height: 4,
      borderRadius: 4,
      background: light ? 'rgba(255,255,255,0.7)' : rgba(AC.ink, 0.45),
      zIndex: 90,
    }}
  />
);

export const Scrim: React.FC<{opacity: number; alpha?: number}> = ({opacity, alpha = 0.32}) =>
  opacity > 0 ? (
    <div style={{position: 'absolute', inset: 0, background: `rgba(0,0,0,${alpha})`, opacity, zIndex: 60}} />
  ) : null;

// --- splash_view.dart -----------------------------------------------------

export const SplashScreen: React.FC<{pack: AppPack; fade: number; rise: number; shuttle: number}> = ({
  pack,
  fade,
  rise,
  shuttle,
}) => (
  <div style={{position: 'absolute', inset: 0, background: pack.palette.primaryDeep}}>
    <StatusBar light />
    <div
      style={{
        position: 'absolute',
        inset: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: `0 ${SP.xxl}px`,
        opacity: fade,
        transform: `translateY(${rise}px)`,
      }}
    >
      <SplashLockup pack={pack} />
    </div>
    <div
      style={{
        position: 'absolute',
        left: SCREEN.w / 2 - 48,
        bottom: SP.huge + SCREEN.gesture,
        opacity: fade,
      }}
    >
      <NeoProgressBar t={shuttle} color={pack.palette.accentFill} track={pack.palette.primary} />
    </div>
    <GestureHandle light />
  </div>
);

export const SplashLockup: React.FC<{pack: AppPack}> = ({pack}) => (
  <>
    <div
      style={{
        ...decor.card({radius: RAD.lg, borderColor: AC.ink, shadow: false}),
        width: 128,
        height: 128,
        padding: SP.lg,
      }}
    >
      <Img src={staticFile('app/svg/splash_image.svg')} style={{width: '100%', height: '100%', objectFit: 'contain'}} />
    </div>
    <div style={{...extraBold(36, AC.white, -1), marginTop: SP.xl, textAlign: 'center'}}>{pack.activityName}</div>
    <div
      style={{
        ...monoStyle({fontSize: 11, color: AC.textOnBrandMuted, ls: 1.1, h: 1.5}),
        marginTop: SP.xs,
        textAlign: 'center',
      }}
    >
      {pack.tagline}
    </div>
  </>
);

/** NeoProgressBar: ink-stroked track, a hard block shuttling end to end. */
export const NeoProgressBar: React.FC<{t: number; color: string; track: string; width?: number; height?: number}> = ({
  t,
  color,
  track,
  width = 96,
  height = 10,
}) => {
  const tri = 1 - Math.abs(((t % 2) + 2) % 2 - 1); // 0→1→0, reverse repeat
  const blockW = (width - 2) * 0.42;
  return (
    <div
      style={{
        width,
        height,
        boxSizing: 'border-box',
        background: track,
        borderRadius: RAD.xs,
        border: `${STROKE}px solid ${AC.ink}`,
        overflow: 'hidden',
        position: 'relative',
      }}
    >
      <div style={{position: 'absolute', top: 0, bottom: 0, width: blockW, left: tri * (width - 2 - blockW), background: color}} />
    </div>
  );
};

// --- app bar ---------------------------------------------------------------

const LogoTitle: React.FC<{pack: AppPack; subtitle: string}> = ({pack, subtitle}) => (
  <div style={{display: 'flex', alignItems: 'center'}}>
    <div
      style={{
        padding: 5,
        borderRadius: '50%',
        background: pack.palette.primarySoft,
        border: `${STROKE}px solid ${pack.palette.primary}`,
        display: 'flex',
      }}
    >
      <AppIcon asset="roti" size={20} />
    </div>
    <div style={{width: SP.xs}} />
    <div style={{display: 'flex', flexDirection: 'column'}}>
      <span style={extraBold(21, AC.text)}>{pack.activityName}</span>
      <span style={{...AppText.monoLabel, marginTop: 1}}>{subtitle.toUpperCase()}</span>
    </div>
  </div>
);

const AppBarShell: React.FC<{leading: React.ReactNode; title: React.ReactNode}> = ({leading, title}) => (
  <>
    <div
      style={{
        position: 'absolute',
        top: SCREEN.status,
        left: 0,
        right: 0,
        height: SCREEN.appBar,
        display: 'flex',
        alignItems: 'center',
        background: AC.bg,
        zIndex: 30,
      }}
    >
      <div style={{width: 56, display: 'flex', justifyContent: 'center', flexShrink: 0}}>{leading}</div>
      <div style={{marginLeft: 4}}>{title}</div>
    </div>
    <div style={{position: 'absolute', top: SCREEN.status + SCREEN.appBar, left: 0, right: 0, height: STROKE, background: AC.ink, zIndex: 30}} />
  </>
);

// --- dashboard pieces --------------------------------------------------------

const RosterStatusBar: React.FC<{locked: boolean}> = ({locked}) => {
  const accent = locked ? AC.danger : AC.success;
  return (
    <div style={{display: 'flex', alignItems: 'center'}}>
      <div style={{width: 9, height: 9, background: accent, border: `1px solid ${AC.ink}`, boxSizing: 'border-box'}} />
      <div style={{width: SP.xs}} />
      <span style={monoStyle({color: accent, fontSize: 11, ls: 1.1})}>{locked ? 'ROSTER LOCKED' : 'ROSTER OPEN'}</span>
      {locked ? (
        <span style={{...AppText.monoLabel, color: AC.textTertiary, marginLeft: SP.xs}}>· LEFT 1:15 PM</span>
      ) : null}
    </div>
  );
};

/** PendingInvitesCard + its one InviteRow. */
const PendingInvitesCard: React.FC<{pack: AppPack; countPress: number}> = ({pack, countPress}) => {
  const pal = pack.palette;
  return (
    <div style={{...decor.tinted(pal.accent, {shadow: false}), padding: SP.md}}>
      <div style={{display: 'flex', alignItems: 'center'}}>
        <div style={{...decor.filled(pal.accentFill, {radius: RAD.xs}), padding: 6, display: 'flex'}}>
          <AppIcon asset="plate" size={18} />
        </div>
        <div style={{width: SP.xs}} />
        <span style={extraBold(15, AC.text)}>A {pack.expense} needs your answer</span>
      </div>
      <div style={{...AppText.caption, color: AC.textSecondary, marginTop: 4}}>
        Nobody can set off on the {pack.errand} until you reply.
      </div>
      <div style={{...decor.card({radius: RAD.sm, shadow: false}), padding: SP.sm, marginTop: SP.sm, marginBottom: SP.xs}}>
        <div style={{display: 'flex', alignItems: 'flex-start'}}>
          <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>
            <span style={bold(14, AC.text)}>Extra salan</span>
            <span style={{...AppText.caption, marginTop: 2}}>Bilal paid Rs 480 · asked 3 people</span>
          </div>
          <div style={{width: SP.xs}} />
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-end'}}>
            <span style={extraBold(16, pal.accent)}>~Rs 160</span>
            <span style={medium(10, AC.textTertiary)}>your share</span>
          </div>
        </div>
        <div style={{display: 'flex', gap: SP.xs, marginTop: SP.sm}}>
          <CustomButton text="Not me" bg="transparent" fg={AC.textSecondary} height={40} elevated={false} style={{flex: 1}} />
          <CustomButton
            text="Count me in"
            bg={pal.primary}
            icon="check"
            height={40}
            elevated={false}
            press={countPress}
            style={{flex: 2}}
          />
        </div>
      </div>
    </div>
  );
};

type NextStep = 'waitBoth' | 'waitSara' | 'clear' | 'departed';

const StatusLine: React.FC<{icon: string; color?: string; text: string}> = ({icon, color, text}) => (
  <div style={{display: 'flex', alignItems: 'flex-start'}}>
    <MIcon name={icon} size={16} color={color ?? AC.textOnBrandMuted} style={{marginTop: 1}} />
    <div style={{width: SP.xs}} />
    <span style={{...semiBold(13.5, AC.white), flex: 1}}>{text}</span>
  </div>
);

/** RunnerCard, hasRunner == true, seen by the runner (who is also an admin). */
const RunnerCard: React.FC<{
  pack: AppPack;
  name: string;
  units: number;
  step: NextStep;
  startPress?: number;
}> = ({pack, name, units, step, startPress = 0}) => {
  const pal = pack.palette;
  let status: React.ReactNode;
  let button: React.ReactNode;
  if (step === 'departed') {
    status = <StatusLine icon="lock" text="Left at 1:15 PM · list locked" />;
    button = <CustomButton text={pack.arrival} bg={pal.accentFill} fg={pal.onAccent} icon="notifications_active" height={48} />;
  } else if (step === 'clear') {
    status = <StatusLine icon="check" text="Everything is confirmed — clear to go!" />;
    button = (
      <CustomButton text={`Start the ${pack.errand}`} bg={pal.accentFill} fg={pal.onAccent} svg="runner" height={48} press={startPress} />
    );
  } else {
    const who = step === 'waitBoth' ? 'Sara, Ali' : 'Sara';
    status = <StatusLine icon="hourglass_top" color={AC.warning} text={`Waiting on ${who} to answer "Extra salan".`} />;
    button = <CustomButton text={`Start the ${pack.errand}`} bg={pal.accentFill} fg={pal.onAccent} svg="runner" height={48} disabled />;
  }
  return (
    <div style={{...decor.filled(pal.primaryDeep, {shadow: false}), padding: SP.sm + 2}}>
      <div style={{display: 'flex', alignItems: 'center'}}>
        <RunnerTile hasRunner pal={pal} />
        <div style={{width: SP.sm}} />
        <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>
          <span style={{...AppText.monoLabel, color: AC.textOnBrandMuted}}>{pack.runner.toUpperCase()}</span>
          <span style={{...bold(17, AC.white), marginTop: 3}}>{name}</span>
        </div>
        <div style={{width: SP.xs}} />
        <UnitBadge count={units} pack={pack} suffix="to buy" fontSize={26} onBrand />
      </div>
      <div style={{height: SP.sm}} />
      <DashedDivider />
      <div style={{height: SP.sm}} />
      {status}
      <div style={{height: SP.sm}} />
      {button}
    </div>
  );
};

type Entry = {name: string; dish: string | null; units: number; me?: boolean};
const ROSTER: Entry[] = [
  {name: 'Sara', dish: 'Chicken karahi', units: 2},
  {name: 'Ali', dish: 'Daal mash', units: 3, me: true},
  {name: 'Hina', dish: 'Aloo gobi', units: 3},
  {name: 'Bilal', dish: null, units: 4},
];

const RosterTile: React.FC<{pack: AppPack; e: Entry; appear: number}> = ({pack, e, appear}) => {
  const pal = pack.palette;
  const nothing = e.dish === null;
  return (
    <div
      style={{
        ...decor.card({color: e.me ? pal.primarySoft : AC.surface, shadow: false}),
        marginBottom: SP.sm,
        display: 'flex',
        overflow: 'hidden',
        opacity: appear,
        transform: `translateY(${(1 - appear) * 16}px)`,
      }}
    >
      {e.me ? <div style={{width: 6, background: pal.primary, flexShrink: 0}} /> : null}
      <div style={{flex: 1, display: 'flex', alignItems: 'center', padding: `${SP.sm + 2}px ${SP.md}px`}}>
        <div
          style={
            e.me
              ? {borderRadius: RAD.sm, border: `${STROKE}px solid ${pal.primary}`, padding: 2, display: 'flex'}
              : {display: 'flex'}
          }
        >
          <UserAvatar name={e.name} dimmed={nothing} tintColor={pal.primary} />
        </div>
        <div style={{width: SP.sm}} />
        <div style={{flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0}}>
          <span style={bold(16, nothing ? AC.textTertiary : AC.text)}>{nothing ? pack.attendingOnly : e.dish}</span>
          <span style={{...medium(12, e.me ? pal.primary : AC.textTertiary), marginTop: 3}}>
            {e.me ? `${e.name} · you` : e.name}
          </span>
        </div>
        <div style={{width: SP.xs}} />
        <div style={{width: 46, display: 'flex', justifyContent: 'flex-end'}}>
          <UnitBadge count={e.units} pack={pack} />
        </div>
      </div>
    </div>
  );
};

type ShareState = {name: string; status: 'accepted' | 'pending'};

/** SharedExpenseTile. */
const SharedExpenseTile: React.FC<{
  pack: AppPack;
  title: string;
  paidBy: string;
  cost: number;
  shares: ShareState[];
  meShare: number | null; // null → not in yet
  awaitingMe: boolean;
}> = ({pack, title, paidBy, cost, shares, meShare, awaitingMe}) => {
  const pal = pack.palette;
  const pending = shares.filter((s) => s.status === 'pending').length;
  const accent = pending > 0 ? AC.warning : pal.accent;
  return (
    <div
      style={{
        ...decor.card({color: awaitingMe ? tint(accent, 0.12) : AC.surface, shadow: false}),
        padding: SP.sm + 2,
        marginBottom: SP.sm,
      }}
    >
      <div style={{display: 'flex', alignItems: 'flex-start'}}>
        <div
          style={{
            width: 36,
            height: 36,
            boxSizing: 'border-box',
            background: tint(accent, 0.24),
            borderRadius: RAD.xs,
            border: `1px solid ${AC.ink}`,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
          }}
        >
          <AppIcon asset="plate" size={19} />
        </div>
        <div style={{width: SP.sm}} />
        <div style={{flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0}}>
          <div style={{display: 'flex', alignItems: 'center'}}>
            <span style={{...bold(14.5, AC.text), whiteSpace: 'nowrap'}}>{title}</span>
            {pending > 0 ? (
              <>
                <div style={{width: SP.xs}} />
                <Pill label={`Waiting on ${pending}`} color={AC.warning} />
              </>
            ) : null}
          </div>
          <span style={{...medium(11.5, AC.textSecondary), marginTop: 3}}>
            {paidBy} paid {rs(cost)}
          </span>
        </div>
        <div style={{width: SP.xs}} />
        <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-end'}}>
          <span style={extraBold(16, meShare !== null ? accent : AC.textTertiary)}>{meShare !== null ? rs(meShare) : '—'}</span>
          <span style={medium(10, awaitingMe ? AC.warning : AC.textTertiary)}>{awaitingMe ? 'your call' : 'your share'}</span>
        </div>
      </div>
      <div style={{display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: SP.xs}}>
        {shares.map((s) => {
          const ok = s.status === 'accepted';
          const color = ok ? AC.success : AC.warning;
          return (
            <div
              key={s.name}
              style={{...decor.pill(color, 0.18), padding: '3px 7px', display: 'flex', alignItems: 'center', gap: 4}}
            >
              <MIcon name={ok ? 'check_circle' : 'schedule'} size={11} color={color} />
              <span style={medium(11, ok ? AC.text : AC.textTertiary)}>{s.name}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

// --- the lunch dashboard (Ali's phone) --------------------------------------

export type LunchState = {
  inviteCollapse: number; // 0 → card shown, 1 → gone (Ali answered)
  countPress: number;
  saraAccepted: boolean; // Sara has answered
  aliAccepted: boolean;
  departed: boolean;
  startPress: number;
  scroll: number;
  rosterAppear: number[]; // per tile
};

export const LunchDashboard: React.FC<{pack: AppPack; s: LunchState}> = ({pack, s}) => {
  const pal = pack.palette;
  const step: NextStep = s.departed ? 'departed' : s.aliAccepted && s.saraAccepted ? 'clear' : s.aliAccepted ? 'waitSara' : 'waitBoth';
  const shares: ShareState[] = [
    {name: 'Bilal', status: 'accepted'},
    {name: 'Sara', status: s.saraAccepted ? 'accepted' : 'pending'},
    {name: 'You', status: s.aliAccepted ? 'accepted' : 'pending'},
  ];
  const accepted = shares.filter((x) => x.status === 'accepted').length;
  // Postgres splits each cost across the accepted people only.
  const myShare = s.aliAccepted ? 480 / accepted : null;
  const inviteH = 222 * (1 - s.inviteCollapse);
  const bottomH = s.departed ? STROKE + SP.xs + 48 + SP.md + SCREEN.gesture : STROKE + SP.xs + 56 + SP.md + SCREEN.gesture;

  return (
    <div style={{position: 'absolute', inset: 0, background: AC.bg}}>
      <StatusBar bg={AC.bg} />
      <AppBarShell leading={<MIcon name="menu" size={24} />} title={<LogoTitle pack={pack} subtitle="Thursday, 15 October" />} />
      <div style={{position: 'absolute', top: BODY_TOP, left: 0, right: 0, bottom: bottomH, overflow: 'hidden'}}>
        <div style={{padding: `${SP.sm}px ${SP.md}px ${SP.huge}px`, transform: `translateY(${-s.scroll}px)`}}>
          <RosterStatusBar locked={s.departed} />
          <div style={{height: SP.md}} />
          {inviteH > 0.5 ? (
            <div style={{height: inviteH, overflow: 'hidden', opacity: 1 - s.inviteCollapse * 0.7}}>
              <PendingInvitesCard pack={pack} countPress={s.countPress} />
            </div>
          ) : null}
          <RunnerCard pack={pack} name="Ali · you" units={12} step={step} startPress={s.startPress} />
          <div style={{height: SP.sm + SP.md}} />
          <SectionHeader
            title="Today's roster"
            count={4}
            action={<PillButton label="AI check" icon="auto_awesome" color={pal.primary} />}
          />
          <div style={{height: SP.sm}} />
          {ROSTER.map((e, i) => (
            <RosterTile key={e.name} pack={pack} e={e} appear={s.rosterAppear[i] ?? 1} />
          ))}
          <div style={{height: SP.lg}} />
          <SectionHeader
            title={titleCase(pack.expensePlural)}
            count={1}
            action={s.departed ? undefined : <PillButton label="Add" icon="add" color={pal.accent} />}
          />
          <div style={{height: SP.sm}} />
          <SharedExpenseTile
            pack={pack}
            title="Extra salan"
            paidBy="Bilal"
            cost={480}
            shares={shares}
            meShare={myShare}
            awaitingMe={!s.aliAccepted}
          />
        </div>
      </div>
      {/* DashboardBottomBar */}
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomH,
          boxSizing: 'border-box',
          background: AC.bg,
          borderTop: `${STROKE}px solid ${AC.ink}`,
          padding: `${SP.xs}px ${SP.lg}px ${SP.md + SCREEN.gesture}px`,
          zIndex: 20,
        }}
      >
        {s.departed ? (
          <div
            style={{
              ...decor.tinted(AC.warning),
              padding: `${SP.sm + 2}px`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: SP.xs,
            }}
          >
            <MIcon name="lock" size={18} color={AC.warning} />
            <span style={semiBold(13, AC.warning)}>Roster locked — Ali left at 1:15 PM</span>
          </div>
        ) : (
          <CustomButton text="Edit my entry" bg={pal.primary} icon="edit" height={56} />
        )}
      </div>
      <GestureHandle />
    </div>
  );
};

// --- the ground booking dashboard -------------------------------------------

const GROUP = ['Bilal', 'You', 'Hina', 'Sara', 'Shan', 'Talha', 'Umar', 'Usman', 'Waqas', 'Yasir', 'Zain', 'Zubair'];

export const GroundDashboard: React.FC<{pack: AppPack; reveal: number[]}> = ({pack, reveal}) => {
  const pal = pack.palette;
  const r = (i: number): React.CSSProperties => ({
    opacity: reveal[i] ?? 1,
    transform: `translateY(${(1 - (reveal[i] ?? 1)) * 14}px)`,
  });
  return (
    <div style={{position: 'absolute', inset: 0, background: AC.bg}}>
      <StatusBar bg={AC.bg} />
      <AppBarShell leading={<MIcon name="menu" size={24} />} title={<LogoTitle pack={pack} subtitle="Thursday, 15 October" />} />
      <div style={{position: 'absolute', top: BODY_TOP, left: 0, right: 0, bottom: 0, overflow: 'hidden'}}>
        <div style={{padding: `${SP.sm}px ${SP.md}px ${SP.huge}px`}}>
          <div style={r(0)}>
            <RunnerCard pack={pack} name="Bilal" units={2} step="clear" />
          </div>
          <div style={{height: SP.sm}} />
          {/* _FactLine: no roster, so the headcount is stated here */}
          <div style={{display: 'flex', alignItems: 'center', marginBottom: SP.sm, ...r(1)}}>
            <AppIcon asset="salan" size={18} />
            <div style={{width: SP.xs}} />
            <span style={AppText.titleSm}>12 in the group</span>
          </div>
          <div style={{height: SP.lg}} />
          <div style={r(2)}>
            <SectionHeader title={titleCase(pack.expensePlural)} count={1} action={<PillButton label="Add" icon="add" color={pal.accent} />} />
            <div style={{height: SP.sm}} />
            <SharedExpenseTile
              pack={pack}
              title="Pitch, 2 hours"
              paidBy="Bilal"
              cost={6000}
              shares={GROUP.map((name) => ({name, status: 'accepted' as const}))}
              meShare={500}
              awaitingMe={false}
            />
          </div>
        </div>
      </div>
      <GestureHandle />
    </div>
  );
};

// --- dialog / toast overlays --------------------------------------------------

export const HeadingOutDialog: React.FC<{pack: AppPack; t: number; confirmPress: number}> = ({pack, t, confirmPress}) =>
  t > 0 ? (
    <>
      <Scrim opacity={Math.min(1, t)} />
      <div
        style={{
          position: 'absolute',
          left: SP.xl,
          right: SP.xl,
          top: '50%',
          transform: `translateY(-50%) scale(${0.92 + 0.08 * Math.min(1, t)})`,
          opacity: Math.min(1, t),
          zIndex: 70,
        }}
      >
        <ConfirmDialog
          icon="directions_run"
          accent={pack.palette.primary}
          title="Heading out?"
          content={`This locks the list at 1 ${pack.expense} plus 12 ${pack.unitPlural}. Nothing can be added after this.`}
          confirmLabel="Lock it & go"
          confirmPress={confirmPress}
        />
      </div>
    </>
  ) : null;

export const ScreenToast: React.FC<{message: string; t: number}> = ({message, t}) => (
  <Toast message={message} t={t} top={SCREEN.status} />
);

// --- ledger -------------------------------------------------------------------

const BentoTile: React.FC<{label: string; value: string; caption: string; svg: string; fill: string; darkText?: boolean}> = ({
  label,
  value,
  caption,
  svg,
  fill,
  darkText,
}) => {
  const fg = darkText ? AC.text : AC.white;
  return (
    <div style={{...decor.filled(fill, {shadow: false}), padding: SP.sm, flex: 1, position: 'relative', overflow: 'hidden'}}>
      <div style={{position: 'absolute', right: -22, bottom: -24, opacity: 0.55}}>
        <AppIcon asset={svg} size={92} />
      </div>
      <div style={{position: 'relative', display: 'flex', flexDirection: 'column'}}>
        <span style={{...monoStyle({fontSize: 11, color: fg, ls: 1.2}), opacity: 0.75, textTransform: 'uppercase'}}>{label}</span>
        <span style={{...monoStyle({fontSize: 38, weight: 800, color: fg, ls: -1.5}), marginTop: SP.sm}}>{value}</span>
        <span style={{...monoStyle({fontSize: 10.5, color: fg, ls: 0.4}), opacity: 0.8, marginTop: 4}}>{caption}</span>
      </div>
    </div>
  );
};

const LEDGER_USERS = [
  {name: 'Ali', units: 3, me: true},
  {name: 'Bilal', units: 4},
  {name: 'Hina', units: 3},
  {name: 'Sara', units: 2},
  {name: 'Shan', units: 0},
];

export const LedgerScreen: React.FC<{pack: AppPack; settled: boolean}> = ({pack, settled}) => {
  const pal = pack.palette;
  const price = settled ? 25 : 0;
  const days = [12, 13, 14, 15, 16, 17];
  const dayName = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  return (
    <div style={{position: 'absolute', inset: 0, background: AC.bg}}>
      <StatusBar bg={AC.bg} />
      <AppBarShell
        leading={<AppIconButton icon="arrow_back" />}
        title={
          <div style={{display: 'flex', flexDirection: 'column'}}>
            <span style={extraBold(22, AC.text)}>{titleCase(pack.unitPlural)} ledger</span>
            <span style={{...AppText.monoLabel, marginTop: 2}}>OCTOBER 2026</span>
          </div>
        }
      />
      <div style={{position: 'absolute', top: BODY_TOP, left: 0, right: 0, bottom: 0, overflow: 'hidden'}}>
        {/* MonthNavBar */}
        <div style={{background: AC.surface, borderBottom: `${STROKE}px solid ${AC.border}`, padding: `${SP.sm}px ${SP.md}px`}}>
          <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
            <AppIconButton icon="chevron_left" />
            <div
              style={{
                background: AC.surfaceAlt,
                borderRadius: RAD.sm,
                border: `1px solid ${AC.border}`,
                padding: `4px ${SP.sm + 2}px`,
                display: 'flex',
                alignItems: 'center',
                gap: 4,
              }}
            >
              <span style={AppText.h3}>October 2026</span>
              <MIcon name="arrow_drop_down" size={20} color={pal.primary} />
            </div>
            <AppIconButton icon="chevron_right" enabled={false} />
          </div>
          <div style={{...AppText.monoLabel, textAlign: 'center', marginTop: 6}}>
            11 DAYS · 132 {pack.unitPlural.toUpperCase()}
            {settled ? ' · RS 3300' : ''}
          </div>
        </div>
        {/* MonthSummary */}
        <div style={{display: 'flex', gap: SP.sm, padding: SP.xs}}>
          <BentoTile label={`Your ${pack.unitPlural}`} value="33" caption={settled ? rs(33 * price) : 'not billed yet'} svg="roti" fill={pal.primaryDeep} />
          <BentoTile
            label={`Total ${pack.unitPlural}`}
            value="132"
            caption={settled ? rs(132 * price) : 'not billed yet'}
            svg="team"
            fill={pal.accentFill}
            darkText
          />
        </div>
        {/* date strip */}
        <div
          style={{
            height: 82,
            boxSizing: 'border-box',
            background: AC.surface,
            borderBottom: `${STROKE}px solid ${AC.border}`,
            padding: `${SP.xs}px ${SP.md}px`,
            display: 'flex',
            gap: SP.xs,
            overflow: 'hidden',
          }}
        >
          {days.map((d, i) => {
            const sel = d === 15;
            const hasUnits = d <= 15 && i < 4;
            return (
              <div
                key={d}
                style={{
                  width: 60,
                  flexShrink: 0,
                  boxSizing: 'border-box',
                  padding: '8px 0',
                  background: sel ? pal.primary : AC.surface,
                  borderRadius: RAD.md,
                  border: `${sel ? 2 : STROKE}px solid ${sel ? pal.primary : AC.border}`,
                  boxShadow: sel ? SHADOW.card : undefined,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <span style={monoStyle({fontSize: 10.5, weight: 700, color: sel ? AC.white : AC.textTertiary})}>{dayName[i]}</span>
                <span style={{...monoStyle({fontSize: 18, weight: 800, color: sel ? AC.white : AC.text}), marginTop: 3}}>{d}</span>
                {hasUnits ? (
                  <div style={{width: 5, height: 5, borderRadius: 5, marginTop: 2, background: sel ? pal.accent : pal.primary}} />
                ) : (
                  <div style={{height: 7}} />
                )}
              </div>
            );
          })}
        </div>
        <div style={{padding: `${SP.md}px ${SP.md}px`}}>
          {!settled ? (
            <div style={{...decor.tinted(AC.warning), padding: SP.sm, display: 'flex', alignItems: 'flex-start', gap: SP.xs, marginBottom: SP.md}}>
              <MIcon name="info_outline" size={17} color={AC.warning} />
              <span style={medium(12, AC.warning)}>
                11 days have {pack.unitPlural} but no bill entered yet — those aren't counted in the totals.
              </span>
            </div>
          ) : null}
          <div style={{display: 'flex', justifyContent: 'space-between'}}>
            <span style={{...AppText.monoLabel, color: pal.primary}}>THURSDAY, 15 OCTOBER</span>
            <span style={AppText.monoLabel}>
              12 {pack.unitPlural.toUpperCase()} TOTAL{settled ? ' · RS 300' : ''}
            </span>
          </div>
          <div style={{height: SP.sm}} />
          {LEDGER_USERS.map((u) => (
            <div
              key={u.name}
              style={{
                ...decor.card({color: u.me ? pal.primarySoft : AC.surface}),
                padding: SP.md,
                marginBottom: SP.sm,
                display: 'flex',
                alignItems: 'center',
              }}
            >
              <UserAvatar name={u.name} tintColor={pal.primary} />
              <div style={{width: SP.md}} />
              <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>
                <span style={bold(15, AC.text)}>{u.me ? `${u.name} (You)` : u.name}</span>
                <span style={{...AppText.monoLabel, color: u.units > 0 ? pal.primary : AC.textTertiary, marginTop: 2}}>
                  {u.units} {pack.unitPlural.toUpperCase()}
                  {settled && u.units > 0 ? ` · ${rs(u.units * price).toUpperCase()}` : ''}
                </span>
              </div>
              <div
                style={{
                  padding: `${SP.xs + 2}px ${SP.md - 2}px`,
                  background: u.units > 0 ? pal.accent : AC.surfaceAlt,
                  borderRadius: RAD.sm,
                  border: `${STROKE}px solid ${u.units > 0 ? pal.accent : AC.border}`,
                  boxShadow: u.units > 0 ? SHADOW.card : undefined,
                }}
              >
                <span style={monoStyle({fontSize: 17, weight: 800, color: u.units > 0 ? AC.white : AC.textTertiary})}>{u.units}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
      <GestureHandle />
    </div>
  );
};

/** SettleMonthSheet with BillTotalTile. */
export const SettleSheet: React.FC<{pack: AppPack; price: string; settlePress: number; focused: boolean}> = ({
  pack,
  price,
  settlePress,
  focused,
}) => {
  const pal = pack.palette;
  const total = 132 * (parseInt(price || '0', 10) || 0);
  return (
    <div
      style={{
        background: AC.surface,
        borderTopLeftRadius: RAD.xl,
        borderTopRightRadius: RAD.xl,
        border: `${STROKE}px solid ${AC.ink}`,
        borderBottom: 'none',
        padding: `${SP.md}px ${SP.lg}px ${SP.xl + SCREEN.gesture}px`,
      }}
    >
      <div style={{width: 44, height: 5, background: AC.ink, margin: `0 auto ${SP.lg}px`}} />
      {/* BillTotalTile */}
      <div style={{...decor.filled(pal.primaryDeep, {radius: RAD.lg, shadow: false}), padding: SP.md, position: 'relative', overflow: 'hidden'}}>
        <MIcon name="restaurant" size={110} color="rgba(255,255,255,0.10)" style={{position: 'absolute', top: -18, right: -14}} />
        <div style={{position: 'relative'}}>
          <div style={monoStyle({fontSize: 12, color: 'rgba(255,255,255,0.8)', ls: 1.4})}>TOTAL BILL</div>
          <div style={{display: 'flex', alignItems: 'baseline', marginTop: SP.xs}}>
            <span style={monoStyle({fontSize: 22, weight: 800, color: 'rgba(255,255,255,0.55)'})}>Rs</span>
            <span style={{...monoStyle({fontSize: 48, weight: 800, color: AC.white, ls: -2}), marginLeft: 6}}>{total}</span>
          </div>
          <div
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 6,
              marginTop: SP.sm,
              padding: `5px ${SP.sm}px`,
              background: AC.ink,
              borderRadius: RAD.xs,
              border: `1px solid ${AC.white}`,
            }}
          >
            <MIcon name="calendar_today" size={12} color={AC.white} />
            <span style={monoStyle({fontSize: 12, color: AC.white, ls: 0.6})}>October 2026</span>
          </div>
        </div>
      </div>
      {/* CustomTextField */}
      <div style={{marginTop: SP.md}}>
        <div style={semiBold(12.5, focused ? pal.primary : AC.textSecondary)}>Price per {pack.unit}</div>
        <div
          style={{
            marginTop: SP.xs,
            height: 48,
            boxSizing: 'border-box',
            borderRadius: RAD.sm,
            border: `${focused ? 1.5 : 1}px solid ${focused ? pal.primary : AC.border}`,
            background: AC.surface,
            boxShadow: focused ? SHADOW.card : undefined,
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <span style={{...bold(13, focused ? pal.primary : AC.textTertiary), padding: `0 6px 0 ${SP.sm}px`}}>Rs</span>
          {/* Empty: the caret sits before the hint. Typed: after the digits. */}
          {focused && !price ? <div style={{width: 2, height: 18, background: pal.primary, borderRadius: 2, marginRight: 1}} /> : null}
          <span style={price ? medium(14.5, AC.text) : regular(14, AC.textTertiary)}>{price || 'e.g. 25'}</span>
          {focused && price ? <div style={{width: 2, height: 18, background: pal.primary, borderRadius: 2, marginLeft: 1}} /> : null}
        </div>
        <div style={{...AppText.caption, marginTop: 6}}>132 {pack.unitPlural} across 11 days</div>
      </div>
      <div style={{...AppText.caption, marginTop: SP.sm}}>
        {titleCase(pack.expensePlural)} are billed too, at the split everyone already agreed to.
      </div>
      <div style={{height: SP.lg}} />
      <CustomButton text="Settle October" bg={pal.primaryDeep} icon="check_circle_outline" height={56} press={settlePress} />
    </div>
  );
};

// --- drawer + Theme sheet -------------------------------------------------------

const DrawerRow: React.FC<{
  svg?: string;
  icon?: string;
  accent: string;
  title: string;
  subtitle?: string;
  active?: boolean;
  tinted?: boolean;
  chevron?: boolean;
  badge?: string;
  trailing?: React.ReactNode;
  pressed?: number;
}> = ({svg, icon, accent, title, subtitle, active, tinted, chevron, badge, trailing, pressed = 0}) => {
  const bg = tinted ? tint(accent, 0.12) : active ? tint(accent, 0.14) : pressed > 0.5 ? AC.surfaceAlt : 'transparent';
  const iconFill = tint(accent, tinted || active ? 0.3 : 0.22);
  return (
    <div
      style={{
        marginBottom: SP.xxs,
        padding: `${SP.xs + 2}px ${SP.sm}px`,
        background: bg,
        borderRadius: RAD.sm,
        display: 'flex',
        alignItems: 'center',
      }}
    >
      <div style={{width: 36, height: 36, background: iconFill, borderRadius: RAD.xs, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        {svg ? <AppIcon asset={svg} size={20} /> : <MIcon name={icon!} size={19} color={accent} />}
      </div>
      <div style={{width: SP.sm}} />
      <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>
        <span style={active ? bold(15, AC.text) : semiBold(15, tinted ? accent : AC.text)}>{title}</span>
        {subtitle ? <span style={{...AppText.caption, marginTop: 1}}>{subtitle}</span> : null}
      </div>
      {trailing ??
        (badge ? (
          <div style={{...decor.pill(accent, 0.3), padding: '3px 7px', marginLeft: SP.sm}}>
            <span style={monoStyle({fontSize: 9, weight: 700, ls: 0.8})}>{badge.toUpperCase()}</span>
          </div>
        ) : chevron ? (
          <MIcon name="chevron_right" size={20} color={AC.textTertiary} style={{marginLeft: SP.sm}} />
        ) : null)}
    </div>
  );
};

const SectionLabel: React.FC<{text: string; danger?: boolean}> = ({text, danger}) => (
  <div style={{display: 'flex', alignItems: 'center', padding: `${SP.xl}px ${SP.sm}px ${SP.xs}px`}}>
    <span style={{...AppText.monoLabel, color: danger ? AC.danger : AC.textSecondary}}>{text}</span>
    <div style={{width: SP.sm}} />
    <div style={{flex: 1, height: STROKE, background: danger ? tint(AC.danger, 0.45) : AC.border}} />
  </div>
);

export const DRAWER_W = Math.round(SCREEN.w * 0.82);

export const Drawer: React.FC<{pack: AppPack; themePress: number}> = ({pack, themePress}) => {
  const pal = pack.palette;
  return (
    <div
      style={{
        width: DRAWER_W,
        height: SCREEN.h,
        background: AC.bg,
        borderTopRightRadius: RAD.xl,
        borderBottomRightRadius: RAD.xl,
        borderRight: `${STROKE}px solid ${AC.ink}`,
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <div
        style={{
          background: pal.primaryDeep,
          borderBottom: `${STROKE}px solid ${AC.ink}`,
          padding: `${SCREEN.status + SP.lg}px ${SP.md}px ${SP.lg}px ${SP.lg}px`,
          display: 'flex',
          alignItems: 'center',
        }}
      >
        <UserAvatar name="Ali" size={56} tintColor={pal.primary} />
        <div style={{width: SP.md}} />
        <div style={{flex: 1, display: 'flex', flexDirection: 'column'}}>
          <span style={extraBold(18, AC.white)}>Ali</span>
          <span style={{...monoStyle({fontSize: 10.5, color: AC.textOnBrandMuted, ls: 1.2}), marginTop: 3}}>ADMIN</span>
        </div>
        <MIcon name="edit" size={18} color={AC.textOnBrandMuted} />
      </div>
      <div style={{padding: `${SP.sm}px ${SP.xs}px`}}>
        <DrawerRow svg="tandoor" accent={pal.primary} title="Today" active />
        <DrawerRow svg="roti" accent={pal.secondary} title="Ledger" chevron />
        <SectionLabel text="SETTINGS" />
        <DrawerRow svg="sparkle" accent={AC.info} title="Theme" badge={pack.activityName} pressed={themePress} />
        <DrawerRow
          svg="sun"
          accent={AC.info}
          title="Dark mode"
          trailing={
            <div
              style={{
                width: 62,
                height: 32,
                boxSizing: 'border-box',
                padding: 3,
                marginLeft: SP.sm,
                borderRadius: RAD.xs,
                background: pal.primaryFixed,
                border: `${STROKE}px solid ${AC.ink}`,
                boxShadow: SHADOW.card,
                position: 'relative',
              }}
            >
              <AppIcon asset="moon" size={14} style={{position: 'absolute', right: 9, top: 8}} />
              <div
                style={{
                  width: 26,
                  height: 26,
                  boxSizing: 'border-box',
                  borderRadius: 2,
                  background: AC.white,
                  border: `${STROKE}px solid ${AC.ink}`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <AppIcon asset="sun" size={15} />
              </div>
            </div>
          }
        />
        <SectionLabel text="DANGER ZONE" danger />
        <DrawerRow icon="delete_forever" accent={AC.danger} tinted title="Reset today's data" subtitle={`Wipes ${pack.activityName} only`} />
      </div>
    </div>
  );
};

const PackOption: React.FC<{pack: AppPack; selected: boolean; pressed: number}> = ({pack, selected, pressed}) => {
  const accent = pack.palette.primary;
  const swatch = [pack.palette.primaryDeep, pack.palette.primary, pack.palette.accentFill, pack.palette.primaryFixed];
  return (
    <div
      style={{
        background: selected ? tint(accent, 0.12) : AC.surface,
        borderRadius: 12,
        border: `${STROKE}px solid ${selected ? accent : AC.border}`,
        boxShadow: pressed > 0.5 ? undefined : SHADOW.card,
        padding: SP.sm,
        display: 'flex',
        alignItems: 'center',
        transform: `translateY(${3 * pressed}px) scale(${1 - 0.03 * pressed})`,
        marginBottom: SP.xs,
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          boxSizing: 'border-box',
          padding: 7,
          background: tint(accent, 0.2),
          borderRadius: 4,
          border: `${STROKE}px solid ${AC.ink}`,
          display: 'flex',
        }}
      >
        <AppIcon asset="roti" size={28} />
      </div>
      <div style={{width: SP.sm}} />
      <div style={{flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0}}>
        <span style={extraBold(16, AC.text)}>{pack.activityName}</span>
        <span style={{...medium(12, AC.textSecondary), marginTop: 3}}>{packSummary(pack)}</span>
        <div
          style={{
            marginTop: 7,
            height: 12,
            boxSizing: 'border-box',
            borderRadius: 4,
            border: `1px solid ${AC.ink}`,
            overflow: 'hidden',
            display: 'flex',
          }}
        >
          {swatch.map((c) => (
            <div key={c} style={{flex: 1, background: c}} />
          ))}
        </div>
      </div>
      <div style={{width: SP.xs}} />
      <div
        style={{
          width: 26,
          height: 26,
          boxSizing: 'border-box',
          background: selected ? accent : AC.surfaceAlt,
          borderRadius: 4,
          border: `${STROKE}px solid ${AC.ink}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
      >
        {selected ? <MIcon name="check" size={17} color={AC.white} /> : null}
      </div>
    </div>
  );
};

/** PackPickerSheet. `running` is the pack the app is wearing right now. */
export const ThemeSheet: React.FC<{running: AppPack; packs: AppPack[]; selectedId: string; groundPress: number}> = ({
  running,
  packs,
  selectedId,
  groundPress,
}) => (
  <div
    style={{
      background: AC.surface,
      borderTopLeftRadius: RAD.xl,
      borderTopRightRadius: RAD.xl,
      border: `${STROKE}px solid ${AC.ink}`,
      borderBottom: 'none',
      padding: `${SP.md}px ${SP.lg}px ${SCREEN.gesture + SP.xl}px`,
    }}
  >
    <div style={{width: 44, height: 5, background: AC.ink, margin: `0 auto ${SP.lg}px`}} />
    <div style={{...decor.filled(running.palette.primaryDeep), padding: SP.md}}>
      <div style={extraBold(22, AC.white, -0.4)}>Theme</div>
      <div style={{...medium(14, 'rgba(255,255,255,0.82)', undefined, 1.45), marginTop: 6}}>
        Changes the colours, the shapes, what everything is called and which parts of the app you get. Picking one reloads the
        app.
      </div>
    </div>
    <div style={{height: SP.sm}} />
    {packs.map((p) => (
      <PackOption key={p.id} pack={p} selected={p.id === selectedId} pressed={p.id === 'ground_booking' ? groundPress : 0} />
    ))}
    <div style={{height: SP.sm}} />
    <CustomButton text="Done" bg={running.palette.primaryDeep} icon="check" height={56} />
  </div>
);

