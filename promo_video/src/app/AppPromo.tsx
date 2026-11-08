// The app-accurate cut: same story beats and motion language as the first
// film, but every phone frame is the Flutter app's own UI, rebuilt from
// lib/ (see ./screens.tsx) and driven through its real flow.
import React from 'react';
import {AbsoluteFill, Html5Audio, Img, staticFile, useCurrentFrame} from 'remotion';
import {backOut, expoIn, expoOut, inOut, lerp, prog, quintOut} from '../anim';
import {Echo} from '../components/Echo';
import {Hud} from '../components/Hud';
import {HalftoneIris} from '../components/Transitions';
import {Accent, MonoLabel, Words} from '../components/Type';
import {ChatScene} from '../scenes/ChatScene';
import {c as vc, sans as videoSans} from '../theme';
import {AC, AppPack, extraBold, groundBooking, mixHex, monoStyle, officeLunch, packSummary, rgba, roboto, SHADOW} from './flutter';
import {
  DEVICE,
  DEVICE_H,
  DEVICE_W,
  Drawer,
  DRAWER_W,
  GroundDashboard,
  HeadingOutDialog,
  LedgerScreen,
  LunchDashboard,
  LunchState,
  Phone,
  SCREEN,
  ScreenToast,
  Scrim,
  SettleSheet,
  SplashScreen,
  ThemeSheet,
} from './screens';
import T from './timeline_app.json';

const L = officeLunch;
const G = groundBooking;

// --- camera ------------------------------------------------------------------
type Cam = {s: number; fx: number; fy: number; tx: number; ty: number};
const B = DEVICE.bezel;
const OVER: Cam = {s: 1, fx: DEVICE_W / 2, fy: DEVICE_H / 2, tx: 1400, ty: 540};
const INVITE: Cam = {s: 2, fx: DEVICE_W / 2, fy: 372, tx: 1360, ty: 540};
const RUNNER: Cam = {s: 2, fx: DEVICE_W / 2, fy: 300, tx: 1360, ty: 540};
const DIALOG: Cam = {s: 1.75, fx: DEVICE_W / 2, fy: 470, tx: 1360, ty: 540};
const SHEET: Cam = {s: 1.55, fx: DEVICE_W / 2, fy: 660, tx: 1360, ty: 560};
const THEME: Cam = {s: 1.45, fx: DEVICE_W / 2, fy: 650, tx: 1360, ty: 560};
const GROUND: Cam = {s: 1.6, fx: DEVICE_W / 2, fy: 330, tx: 1360, ty: 540};

const whip = (t: number) => (t < 0.5 ? expoIn(t * 2) / 2 : 0.5 + expoOut((t - 0.5) * 2) / 2);

const KEYS: {f: number; cam: Cam; ease?: (t: number) => number}[] = [
  {f: 0, cam: OVER},
  {f: T.overview.pushStart, cam: OVER},
  {f: T.overview.pushEnd, cam: INVITE, ease: whip},
  {f: T.invite.collapse, cam: INVITE},
  // The list itself scrolls to the shared meal and back; the camera holds.
  {f: T.invite.collapse + 12, cam: RUNNER, ease: inOut},
  {f: T.lock.pressStart + 4, cam: RUNNER},
  {f: T.lock.dialog + 12, cam: DIALOG, ease: inOut},
  {f: T.lock.pullBack, cam: DIALOG},
  {f: T.lock.pullBack + 16, cam: OVER, ease: inOut},
  {f: T.ledger.sheet, cam: OVER},
  {f: T.ledger.sheet + 12, cam: SHEET, ease: inOut},
  {f: T.ledger.pullBack, cam: SHEET},
  {f: T.ledger.pullBack + 14, cam: OVER, ease: inOut},
  {f: T.packs.sheet, cam: OVER},
  {f: T.packs.sheet + 12, cam: THEME, ease: inOut},
  {f: T.packs.reload, cam: THEME},
  {f: T.packs.groundIn + 6, cam: GROUND, ease: inOut},
];

