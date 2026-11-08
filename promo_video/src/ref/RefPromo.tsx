// The reference cut: the Pocketsflow-style film rebuilt shot for shot, in its
// 1-bit dithered art style, for Bite Size. The dithered character is the
// app's own 3D mascot (assets/icon/logo.png); the phone runs the real app UI
// rebuilt from lib/ (see ../app/screens.tsx); colours come from app_colors.dart.
import React from 'react';
import {AbsoluteFill, Html5Audio, staticFile, useCurrentFrame} from 'remotion';
import {loadFont as loadYoungSerif} from '@remotion/google-fonts/YoungSerif';
import {backOut, expoIn, expoOut, inOut, lerp, prog, punch, quintOut} from '../anim';
import {Hud} from '../components/Hud';
import {CircleWipe, HalftoneIris} from '../components/Transitions';
import {Accent, MonoLabel, Rise, Words} from '../components/Type';
import {ClickRing, Cursor} from '../components/Ui';
import {mono, sans, serif} from '../theme';
import {AC, officeLunch, rgba} from '../app/flutter';
import {DEVICE, LunchDashboard, LunchState, Phone, SCREEN, SplashScreen} from '../app/screens';
import {MIcon} from '../app/widgets';
import {Dither, drawCricketBall, drawSalanBowl, Pose} from './Dither';
import T from './timeline_ref.json';

const young = loadYoungSerif('normal', {weights: ['400'], subsets: ['latin']}).fontFamily;

const PAL = officeLunch.palette;
const BRAND = PAL.primary; // the app's primary, the reference's blue
const NIGHT = '#18181B'; // AppColors navy900, the dark stage
const INK = AC.ink;
const GREY = AC.textTertiary;
const PAPER = '#FFFFFF';
const DOTS = '#0F172A';

// --- the mascot -------------------------------------------------------------
// Fine 2px dither through a red filter (as in B&W photography) with an
// unsharp mask, so the fur, the ears, the closed eyes, the teeth and the apple
// all survive the drop to one bit and the mascot reads like a printed photo.
const RED_FILTER: [number, number, number] = [0.5, 0.4, 0.1];

/** The app's 3D mascot, dithered, framed from the ears to the belly. */
const Mascot: React.FC<{size: number; pose?: Pose}> = ({size, pose}) => (
  <Dither
    src="app/icon/logo.png"
    width={size}
    height={size}
    pixel={2}
    fit={1.2}
    anchor={{x: 0.5, y: 0.62}}
    pose={pose}
    weights={RED_FILTER}
    tone={{black: 0.08, white: 0.86}}
    sharpen={{radius: 4, amount: 1.8}}
    ink={DOTS}
    paper={PAPER}
  />
);

const idle = (f: number, amt = 1): Pose => ({
  rotate: 2.2 * Math.sin(f / 9) * amt,
  y: 5 * Math.sin(f / 6) * amt,
  scaleY: 1 + 0.012 * Math.sin(f / 3.1) * amt,
});

// --- 01 · hook -----------------------------------------------------------------
// Dot of the "?" in the accent word, from the word box's top-left, at 132px.
const QDOT = {x: 373, y: 132};