const camAt = (f: number): Cam => {
  let prev = KEYS[0];
  for (const k of KEYS) {
    if (f < k.f) {
      const t = (k.ease ?? inOut)(Math.min(1, Math.max(0, (f - prev.f) / (k.f - prev.f))));
      const a = prev.cam;
      const b = k.cam;
      return {
        s: a.s * Math.pow(b.s / a.s, t),
        fx: lerp(a.fx, b.fx, t),
        fy: lerp(a.fy, b.fy, t),
        tx: lerp(a.tx, b.tx, t),
        ty: lerp(a.ty, b.ty, t),
      };
    }
    prev = k;
  }
  return prev.cam;
};

/** A finger: Android's "show taps" dot, pressing then lifting. */
const Tap: React.FC<{x: number; y: number; at: number; f: number}> = ({x, y, at, f}) => {
  const appear = prog(f, at - 6, 6, expoOut);
  const lift = prog(f, at + 4, 8, expoOut);
  if (f < at - 6 || lift >= 1) return null;
  const press = f >= at && f < at + 4 ? 1 : 0;
  const r = 22 * (1 - 0.15 * press) * (0.7 + 0.3 * appear);
  const ring = prog(f, at, 10, expoOut);
  return (
    <>
      {f >= at ? (
        <div
          style={{
            position: 'absolute',
            left: x - 22 - ring * 26,
            top: y - 22 - ring * 26,
            width: 44 + ring * 52,
            height: 44 + ring * 52,
            borderRadius: '50%',
            border: `2px solid ${rgba(AC.ink, 0.35)}`,
            opacity: 1 - ring,
            zIndex: 95,
          }}
        />
      ) : null}
      <div
        style={{
          position: 'absolute',
          left: x - r,
          top: y - r,
          width: r * 2,
          height: r * 2,
          borderRadius: '50%',
          background: rgba(AC.ink, 0.28),
          border: '2px solid rgba(255,255,255,0.85)',
          opacity: appear * (1 - lift),
          zIndex: 96,
        }}
      />
    </>
  );
};

const pressAt = (f: number, at: number) => (f >= at && f < at + 4 ? 1 : f >= at + 4 && f < at + 6 ? 1 - (f - at - 4) / 2 : 0);

// Tap targets, in screen (not device) coordinates; checked against renders.
const TAPS = {
  countMeIn: {x: 262, y: 309},
  startRun: {x: 206, y: 307},
  lockItGo: {x: 291, y: 534},
  priceField: {x: 206, y: 716},
  settle: {x: 206, y: 842},
  theme: {x: 140, y: 338},
  ground: {x: 206, y: 748},
};

// --- what the phone shows ----------------------------------------------------
const lunchStateAt = (f: number): LunchState => ({
  inviteCollapse: prog(f, T.invite.collapse, 8, inOut),
  countPress: pressAt(f, T.invite.press),
  aliAccepted: f >= T.invite.toast,
  saraAccepted: f >= T.invite.saraAccepts,
  departed: f >= T.lock.locked,
  startPress: pressAt(f, T.lock.pressStart),
  // Down to the shared meal to watch it re-split, then back to the runner card.
  scroll: 395 * prog(f, T.invite.scrollDown, 14, inOut) * (1 - prog(f, T.invite.scrollUp, 12, inOut)),
  rosterAppear: [1, 1, 1, 1],
});

const fadeWindow = (f: number, a: number, b: number, inDur = 6, outDur = 6) => prog(f, a, inDur) * (1 - prog(f, b - outDur, outDur));