const Hook: React.FC = () => {
  const f = useCurrentFrame();
  const H = T.hook;
  const peek = prog(f, H.peek, 26, expoOut);
  const hop = punch(f, H.accent, 14, 1);
  const bubble = prog(f, H.bubble, 12, backOut) * (1 - prog(f, H.bubbleOut, 9, expoIn));
  const typed = 'psst…'.slice(0, Math.max(0, Math.min(5, Math.floor((f - H.bubble - 2) / 3))));
  const dotPop = punch(f, H.qdot, 12, 0.6);
  const wipe = prog(f, H.wipeStart, H.wipeFull - H.wipeStart, inOut);
  const dotR = 10 * (1 + dotPop) + lerp(0, 2600, wipe);
  return (
    <AbsoluteFill style={{background: PAPER}}>
      <div style={{position: 'absolute', left: 1010, top: 250}}>
        <Mascot
          size={840}
          pose={{
            ...idle(f),
            x: (1 - peek) * 560,
            rotate: (1 - peek) * -16 + 2.2 * Math.sin(f / 9) + (f > H.label ? -2.5 * prog(f, H.label, 12) : 0),
            y: 5 * Math.sin(f / 6) - hop * 22,
          }}
        />
      </div>
      {/* "psst…" */}
      {bubble > 0.01 ? (
        <div
          style={{
            position: 'absolute',
            left: 770,
            top: 470,
            transform: `scale(${bubble})`,
            transformOrigin: '100% 60%',
          }}
        >
          <svg width={290} height={110} style={{position: 'absolute', left: 0, top: 0, overflow: 'visible'}}>
            <path
              d="M48 8 H200 a40 40 0 0 1 40 40 v0 a40 40 0 0 1 -14 30 Q248 96 284 100 Q236 104 212 86 a40 40 0 0 1 -12 2 H48 a40 40 0 0 1 0 -80 Z"
              fill={PAPER}
              stroke={INK}
              strokeWidth={3}
              strokeLinejoin="round"
            />
          </svg>
          <div style={{position: 'relative', width: 240, height: 88, display: 'flex', alignItems: 'center', paddingLeft: 30, boxSizing: 'border-box'}}>
            <span style={{fontFamily: mono, fontSize: 32, color: INK}}>{typed}</span>
          </div>
        </div>
      ) : null}
      <div style={{position: 'absolute', left: 140, top: 300, zIndex: 5}}>
        <MonoLabel at={H.label} text="// for the office" color={GREY} size={27} />
        <div style={{marginTop: 28, fontFamily: sans, fontWeight: 600, fontSize: 132, lineHeight: 1.05, letterSpacing: '-0.035em', color: INK}}>
          <div style={{whiteSpace: 'nowrap'}}>
            <Words text="Who's in" at={H.line1[0]} stagger={H.line1[1] - H.line1[0]} />
          </div>
          <div style={{whiteSpace: 'nowrap', marginTop: 6}}>
            <Words text="for" at={H.line2} />{' '}
            <span style={{position: 'relative', display: 'inline-block'}}>
              <Accent at={H.accent} color={BRAND} sizeEm={1.32}>
                lunch?
              </Accent>
              {f >= H.qdot ? (
                <div style={{position: 'absolute', left: QDOT.x, top: QDOT.y, width: 0, height: 0}}>
                  <CircleWipe x={0} y={0} r={dotR} color={BRAND} />
                </div>
              ) : null}
            </span>
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// --- 02 · anything ---------------------------------------------------------------
const CARD = {w: 363, h: 607, y: 215, xs: [712, 1099, 1486]};
const CARDS = [
  {tag: 'roti', n: '01', title: 'Rotis', price: 'Rs 25 each', art: {src: 'app/svg/roti.svg', tone: {black: 0.25, white: 0.92}, filter: 'contrast(1.2)'}},
  {tag: 'meal', n: '02', title: 'Meals', price: 'Rs 480 shared', art: {draw: drawSalanBowl, tone: {black: 0.1, white: 0.9}}},
  {tag: 'pitch', n: '03', title: 'Pitches', price: 'Rs 3,000/hr', art: {draw: drawCricketBall, tone: {black: 0.1, white: 0.85}}},
];

const ThingCard: React.FC<{i: number}> = ({i}) => {
  const c = CARDS[i];
  return (
    <div
      style={{
        width: CARD.w,
        height: CARD.h,
        background: PAPER,
        borderRadius: 30,
        padding: '34px 30px 30px',
        boxSizing: 'border-box',
        display: 'flex',
        flexDirection: 'column',
        boxShadow: `0 30px 60px -30px ${rgba('#0F172A', 0.35)}`,
      }}
    >
      <div style={{display: 'flex', justifyContent: 'space-between', fontFamily: mono, fontSize: 25, color: GREY}}>
        <span>// {c.tag}</span>
        <span>{c.n}</span>
      </div>
      <div style={{flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <Dither src={c.art.src} draw={c.art.draw} width={291} height={291} pixel={3} tone={c.art.tone} filter={c.art.filter} sharpen={{radius: 3, amount: 1.2}} ink={DOTS} />
      </div>
      <div style={{fontFamily: sans, fontWeight: 600, fontSize: 62, letterSpacing: '-0.035em', color: INK, lineHeight: 1.05}}>{c.title}</div>
      <div style={{fontFamily: mono, fontSize: 27, color: GREY, marginTop: 10}}>{c.price}</div>
    </div>
  );
};

// The phone sits where the reference's does; its screen is where the field lands.
const PHONE = {x: 1330, y: 72};
const SCREEN_RECT = {x: PHONE.x + DEVICE.bezel, y: PHONE.y + DEVICE.bezel, w: SCREEN.w, h: SCREEN.h};

const Anything: React.FC = () => {
  const f = useCurrentFrame();
  const A = T.anything;
  const m = prog(f, A.shrinkStart, A.shrinkEnd - A.shrinkStart, inOut);
  // Field → phone screen; its colour eases into the splash's deep brand tile.
  const x = lerp(0, SCREEN_RECT.x, m);
  const y = lerp(0, SCREEN_RECT.y, m);
  const w = lerp(1920, SCREEN_RECT.w, m);
  const h = lerp(1080, SCREEN_RECT.h, m);
  // Uniform scale, centred, so the cards ride the field down without squashing.
  const k = Math.min(w / 1920, h / 1080);
  return (
    <AbsoluteFill style={{background: PAPER}}>
      <div
        style={{
          position: 'absolute',
          left: x,
          top: y,
          width: w,
          height: h,
          borderRadius: lerp(0, DEVICE.radius - DEVICE.bezel, m),
          overflow: 'hidden',
          background: m > 0 ? mixColor(BRAND, PAL.primaryDeep, m) : BRAND,
        }}
      >
        <div style={{position: 'absolute', left: (w - 1920 * k) / 2, top: (h - 1080 * k) / 2, width: 1920, height: 1080, transform: `scale(${k})`, transformOrigin: '0 0'}}>
          {CARDS.map((_, i) => {
            const at = A.cards[i];
            const p = prog(f, at, 20, quintOut);
            const vis = prog(f, at, 6);
            if (f < at) return null;
            return (
              <div
                key={i}
                style={{
                  position: 'absolute',
                  left: CARD.xs[i],
                  top: CARD.y,
                  opacity: vis * (1 - m),
                  transform: `translate(${(1 - p) * 520}px, ${(1 - p) * -30}px) rotate(${(1 - p) * 6}deg) scale(${1.06 - 0.06 * p})`,
                  transformOrigin: '50% 100%',
                }}
              >
                <ThingCard i={i} />
              </div>
            );
          })}
        </div>
      </div>
    </AbsoluteFill>
  );
};

const mixColor = (a: string, b: string, t: number) => {
  const pa = [1, 3, 5].map((i) => parseInt(a.slice(i, i + 2), 16));
  const pb = [1, 3, 5].map((i) => parseInt(b.slice(i, i + 2), 16));
  return `rgb(${pa.map((v, i) => Math.round(v + (pb[i] - v) * t)).join(',')})`;
};

// --- 03 · roster (the real app on a phone) ----------------------------------------
const lunch = (f: number): LunchState => ({
  inviteCollapse: 0,
  countPress: f >= T.roster.click && f < T.roster.click + 4 ? 1 : 0,
  aliAccepted: false,
  saraAccepted: false,
  departed: false,
  startPress: 0,
  scroll: 0,
  rosterAppear: [1, 1, 1, 1],
});

// COUNT ME IN on the phone, device coordinates (screen + bezel).
const PHONE_BTN = {x: DEVICE.bezel + 262, y: DEVICE.bezel + 309};
// A gentle push: the button grows to fill the width, it never floods the frame.
const PUSH = 6;

const PhoneStage: React.FC = () => {
  const f = useCurrentFrame();
  const R = T.roster;
  const launch = prog(f, R.launch, 10, expoOut);
  const zoomAt = (g: number) => Math.pow(PUSH, inOut(prog(g, R.zoomStart, R.zoomEnd - 1 - R.zoomStart, (t) => t)));
  const s = zoomAt(f);
  const blur = Math.min(5, Math.abs(Math.log(s) - Math.log(zoomAt(f - 1))) * 14);
  const kk = (s - 1) / (PUSH - 1);
  const bx = PHONE.x + PHONE_BTN.x;
  const by = PHONE.y + PHONE_BTN.y;
  const tx = (960 - bx) * kk;
  const ty = (540 - by) * kk;
  return (
    <AbsoluteFill style={{filter: blur > 0.05 ? `blur(${blur}px)` : undefined}}>
    <AbsoluteFill style={{transform: `translate(${tx}px, ${ty}px) scale(${s})`, transformOrigin: `${bx}px ${by}px`}}>
      <AbsoluteFill style={{background: PAPER}} />
      <div style={{position: 'absolute', left: PHONE.x, top: PHONE.y}}>
        <Phone>
          <SplashScreen pack={officeLunch} fade={1} rise={0} shuttle={Math.max(0, f - T.anything.shrinkEnd) / 27} />
          {f >= R.launch ? (
            <div style={{position: 'absolute', inset: 0, opacity: launch}}>
              <LunchDashboard pack={officeLunch} s={lunch(f)} />
            </div>
          ) : null}
        </Phone>
      </div>
      <RosterCopy />
      {f >= R.cursorIn ? (
        <>
          <ClickRing x={bx + 14} y={by + 4} t={prog(f, R.click, 12, expoOut)} color={rgba(BRAND, 0.5)} />
          <Cursor
            x={lerp(1880, bx + 6, prog(f, R.cursorIn, R.click - R.cursorIn - 2, inOut))}
            y={lerp(1120, by, prog(f, R.cursorIn, R.click - R.cursorIn - 2, inOut))}
            press={Math.max(0, punch(f, R.click, 8, 1))}
          />
        </>
      ) : null}
    </AbsoluteFill>
    </AbsoluteFill>
  );
};

const RosterCopy: React.FC = () => {
  const R = T.roster;
  return (
    <div style={{position: 'absolute', left: 110, top: 210}}>
      <div style={{fontSize: 66, lineHeight: 1.1, whiteSpace: 'nowrap', letterSpacing: '-0.02em'}}>
        <Rise at={R.line1}>
          <span style={{fontFamily: young, color: INK}}>Bite Size</span>
        </Rise>{' '}
        <span style={{fontFamily: sans, fontWeight: 500, color: GREY}}>
          <Words text="turns it into" at={R.line1 + 5} stagger={3} />
        </span>
      </div>
      <div style={{fontFamily: sans, fontWeight: 600, fontSize: 150, lineHeight: 1.04, letterSpacing: '-0.04em', color: INK, marginTop: 18}}>
        <div style={{whiteSpace: 'nowrap'}}>
          <Words text="one list," at={R.line2} stagger={5} />
        </div>
        <div style={{whiteSpace: 'nowrap'}}>
          <Words text="one" at={R.line3[0]} />{' '}
          <Accent at={R.line3[1]} color={BRAND} sizeEm={1.25}>
            runner.
          </Accent>
        </div>
      </div>
    </div>
  );
};

// --- 04 · sorted (the bento) --------------------------------------------------------
const G = {
  A: {x: 100, y: 90, w: 560, h: 900},
  B: {x: 680, y: 90, w: 560, h: 440},
  C: {x: 1260, y: 90, w: 560, h: 440},
  D: {x: 680, y: 550, w: 560, h: 440},
  E: {x: 1260, y: 550, w: 560, h: 210},
  F: {x: 1260, y: 778, w: 560, h: 212},
};
type Box = {x: number; y: number; w: number; h: number};
const A_BTN = {x: 28, y: 236, w: 504, h: 84};
const A_BTN_CENTER = {x: G.A.x + A_BTN.x + A_BTN.w / 2, y: G.A.y + A_BTN.y + A_BTN.h / 2};

const BentoCard: React.FC<{b: Box; at?: number; children?: React.ReactNode; f: number}> = ({b, at, children, f}) => {
  const shown = at === undefined || f >= at;
  const p = at === undefined ? 1 : prog(f, at, 14, expoOut);
  return (
    <>
      <div
        style={{
          position: 'absolute',
          left: b.x,
          top: b.y,
          width: b.w,
          height: b.h,
          borderRadius: 28,
          border: `2px dashed ${AC.border}`,
          boxSizing: 'border-box',
          opacity: shown ? 1 - p : 1,
        }}
      />
      {shown ? (
        <div
          style={{
            position: 'absolute',
            left: b.x,
            top: b.y,
            width: b.w,
            height: b.h,
            background: PAPER,
            borderRadius: 28,
            border: `1.5px solid ${AC.border}`,
            boxSizing: 'border-box',
            padding: 28,
            overflow: 'hidden',
            opacity: prog(f, at ?? -99, 5),
            transform: `translateY(${(1 - p) * 30}px) scale(${0.97 + 0.03 * p})`,
            boxShadow: `0 18px 40px -24px ${rgba('#0F172A', 0.2)}`,
          }}
        >
          {children}
        </div>
      ) : null}
    </>
  );
};

const Label: React.FC<{text: string; right?: React.ReactNode; dot?: string}> = ({text, right, dot}) => (
  <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 34}}>
    <span style={{fontFamily: mono, fontSize: 24, color: GREY, display: 'flex', alignItems: 'center', gap: 10}}>
      {dot ? <span style={{width: 12, height: 12, borderRadius: 12, background: dot}} /> : null}
      {text}
    </span>
    {right}
  </div>
);

const lineIn = (f: number, at: number): React.CSSProperties => {
  const p = prog(f, at, 10, expoOut);
  return {opacity: prog(f, at, 4), transform: `translateY(${(1 - p) * 12}px)`};
};

const money = (n: number) => `Rs ${n.toLocaleString('en-US', {minimumFractionDigits: 2, maximumFractionDigits: 2})}`;

const Bento: React.FC = () => {
  const f = useCurrentFrame();
  const S = T.sorted;
  const typedNames = 'Bilal, Sara, Ali'.slice(0, Math.max(0, Math.floor((f - S.type) / 1)));
  const joined = f >= S.pullEnd + 4;
  const sorted = f >= S.joined;
  const price = Math.round(25 * prog(f, S.month, 12, quintOut));
  const bill = 3300 * prog(f, S.billCount, 20, quintOut);
  const bars = [10, 12, 11, 12, 13, 12, 13, 15];
  const checked = (i: number) => f >= S.checks[i];
  return (
    <AbsoluteFill style={{background: AC.bg}}>
      {[100, 660, 680, 1240, 1260, 1820].map((x) => (
        <div key={x} style={{position: 'absolute', left: x, top: 0, bottom: 0, width: 1.5, background: AC.divider, opacity: 0.8}} />
      ))}
      {[90, 530, 550, 990].map((y) => (
        <div key={y} style={{position: 'absolute', top: y, left: 0, right: 0, height: 1.5, background: AC.divider, opacity: 0.8}} />
      ))}

      {/* A · the shared meal, as the reference's checkout */}
      <BentoCard b={G.A} f={f}>
        <Label text="// shared meal" />
        <div style={{display: 'flex', alignItems: 'center', gap: 20, marginTop: 22}}>
          <div style={{width: 112, height: 112, borderRadius: 20, background: AC.bg, border: `1.5px solid ${AC.border}`, display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden'}}>
            <Dither draw={drawSalanBowl} width={102} height={102} pixel={3} tone={{black: 0.1, white: 0.9}} ink={DOTS} paper={AC.bg} />
          </div>
          <div style={{flex: 1}}>
            <div style={{fontFamily: sans, fontWeight: 600, fontSize: 36, color: INK, letterSpacing: '-0.02em'}}>Extra salan</div>
            <div style={{fontFamily: mono, fontSize: 22, color: GREY, marginTop: 4}}>shared by Bilal</div>
          </div>
          <div style={{fontFamily: mono, fontSize: 28, color: INK}}>Rs 480.00</div>
        </div>
        <div style={{height: 1.5, background: AC.divider, marginTop: 24}} />
        <div
          style={{
            position: 'absolute',
            left: A_BTN.x,
            top: A_BTN.y,
            width: A_BTN.w,
            height: A_BTN.h,
            borderRadius: 16,
            background: joined ? `color-mix(in srgb, ${BRAND} 12%, white)` : BRAND,
            color: joined ? BRAND : PAPER,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 12,
            fontFamily: sans,
            fontWeight: 600,
            fontSize: 34,
          }}
        >
          <MIcon name="check" size={34} color={joined ? BRAND : PAPER} />
          {joined ? 'Joined' : 'Count me in'}
        </div>
        <div style={{position: 'absolute', left: 28, right: 28, top: 344, display: 'flex', alignItems: 'center', gap: 14, fontFamily: mono, fontSize: 22, color: GREY}}>
          <div style={{flex: 1, height: 1.5, background: AC.divider}} />
          or reply later
          <div style={{flex: 1, height: 1.5, background: AC.divider}} />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 28,
            right: 28,
            top: 390,
            height: 76,
            borderRadius: 16,
            border: `1.5px solid ${AC.border}`,
            display: 'flex',
            alignItems: 'center',
            padding: '0 22px',
            boxSizing: 'border-box',
          }}
        >
          <span style={{fontFamily: mono, fontSize: 28, color: INK, flex: 1}}>{typedNames}</span>
          <span style={{fontFamily: mono, fontSize: 24, color: GREY}}>{typedNames.length >= 16 ? '3 ways' : 'who?'}</span>
        </div>
        <div style={{position: 'absolute', left: 28, right: 28, top: 496, fontFamily: sans, fontSize: 28, color: AC.textSecondary}}>
          <Row l="Extra salan" r="Rs 480.00" />
          <div style={lineIn(f, S.share)}>
            <Row l="Split · 3 ways" r="÷ 3" accent />
          </div>
          <div style={lineIn(f, S.share + 4)}>
            <Row l="Paid by Bilal" r="Rs 480.00" />
          </div>
        </div>
        <div style={{position: 'absolute', left: 28, right: 28, top: 690, height: 1.5, background: AC.divider}} />
        <div style={{position: 'absolute', left: 28, right: 28, top: 706, display: 'flex', justifyContent: 'space-between', alignItems: 'baseline'}}>
          <span style={{fontFamily: sans, fontWeight: 600, fontSize: 36, color: INK}}>Your share</span>
          <span style={{fontFamily: mono, fontWeight: 600, fontSize: 38, color: INK}}>{f >= S.total ? 'Rs 160.00' : '~Rs 160.00'}</span>
        </div>
        <div
          style={{
            position: 'absolute',
            left: 28,
            right: 28,
            bottom: 28,
            height: 92,
            borderRadius: 18,
            background: sorted ? BRAND : INK,
            color: PAPER,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: 12,
            fontFamily: sans,
            fontWeight: 600,
            fontSize: 34,
            transform: `scale(${1 + punch(f, S.joined, 12, 0.05)})`,
          }}
        >
          {sorted ? <MIcon name="check" size={34} color={PAPER} /> : null}
          {sorted ? 'Billed at month-end' : f >= S.total ? "Everyone's in" : 'Waiting on Sara'}
        </div>
      </BentoCard>

      {/* B · the runner, live */}
      <BentoCard b={G.B} f={f}>
        <Label text="// on the run" dot={BRAND} />
        <div style={{position: 'absolute', left: 70, top: 66}}>
          <Mascot size={420} pose={{...idle(f, 1.6), rotate: 3 * Math.sin(f / 5)}} />
        </div>
      </BentoCard>

      {/* C · month-end price, as the reference's subscription */}
      <BentoCard b={G.C} at={S.month} f={f}>
        <Label text="// month-end" right={<MIcon name="autorenew" size={36} color={INK} style={{transform: `rotate(${f * 6}deg)`}} />} />
        <div style={{display: 'flex', alignItems: 'baseline', gap: 16, marginTop: 40}}>
          <span style={{fontFamily: sans, fontWeight: 700, fontSize: 132, letterSpacing: '-0.05em', color: INK, lineHeight: 1}}>Rs {price}</span>
          <span style={{fontFamily: sans, fontSize: 44, color: GREY}}>/ roti</span>
        </div>
        <div style={{position: 'absolute', left: 44, right: 44, top: 330}}>
          <div style={{position: 'absolute', left: 12, right: 12, top: 10, height: 3, background: AC.divider}} />
          <div
            style={{
              position: 'absolute',
              left: 12,
              top: 10,
              height: 3,
              width: `${(Math.max(0, S.dots.filter((d) => f >= d).length - 1) / 4) * 100 * 0.95}%`,
              background: BRAND,
            }}
          />
          <div style={{display: 'flex', justifyContent: 'space-between'}}>
            {['MON', 'TUE', 'WED', 'THU', 'FRI'].map((d, i) => {
              const on = f >= S.dots[i];
              return (
                <div key={d} style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12}}>
                  <div style={{width: 24, height: 24, borderRadius: 24, background: on ? BRAND : PAPER, border: `3px solid ${on ? BRAND : AC.borderStrong}`, boxSizing: 'border-box', transform: `scale(${1 + punch(f, S.dots[i], 10, 0.4)})`}} />
                  <span style={{fontFamily: mono, fontSize: 20, color: AC.textSecondary}}>{d}</span>
                </div>
              );
            })}
          </div>
        </div>
      </BentoCard>

      {/* D · who's in, as the reference's upsells */}
      <BentoCard b={G.D} at={S.roster} f={f}>
        <Label text="// who's in" />
        {[
          {dish: 'Daal mash', who: 'Ali · runner', n: 3},
          {dish: 'Eating only', who: 'Bilal', n: 4},
        ].map((r, i) => {
          const on = checked(i);
          return (
            <div
              key={r.dish}
              style={{
                marginTop: i === 0 ? 24 : 16,
                height: 150,
                borderRadius: 20,
                border: `2px solid ${on ? BRAND : AC.border}`,
                background: on ? `color-mix(in srgb, ${BRAND} 7%, white)` : PAPER,
                display: 'flex',
                alignItems: 'center',
                gap: 18,
                padding: '0 20px',
                boxSizing: 'border-box',
              }}
            >
              <div style={{width: 96, height: 96, borderRadius: 16, overflow: 'hidden', background: PAPER, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <Dither src="app/svg/roti.svg" width={93} height={93} pixel={3} tone={{black: 0.25, white: 0.92}} filter="contrast(1.2)" ink={DOTS} />
              </div>
              <div style={{flex: 1}}>
                <div style={{fontFamily: sans, fontWeight: 600, fontSize: 32, color: INK, letterSpacing: '-0.02em'}}>{r.dish}</div>
                <div style={{fontFamily: sans, fontSize: 23, color: GREY, marginTop: 2}}>{r.who}</div>
                <div style={{fontFamily: sans, fontWeight: 600, fontSize: 24, color: BRAND, marginTop: 4}}>{r.n} rotis</div>
              </div>
              <div
                style={{
                  width: 44,
                  height: 44,
                  borderRadius: 10,
                  border: `2.5px solid ${on ? BRAND : AC.borderStrong}`,
                  background: on ? BRAND : PAPER,
                  boxSizing: 'border-box',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  transform: `scale(${1 + punch(f, S.checks[i], 10, 0.3)})`,
                }}
              >
                {on ? <MIcon name="check" size={32} color={PAPER} /> : null}
              </div>
            </div>
          );
        })}
      </BentoCard>

      {/* E · the lock, as the reference's merchant-of-record */}
      <BentoCard b={G.E} at={S.lock} f={f}>
        <Label text="// the runner leaves" right={<MIcon name="lock" size={30} color={f >= S.chips[0] ? BRAND : AC.borderStrong} />} />
        <div style={{fontFamily: sans, fontWeight: 500, fontSize: 29, color: INK, marginTop: 16, letterSpacing: '-0.01em'}}>
          The list locks when the runner leaves.
        </div>
        <div style={{display: 'flex', gap: 10, marginTop: 18}}>
          {['Roster', '1 shared meal', '12 rotis'].map((t, i) => (
            <div
              key={t}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                padding: '7px 13px',
                borderRadius: 999,
                border: `1.5px solid ${AC.border}`,
                fontFamily: mono,
                fontSize: 19,
                color: INK,
                whiteSpace: 'nowrap',
              }}
            >
              {t}
              {f >= S.chips[i] ? <MIcon name="lock" size={20} color={BRAND} style={{transform: `scale(${1 + punch(f, S.chips[i], 8, 0.4)})`}} /> : null}
            </div>
          ))}
        </div>
      </BentoCard>

      {/* F · the month's bill, as the reference's payouts */}
      <BentoCard b={G.F} at={S.bill} f={f}>
        <Label text="// october bill" />
        <div style={{fontFamily: mono, fontWeight: 600, fontSize: 48, color: INK, marginTop: 16, letterSpacing: '-0.02em'}}>{money(bill)}</div>
        <div style={{fontFamily: mono, fontSize: 22, color: GREY, marginTop: 6}}>132 rotis × Rs 25</div>
        <div style={{position: 'absolute', right: 30, bottom: 28, display: 'flex', alignItems: 'flex-end', gap: 6}}>
          {bars.map((b, i) => (
            <div
              key={i}
              style={{
                width: 11,
                height: b * 5.5 * prog(f, S.billCount + i * 1.5, 10, expoOut),
                background: i === bars.length - 1 ? BRAND : `color-mix(in srgb, ${BRAND} 35%, white)`,
                borderRadius: 3,
              }}
            />
          ))}
        </div>
      </BentoCard>

      {/* badges + ring once it's sorted */}
      {[G.A, G.B, G.C, G.E].map((b, i) => {
        const p = prog(f, S.badges[i], 12, backOut);
        return p > 0 ? (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: b.x + b.w - 70,
              top: b.y + 24,
              width: 42,
              height: 42,
              borderRadius: 42,
              background: BRAND,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              transform: `scale(${p})`,
            }}
          >
            <MIcon name="check" size={30} color={PAPER} />
          </div>
        ) : null;
      })}
      {f >= S.settle && f < S.settle + 24 ? (
        <div
          style={{
            position: 'absolute',
            left: 880 - lerp(80, 760, prog(f, S.settle, 24, expoOut)),
            top: 780 - lerp(80, 760, prog(f, S.settle, 24, expoOut)),
            width: 2 * lerp(80, 760, prog(f, S.settle, 24, expoOut)),
            height: 2 * lerp(80, 760, prog(f, S.settle, 24, expoOut)),
            borderRadius: '50%',
            border: `3px solid ${BRAND}`,
            opacity: 1 - prog(f, S.settle, 24),
          }}
        />
      ) : null}
    </AbsoluteFill>
  );
};