const ScreenContent: React.FC<{f: number}> = ({f}) => {
  const s = lunchStateAt(f);
  const LEDGER_POP = T.ledger.pop;
  // Splash → dashboard: the app's own 350 ms easeOut dissolve.
  const launch = prog(f, T.splash.launch, 10, expoOut);
  // Ledger push / pop: Android's fade-forwards page transition.
  const push = prog(f, T.ledger.push, 10, quintOut);
  const pop = prog(f, LEDGER_POP, 10, quintOut);
  const ledgerVis = push * (1 - pop);
  const settled = f >= T.ledger.settled;
  const typed = f >= T.ledger.type[1] ? '25' : f >= T.ledger.type[0] ? '2' : '';

  const sheetIn = prog(f, T.ledger.sheet, 9, quintOut) * (1 - prog(f, T.ledger.pressSettle + 5, 7, inOut));
  const drawerIn = prog(f, T.packs.drawer, 9, quintOut) * (1 - prog(f, T.packs.tapTheme + 4, 7, inOut));
  const themeIn = prog(f, T.packs.sheet, 9, quintOut);
  const ground = f >= T.packs.tapGround + 4;
  const wipe = prog(f, T.packs.reload, 10, inOut);
  const tapG = {x: TAPS.ground.x, y: TAPS.ground.y};

  return (
    <>
      {/* base: splash, then the lunch dashboard */}
      {f < T.splash.launch + 10 ? (
        <SplashScreen
          pack={L}
          fade={prog(f, T.splash.rise, 18, expoOut)}
          rise={14 * (1 - prog(f, T.splash.rise, 18, quintOut))}
          shuttle={Math.max(0, f - T.splash.rise) / 27}
        />
      ) : null}
      {f >= T.splash.launch ? (
        <div style={{position: 'absolute', inset: 0, opacity: launch}}>
          <LunchDashboard pack={L} s={s} />
        </div>
      ) : null}

      {/* invite → accept */}
      <ScreenToast message="You're in on Extra salan ✅" t={fadeWindow(f, T.invite.toast, T.lock.pressStart - 2)} />
      <HeadingOutDialog
        pack={L}
        t={prog(f, T.lock.dialog, 6, expoOut) * (1 - prog(f, T.lock.pressLock + 5, 5, inOut))}
        confirmPress={pressAt(f, T.lock.pressLock)}
      />
      <ScreenToast message="Off on the tandoor run — list locked 🏃" t={fadeWindow(f, T.lock.toast, T.ledger.push)} />

      {/* ledger page + settle sheet */}
      {ledgerVis > 0 ? (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            opacity: ledgerVis,
            transform: `translateX(${(1 - push) * 60 + pop * 60}px)`,
            zIndex: 80,
          }}
        >
          <LedgerScreen pack={L} settled={settled} />
          <Scrim opacity={sheetIn} />
          {sheetIn > 0 ? (
            <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, transform: `translateY(${(1 - sheetIn) * 100}%)`, zIndex: 70}}>
              <SettleSheet pack={L} price={typed} settlePress={pressAt(f, T.ledger.pressSettle)} focused={f >= T.ledger.tapField} />
            </div>
          ) : null}
          <ScreenToast message="October settled 💰" t={fadeWindow(f, T.ledger.toast, LEDGER_POP)} />
        </div>
      ) : null}

      {/* drawer → Theme sheet */}
      {drawerIn > 0 ? (
        <>
          <Scrim opacity={drawerIn} alpha={0.54} />
          <div style={{position: 'absolute', left: 0, top: 0, transform: `translateX(${(drawerIn - 1) * (DRAWER_W + 4)}px)`, zIndex: 85}}>
            <Drawer pack={L} themePress={pressAt(f, T.packs.tapTheme)} />
          </div>
        </>
      ) : null}
      {themeIn > 0 && f < T.packs.reload + 10 ? (
        <>
          <Scrim opacity={themeIn} />
          <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, transform: `translateY(${(1 - themeIn) * 100}%)`, zIndex: 86}}>
            <ThemeSheet
              running={ground ? G : L}
              packs={[L, G]}
              selectedId={ground ? G.id : L.id}
              groundPress={pressAt(f, T.packs.tapGround)}
            />
          </div>
        </>
      ) : null}

      {/* the app restarts wearing the new pack */}
      {f >= T.packs.reload ? (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            clipPath: `circle(${wipe * 1100}px at ${tapG.x}px ${tapG.y}px)`,
            zIndex: 90,
          }}
        >
          <GroundDashboard
            pack={G}
            reveal={T.packs.rows.map((r) => prog(f, r, 12, expoOut))}
          />
        </div>
      ) : null}

      {/* fingers */}
      <Tap x={TAPS.countMeIn.x} y={TAPS.countMeIn.y} at={T.invite.press} f={f} />
      <Tap x={TAPS.startRun.x} y={TAPS.startRun.y} at={T.lock.pressStart} f={f} />
      <Tap x={TAPS.lockItGo.x} y={TAPS.lockItGo.y} at={T.lock.pressLock} f={f} />
      <Tap x={TAPS.priceField.x} y={TAPS.priceField.y} at={T.ledger.tapField} f={f} />
      <Tap x={TAPS.settle.x} y={TAPS.settle.y} at={T.ledger.pressSettle} f={f} />
      <Tap x={TAPS.theme.x} y={TAPS.theme.y} at={T.packs.tapTheme} f={f} />
      <Tap x={TAPS.ground.x} y={TAPS.ground.y} at={T.packs.tapGround} f={f} />
    </>
  );
};

/** The handset on the camera. Reads its own frame so Echo can lag it. */
const DeviceStage: React.FC = () => {
  const f = useCurrentFrame();
  const cam = camAt(f);
  const morphing = f < T.splash.morphEnd;
  return (
    <AbsoluteFill>
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: DEVICE_W,
          height: DEVICE_H,
          transformOrigin: '0 0',
          transform: `translate(${cam.tx - cam.s * cam.fx}px, ${cam.ty - cam.s * cam.fy}px) scale(${cam.s})`,
          opacity: morphing ? prog(f, T.splash.morphStart + 4, 12, expoOut) : 1,
        }}
      >
        <Phone>{morphing ? null : <ScreenContent f={f} />}</Phone>
      </div>
    </AbsoluteFill>
  );
};

/** Splash full-bleed, shrinking into the phone's screen. */
const SplashField: React.FC = () => {
  const f = useCurrentFrame();
  const m = prog(f, T.splash.morphStart, T.splash.morphEnd - T.splash.morphStart, inOut);
  const sx = OVER.tx - OVER.fx + B;
  const sy = OVER.ty - OVER.fy + B;
  const x = lerp(0, sx, m);
  const y = lerp(0, sy, m);
  const w = lerp(1920, SCREEN.w, m);
  const h = lerp(1080, SCREEN.h, m);
  const k = lerp(2.15, 1, m);
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        borderRadius: lerp(0, DEVICE.radius - B, m),
        overflow: 'hidden',
        background: L.palette.primaryDeep,
      }}
    >
      <div
        style={{
          position: 'absolute',
          left: w / 2 - SCREEN.w / 2,
          top: h / 2 - SCREEN.h / 2,
          width: SCREEN.w,
          height: SCREEN.h,
          transform: `scale(${k})`,
        }}
      >
        <SplashScreen
          pack={L}
          fade={prog(f, T.splash.rise, 18, expoOut)}
          rise={14 * (1 - prog(f, T.splash.rise, 18, quintOut))}
          shuttle={Math.max(0, f - T.splash.rise) / 27}
        />
      </div>
    </div>
  );
};