const Row: React.FC<{l: string; r: string; accent?: boolean}> = ({l, r, accent}) => (
  <div style={{display: 'flex', justifyContent: 'space-between', marginBottom: 14}}>
    <span>{l}</span>
    <span style={{fontFamily: mono, color: accent ? BRAND : INK}}>{r}</span>
  </div>
);

/** "Sorted." — slams across with ribbon bands, then lands as a stamp. */
const Stamp: React.FC = () => {
  const f = useCurrentFrame();
  const S = T.sorted;
  if (f < S.stamp) return null;
  const slam = prog(f, S.stamp, 12, quintOut);
  const settle = prog(f, S.settle, 18, inOut);
  const s = lerp(lerp(1.7, 1, slam), 0.36, settle);
  const x = lerp(960, 880, settle);
  const y = lerp(540, 780, settle);
  const bands = 1 - settle;
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(-50%, -50%) rotate(${lerp(-8, -6, settle)}deg) scale(${s})`}}>
      <div style={{position: 'relative', padding: '6px 80px 36px'}}>
        <div style={{position: 'absolute', left: -1000, right: -1000, top: 36, height: 30, background: BRAND, opacity: bands}} />
        <div style={{position: 'absolute', left: -1000, right: -1000, bottom: 24, height: 16, background: BRAND, opacity: bands * 0.85}} />
        <div style={{position: 'absolute', inset: 0, borderRadius: 60, border: `16px solid ${BRAND}`, background: 'rgba(255,255,255,0.94)', opacity: settle}} />
        <div style={{position: 'relative', fontFamily: serif, fontStyle: 'italic', fontSize: 380, lineHeight: 1, color: BRAND, whiteSpace: 'nowrap'}}>Sorted.</div>
      </div>
    </div>
  );
};

/** The pull back out of COUNT ME IN onto the card's own button. */
const Pulled: React.FC = () => {
  const f = useCurrentFrame();
  const S = T.sorted;
  // Matches the phone button at 6× (210×40 → 1264×240) so the cut is invisible.
  const SCALE = 2.6;
  const zoomAt = (g: number) => Math.pow(SCALE, 1 - inOut(prog(g, S.pullStart, S.pullEnd - S.pullStart, (t) => t)));
  const s = zoomAt(f);
  const k = (s - 1) / (SCALE - 1);
  const blur = Math.min(5, Math.abs(Math.log(s) - Math.log(zoomAt(f - 1))) * 14);
  return (
    <AbsoluteFill style={{filter: blur > 0.05 ? `blur(${blur}px)` : undefined}}>
      <AbsoluteFill
        style={{
          transform: `translate(${(960 - A_BTN_CENTER.x) * k}px, ${(540 - A_BTN_CENTER.y) * k}px) scale(${s})`,
          transformOrigin: `${A_BTN_CENTER.x}px ${A_BTN_CENTER.y}px`,
        }}
      >
        <Bento />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// --- 05 · split ---------------------------------------------------------------------
const Split: React.FC = () => {
  const f = useCurrentFrame();
  const P = T.split;
  const rise = prog(f, P.irisFull, 12, expoOut);
  const glow = prog(f, P.accent2 + 4, 10);
  return (
    <AbsoluteFill style={{background: NIGHT}}>
      <div style={{position: 'absolute', left: 1220, top: 320}}>
        <Mascot size={760} pose={{...idle(f), y: (1 - rise) * 500 + 5 * Math.sin(f / 6), rotate: -3 + 2 * Math.sin(f / 9)}} />
      </div>
      <div style={{position: 'absolute', left: 120, top: 330, fontFamily: sans, fontWeight: 600, fontSize: 132, lineHeight: 1.12, letterSpacing: '-0.035em'}}>
        <div style={{whiteSpace: 'nowrap', color: PAPER}}>
          <Words text="You" at={P.you} />{' '}
          <Accent at={P.accent1} color={PAPER} underline={false} sizeEm={1.25}>
            bite.
          </Accent>
        </div>
        <div style={{whiteSpace: 'nowrap', color: '#A1A1AA'}}>
          <Words text="We" at={P.we[0]} />{' '}
          <Words text="handle" at={P.we[1]} />{' '}
          <Words text="the" at={P.we[2]} />{' '}
          <span style={{display: 'inline-block', filter: `drop-shadow(0 0 ${28 * glow}px ${PAL.primaryDark})`}}>
            <Accent at={P.accent2} color={PAL.primaryDark} underline={false} sizeEm={1.25}>
              size.
            </Accent>
          </span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// Where "size." sits at the end of the split beat; the white iris opens from it.
const SIZE_AT = {x: 1150, y: 560};

// --- end card ---------------------------------------------------------------------------
const End: React.FC = () => {
  const f = useCurrentFrame();
  const E = T.end;
  const letters = 'Bite '.split('');
  const morph = prog(f, T.split.whiteFull, 12, inOut);
  const mascot = prog(f, E.mascot, 16, backOut);
  return (
    <AbsoluteFill style={{background: PAPER}}>
      {/* the mascot, behind the wordmark — not drawn at all until it pops up */}
      {f >= E.mascot ? (
        <div style={{position: 'absolute', left: 960 - 190, top: 120, overflow: 'hidden', width: 380, height: 400}}>
          <div style={{transform: `translateY(${(1 - mascot) * 420}px)`}}>
            <Mascot size={380} pose={{...idle(f), rotate: 4 + 2 * Math.sin(f / 9)}} />
          </div>
        </div>
      ) : null}
      <div style={{position: 'absolute', left: 0, right: 0, top: 360, display: 'flex', justifyContent: 'center'}}>
        <div style={{fontFamily: young, fontSize: 236, color: INK, lineHeight: 1, display: 'flex', whiteSpace: 'pre'}}>
          {letters.map((l, i) => {
            const p = prog(f, E.letters + i * 2, 14, backOut);
            return (
              <span key={i} style={{display: 'inline-block', opacity: prog(f, E.letters + i * 2, 3), transform: `translateY(${(1 - p) * 120}px) rotate(${(1 - p) * -14}deg)`}}>
                {l}
              </span>
            );
          })}
          {/* "size." from the last beat settles into the wordmark's "Size" */}
          <span style={{position: 'relative', display: 'inline-block'}}>
            <span style={{opacity: morph}}>Size</span>
            <span
              style={{
                position: 'absolute',
                left: 0,
                top: 0,
                fontFamily: serif,
                fontStyle: 'italic',
                color: BRAND,
                opacity: 1 - morph,
                transform: `translate(${(1 - morph) * 80}px, ${(1 - morph) * 120}px) scale(${lerp(0.72, 1, morph)})`,
                transformOrigin: '0 100%',
              }}
            >
              size.
            </span>
          </span>
        </div>
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 640, textAlign: 'center', fontFamily: sans, fontWeight: 500, fontSize: 50, letterSpacing: '-0.02em', color: GREY, whiteSpace: 'nowrap'}}>
        <Words text="Office lunch logistics," at={E.tagline} stagger={2} />{' '}
        <Accent at={E.tagline + 6} color={INK} underline={false} sizeEm={1.15}>
          sorted before noon.
        </Accent>
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 772, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 32}}>
        <div
          style={{
            padding: '22px 46px',
            borderRadius: 999,
            background: BRAND,
            color: PAPER,
            fontFamily: sans,
            fontWeight: 600,
            fontSize: 36,
            opacity: prog(f, E.cta, 5),
            transform: `scale(${0.8 + 0.2 * prog(f, E.cta, 14, backOut)})`,
          }}
        >
          Count me in
        </div>
        <div style={{fontFamily: mono, fontSize: 30, color: AC.textSecondary, opacity: prog(f, E.cta + 4, 8)}}>office lunch · ground booking</div>
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 985, textAlign: 'center', fontFamily: mono, fontSize: 25, color: GREY, opacity: prog(f, E.stats, 10) * 0.85}}>
        one list · one runner · one bill
      </div>
    </AbsoluteFill>
  );
};

// --- the film -------------------------------------------------------------------------
const tone = (f: number) =>
  (f >= T.hook.wipeFull && f < T.anything.shrinkEnd) || (f >= T.split.irisFull && f < T.split.whiteFull)
    ? 'rgba(255,255,255,0.72)'
    : GREY;

/** The mascot travels from the brand field to its spot beside the phone. */
const Traveller: React.FC = () => {
  const f = useCurrentFrame();
  const A = T.anything;
  const rise = prog(f, A.rise, 13, expoOut);
  const go = prog(f, A.shrinkStart, A.shrinkEnd - A.shrinkStart + 4, inOut);
  const left = lerp(-60, 850, go);
  const top = lerp(300, 600, go);
  const size = lerp(800, 480, go);
  return (
    <div style={{position: 'absolute', left, top}}>
      <Mascot size={size} pose={{...idle(f), y: (1 - rise) * 560 + 5 * Math.sin(f / 6), rotate: lerp(-4, 5, go) + 2 * Math.sin(f / 9)}} />
    </div>
  );
};

export const RefPromo: React.FC = () => {
  const f = useCurrentFrame();
  const H = T.hook;
  const A = T.anything;
  const R = T.roster;
  const S = T.sorted;
  const P = T.split;
  const dark = prog(f, P.irisStart, P.irisFull - P.irisStart, inOut);
  const white = prog(f, P.whiteStart, P.whiteFull - P.whiteStart, inOut);
  const XFADE = 4; // frames either side of the phone → grid cut
  return (
    <AbsoluteFill style={{background: PAPER}}>
      {f < H.wipeFull ? <Hook /> : null}
      {f >= H.wipeFull && f < A.shrinkEnd ? <Anything /> : null}
      {/* The grid sits under the phone a few frames early, so the button-to-
          button cut dissolves instead of popping. */}
      {f >= S.pullStart - XFADE && f < P.irisFull ? (
        <>
          <Pulled />
          <Stamp />
        </>
      ) : null}
      {f >= A.shrinkEnd && f < R.zoomEnd + XFADE ? (
        <AbsoluteFill style={{opacity: 1 - prog(f, R.zoomEnd - XFADE, XFADE * 2, inOut)}}>
          <PhoneStage />
        </AbsoluteFill>
      ) : null}
      {f >= H.wipeFull && f < R.zoomStart ? <Traveller /> : null}
      {f >= P.irisStart && f < P.irisFull ? <HalftoneIris x={960} y={560} radius={dark * 1500} color={NIGHT} /> : null}
      {f >= P.irisFull && f < P.whiteFull ? <Split /> : null}
      {f >= P.whiteStart && f < P.whiteFull ? <HalftoneIris x={SIZE_AT.x} y={SIZE_AT.y} radius={white * 1700} color={PAPER} feather={330} /> : null}
      {f >= P.whiteFull ? <End /> : null}
      <Hud chapters={T.chapters} tone={tone} />
      <Html5Audio src={staticFile('audio/bite_size_ref_mix.wav')} />
    </AbsoluteFill>
  );
};