// --- narration -----------------------------------------------------------------
const Headline: React.FC<{
  from: number;
  to: number;
  label: string;
  line1: string;
  line2?: string;
  accent: string;
  at: number[];
  color: string;
}> = ({from, to, label, line1, line2, accent, at, color}) => {
  const f = useCurrentFrame();
  if (f < from - 2 || f >= to) return null;
  const out = prog(f, to - 7, 7, expoIn);
  return (
    <div
      style={{
        position: 'absolute',
        left: 130,
        top: 380,
        opacity: 1 - out,
        transform: `translateY(${-out * 30}px)`,
      }}
    >
      <MonoLabel at={from} text={label} color={vc.textTertiary} size={25} />
      <div
        style={{
          marginTop: 24,
          fontFamily: videoSans,
          fontWeight: 600,
          fontSize: 100,
          lineHeight: 1.08,
          letterSpacing: '-0.035em',
          color: vc.text,
        }}
      >
        <div style={{whiteSpace: 'nowrap'}}>
          <Words text={line1} at={at[0]} />
        </div>
        <div style={{whiteSpace: 'nowrap'}}>
          {line2 ? (
            <>
              <Words text={line2} at={at[1]} />{' '}
            </>
          ) : null}
          <Accent at={at[at.length - 1]} color={color}>
            {accent}
          </Accent>
        </div>
      </div>
    </div>
  );
};

const Narration: React.FC = () => {
  const f = useCurrentFrame();
  const packAccent = mixHex(L.palette.accent, G.palette.accent, prog(f, T.packs.reload, 10));
  return (
    <>
      <Headline
        from={T.overview.headline[0] - 4}
        to={T.invite.headline[0] - 3}
        label="// one list, one runner"
        line1="One list."
        line2="Zero"
        accent="arguments."
        at={T.overview.headline}
        color={L.palette.primary}
      />
      <Headline
        from={T.invite.headline[0] - 2}
        to={T.lock.headline[0] - 3}
        label="// shared meals"
        line1="A cost is an"
        accent="invite."
        at={T.invite.headline}
        color={L.palette.accent}
      />
      <Headline
        from={T.lock.headline[0] - 2}
        to={T.ledger.headline[0] - 3}
        label="// the tandoor run"
        line1="Runner leaves."
        line2="List"
        accent="locks."
        at={[T.lock.headline[0], T.lock.headline[1], T.lock.headline[1] + 6]}
        color={L.palette.primary}
      />
      <Headline
        from={T.ledger.headline[0] - 2}
        to={T.packs.headline[0] - 3}
        label="// month-end ledger"
        line1="One price"
        line2="per"
        accent="roti."
        at={[T.ledger.headline[0], T.ledger.headline[1], T.ledger.headline[1] + 5]}
        color={L.palette.accent}
      />
      <Headline
        from={T.packs.headline[0] - 2}
        to={T.end.irisFull}
        label="// activity packs"
        line1="Same app."
        line2="New"
        accent="pack."
        at={T.packs.headline}
        color={packAccent}
      />
    </>
  );
};

// --- end card --------------------------------------------------------------------
const PackChip: React.FC<{pack: AppPack; at: number}> = ({pack, at}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, 14, backOut);
  const sw = [pack.palette.primaryDeep, pack.palette.primary, pack.palette.accentFill, pack.palette.primaryFixed];
  return (
    <div
      style={{
        background: AC.surface,
        border: `2px solid ${AC.ink}`,
        borderRadius: 18,
        boxShadow: SHADOW.raised,
        padding: '16px 22px',
        width: 440,
        opacity: prog(f, at, 5),
        transform: `translateY(${(1 - p) * 30}px) scale(${0.9 + 0.1 * p})`,
      }}
    >
      <div style={{...extraBold(30, AC.text), fontFamily: roboto}}>{pack.activityName}</div>
      <div style={{...monoStyle({fontSize: 15, color: AC.textSecondary, ls: 0.4, h: 1.3}), fontWeight: 500, marginTop: 4}}>{packSummary(pack)}</div>
      <div style={{display: 'flex', height: 18, marginTop: 12, border: `2px solid ${AC.ink}`, borderRadius: 6, overflow: 'hidden'}}>
        {sw.map((col) => (
          <div key={col} style={{flex: 1, background: col}} />
        ))}
      </div>
    </div>
  );
};

const AppEnd: React.FC = () => {
  const f = useCurrentFrame();
  const logo = prog(f, T.end.letters - 2, 18, backOut);
  const letters = 'Bite Size'.split('');
  return (
    <AbsoluteFill style={{background: AC.bg, alignItems: 'center', justifyContent: 'center'}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 34}}>
        <Img
          src={staticFile('app/icon/logo.png')}
          style={{
            width: 230,
            height: 230,
            transform: `translateY(${(1 - logo) * 80}px) rotate(${(1 - logo) * -12}deg) scale(${0.6 + 0.4 * logo})`,
            opacity: prog(f, T.end.letters - 2, 5),
          }}
        />
        <div>
          <div style={{display: 'flex', fontFamily: roboto, fontWeight: 800, fontSize: 168, letterSpacing: -5, color: AC.text, lineHeight: 1}}>
            {letters.map((l, i) => {
              const p = prog(f, T.end.letters + 4 + i * 2, 16, backOut);
              return (
                <span key={i} style={{display: 'inline-block', overflow: 'hidden', padding: '0.06em 0.02em 0.1em', margin: '-0.06em -0.02em -0.1em', whiteSpace: 'pre'}}>
                  <span style={{display: 'inline-block', transform: `translateY(${(1 - p) * 105}%)`}}>{l}</span>
                </span>
              );
            })}
          </div>
          <div style={{marginTop: 20, fontFamily: videoSans, fontWeight: 500, fontSize: 50, letterSpacing: '-0.025em', color: AC.textSecondary, whiteSpace: 'nowrap'}}>
            <Words text="Fair splits." at={T.end.tagline} stagger={3} />{' '}
            <Accent at={T.end.tagline + 6} color={L.palette.primary} sizeEm={1.2}>
              no arguments.
            </Accent>
          </div>
        </div>
      </div>
      <div style={{display: 'flex', gap: 26, marginTop: 64}}>
        <PackChip pack={L} at={T.end.chips[0]} />
        <PackChip pack={G} at={T.end.chips[1]} />
      </div>
    </AbsoluteFill>
  );
};

// --- the film ------------------------------------------------------------------------
const hudTone = (f: number) => (f >= T.chat.wipeFull && f < T.splash.morphStart + 10 ? 'rgba(255,255,255,0.72)' : vc.textTertiary);
// Only while the camera is in close on the phone, which then runs under the HUD.
const hudBacking = (f: number) => (f >= T.overview.pushStart && f < T.end.irisStart ? 'rgba(244, 250, 255, 0.9)' : undefined);

export const AppPromo: React.FC = () => {
  const f = useCurrentFrame();
  const whipping = f >= T.overview.pushStart && f < T.overview.pushEnd + 3;
  const iris = prog(f, T.end.irisStart, T.end.irisFull - T.end.irisStart, inOut);
  const cam = camAt(f);
  // From the headline side, so the phone is the last thing covered.
  const irisX = 420;
  const irisY = 560;

  return (
    <AbsoluteFill style={{background: vc.bg}}>
      {f < T.chat.wipeFull ? <ChatScene accent={L.palette.primary} wipeColor={L.palette.primaryDeep} /> : null}

      {f >= T.chat.wipeFull && f < T.end.irisFull ? (
        <>
          {f >= T.splash.morphStart ? (
            whipping ? (
              <Echo layers={3} lag={1} strength={0.34}>
                <DeviceStage />
              </Echo>
            ) : (
              <DeviceStage />
            )
          ) : null}
          {f < T.splash.morphEnd ? <SplashField /> : null}
          <Narration />
        </>
      ) : null}

      {f >= T.end.irisStart && f < T.end.irisFull ? (
        <HalftoneIris x={irisX} y={irisY} radius={iris * 1900} color={AC.bg} feather={330} />
      ) : null}
      {f >= T.end.irisFull ? <AppEnd /> : null}

      <Hud chapters={T.chapters} tone={hudTone} backing={hudBacking} />
      <Html5Audio src={staticFile('audio/bite_size_app_mix.wav')} />
    </AbsoluteFill>
  );
};
