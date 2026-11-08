// Part 2, after reference A: the calm console where Bite Size takes the
// chat's mess and answers it — prompt, roster grid, toolkit, settle chart,
// tile wipe, logo. Every feature named here is one the app ships.
import React from 'react';
import {AbsoluteFill, random, useCurrentFrame} from 'remotion';
import {backOut, expoIn, expoOut, inOut, lerp, prog, punch, quintOut} from '../anim';
import {AppIcon} from '../app/widgets';
import {
  ACCENT,
  anton,
  archivo,
  CARD_BG,
  CONSOLE,
  COPPER_DARK,
  DIM,
  GROUND,
  INFO,
  INK,
  jakarta,
  LINE,
  LUNCH,
  mono,
  serif,
  TEXT,
} from './look';
import T from './timeline_notes.json';

const BEAT = 15;
const rgbaHex = (hex: string, a: number) => {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
  return `rgba(${r}, ${g}, ${b}, ${a})`;
};

// --- frame + HUD ---------------------------------------------------------------
export const ConsoleBg: React.FC<{glow?: number; glowAt?: {x: number; y: number}}> = ({glow = 0, glowAt = {x: 960, y: 540}}) => (
  <AbsoluteFill style={{background: CONSOLE}}>
    <AbsoluteFill
      style={{
        backgroundImage: `radial-gradient(${rgbaHex('#ECE7DC', 0.07)} 1.4px, transparent 1.6px)`,
        backgroundSize: '32px 32px',
        backgroundPosition: '16px 16px',
      }}
    />
    {glow > 0 ? (
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle at ${glowAt.x}px ${glowAt.y}px, ${rgbaHex(ACCENT, 0.28 * glow)} 0%, ${rgbaHex(ACCENT, 0.08 * glow)} 28%, transparent 55%)`,
        }}
      />
    ) : null}
    <AbsoluteFill style={{background: 'radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,0.55) 100%)'}} />
  </AbsoluteFill>
);

export const ConsoleHud: React.FC<{color?: string}> = ({color = DIM}) => {
  const f = useCurrentFrame();
  const ch = [...T.chapters].reverse().find((c) => f >= c.from) ?? T.chapters[0];
  const s = Math.floor(f / 30);
  const fr = f % 30;
  const beat = Math.floor(f / BEAT) % 4;
  const corner = (pos: React.CSSProperties, rot: number) => (
    <div style={{position: 'absolute', width: 22, height: 22, borderTop: `2px solid ${color}`, borderLeft: `2px solid ${color}`, transform: `rotate(${rot}deg)`, ...pos}} />
  );
  const label: React.CSSProperties = {position: 'absolute', fontFamily: mono, fontSize: 16, letterSpacing: '0.2em', color, whiteSpace: 'nowrap'};
  return (
    <AbsoluteFill style={{pointerEvents: 'none'}}>
      {corner({left: 28, top: 28}, 0)}
      {corner({right: 28, top: 28}, 90)}
      {corner({right: 28, bottom: 28}, 180)}
      {corner({left: 28, bottom: 28}, 270)}
      <div style={{...label, left: 62, top: 41}}>BITE SIZE {'▪'} SHOWREEL 01</div>
      <div style={{...label, right: 62, top: 41}}>{ch.label}</div>
      <div style={{...label, left: 62, bottom: 41}}>
        TC 00:00:{String(s).padStart(2, '0')}:{String(fr).padStart(2, '0')}
      </div>
      <div style={{...label, right: 62, bottom: 41, display: 'flex', alignItems: 'center', gap: 14}}>
        <span style={{display: 'flex', gap: 4}}>
          {[0, 1, 2, 3].map((i) => (
            <span key={i} style={{width: 10, height: 10, borderRadius: 2, background: i === beat ? color : rgbaHex('#ECE7DC', 0.12)}} />
          ))}
        </span>
        1920{'×'}1080 {'·'} 30 FPS {'·'} 120 BPM
      </div>
      <div style={{position: 'absolute', left: 760, width: 400, bottom: 48, height: 2, background: rgbaHex('#ECE7DC', 0.12)}}>
        <div style={{width: `${(f / T.durationInFrames) * 100}%`, height: '100%', background: color}} />
      </div>
    </AbsoluteFill>
  );
};

// --- the pixel roti: the app's roti mark, rebuilt from squares --------------------
const ROTI_CELLS: [number, number][] = [];
for (let y = 0; y < 9; y++) {
  for (let x = 0; x < 9; x++) {
    const d = Math.hypot(x - 4, y - 4);
    const charSpot = [[3, 2], [5, 5], [2, 5], [6, 3], [4, 7]].some(([cx, cy]) => cx === x && cy === y);
    if (d <= 4.4 && !charSpot) ROTI_CELLS.push([x, y]);
  }
}

export const PixelRoti: React.FC<{cell: number; gap?: number; color?: string; assemble?: number; seed?: string}> = ({
  cell,
  gap = Math.round(cell * 0.22),
  color = ACCENT,
  assemble = 1,
  seed = 'roti',
}) => {
  const step = cell + gap;
  return (
    <div style={{position: 'relative', width: 9 * step - gap, height: 9 * step - gap}}>
      {ROTI_CELLS.map(([x, y], i) => {
        const delay = random(`${seed}d${i}`) * 0.45;
        const p = Math.min(1, Math.max(0, (assemble - delay) / (1 - 0.45)));
        const e = quintOut(p);
        const dx = (random(`${seed}x${i}`) - 0.5) * 900;
        const dy = (random(`${seed}y${i}`) - 0.5) * 700;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x * step,
              top: y * step,
              width: cell,
              height: cell,
              borderRadius: cell * 0.18,
              background: color,
              opacity: Math.min(1, p * 3),
              transform: `translate(${(1 - e) * dx}px, ${(1 - e) * dy}px) rotate(${(1 - e) * 90}deg)`,
              boxShadow: `0 0 ${cell * 0.6}px ${rgbaHex(ACCENT, 0.45)}`,
            }}
          />
        );
      })}
    </div>
  );
};

// --- 01 · prompt -----------------------------------------------------------------------
const HEAD: {t: string; accent?: boolean}[] = [{t: 'What’s for '}, {t: 'lunch', accent: true}, {t: '?'}];
const HEAD_LEN = HEAD.reduce((n, s) => n + s.t.length, 0);
const FIELD_TEXT = 'daal mash · 3 rotis';

const Cursor: React.FC<{f: number; h: number; w?: number; solid?: boolean}> = ({f, h, w = 7, solid}) => (
  <span
    style={{
      display: 'inline-block',
      width: w,
      height: h,
      marginLeft: 6,
      background: ACCENT,
      verticalAlign: 'middle',
      opacity: solid ? 1 : Math.floor(f / 8) % 2 === 0 ? 1 : 0.15,
      boxShadow: `0 0 18px ${rgbaHex(ACCENT, 0.7)}`,
    }}
  />
);

export const PromptScene: React.FC = () => {
  const f = useCurrentFrame();
  const P = T.prompt;
  const typed = Math.max(0, Math.min(HEAD_LEN, Math.floor((f - P.head) * 1.1)));
  const up = prog(f, P.headUp, 12, inOut);
  const field = prog(f, P.field, 12, quintOut);
  const ftyped = Math.max(0, Math.min(FIELD_TEXT.length, Math.floor((f - P.type) * 2)));
  const enter = f >= P.enter && f < P.enter + 5 ? 1 : 0;
  const glow = prog(f, P.enter, 4) * (1 - prog(f, P.enter + 6, 8));
  const exit = prog(f, T.grid.start - 2, 10, expoIn);

  let left = typed;
  const segs = HEAD.map((s) => {
    const n = Math.max(0, Math.min(s.t.length, left));
    left -= n;
    return {...s, shown: s.t.slice(0, n)};
  });

  return (
    <AbsoluteFill style={{opacity: 1 - exit, transform: `translateY(${-exit * 40}px) scale(${1 - exit * 0.05})`}}>
      {/* the headline types at centre, then rises to make room */}
      <div style={{position: 'absolute', left: 0, right: 0, top: lerp(540, 352, up) - 70, height: 140, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
        <div style={{fontFamily: jakarta, fontWeight: 800, fontSize: 104, color: TEXT, letterSpacing: '-0.035em', whiteSpace: 'nowrap', display: 'flex', alignItems: 'center'}}>
          {segs.map((s, i) =>
            s.accent ? (
              <span key={i} style={{fontFamily: serif, fontStyle: 'italic', fontWeight: 400, fontSize: 124, color: ACCENT, letterSpacing: '-0.01em', margin: '0 4px', textShadow: `0 0 30px ${rgbaHex(ACCENT, 0.35)}`}}>
                {s.shown}
              </span>
            ) : (
              <span key={i} style={{whiteSpace: 'pre'}}>
                {s.shown}
              </span>
            ),
          )}
          {f < P.field ? <Cursor f={f} h={92} w={8} solid={f < P.head + HEAD_LEN} /> : null}
        </div>
      </div>

      {/* the input */}
      {f >= P.field ? (
        <div
          style={{
            position: 'absolute',
            left: 400,
            top: 566,
            width: 1120,
            height: 126,
            borderRadius: 30,
            background: 'rgba(236,231,220,0.035)',
            border: `1.5px solid ${glow > 0 ? rgbaHex(ACCENT, 0.4 + 0.5 * glow) : LINE}`,
            boxShadow: glow > 0 ? `0 0 40px ${rgbaHex(ACCENT, 0.25 * glow)}` : '0 30px 60px -30px rgba(0,0,0,0.8)',
            boxSizing: 'border-box',
            display: 'flex',
            alignItems: 'center',
            padding: '0 32px 0 40px',
            gap: 26,
            opacity: field,
            transform: `translateY(${(1 - field) * 30}px)`,
          }}
        >
          <PixelRoti cell={4.6} gap={1} />
          <div style={{flex: 1, fontFamily: mono, fontSize: 46, color: TEXT, whiteSpace: 'pre', display: 'flex', alignItems: 'center'}}>
            {ftyped === 0 ? <span style={{color: DIM, fontSize: 30}}>add your entry{'…'}</span> : FIELD_TEXT.slice(0, ftyped)}
            <Cursor f={f} h={56} w={5} solid={ftyped > 0 && ftyped < FIELD_TEXT.length} />
          </div>
          <div
            style={{
              opacity: prog(f, P.pill, 5),
              transform: `scale(${0.85 + 0.15 * prog(f, P.pill, 8, backOut)})`,
              padding: '10px 22px',
              borderRadius: 999,
              border: `1.5px solid ${rgbaHex(ACCENT, 0.55)}`,
              background: rgbaHex(ACCENT, 0.1),
              fontFamily: mono,
              fontSize: 22,
              letterSpacing: '0.08em',
              color: ACCENT,
              whiteSpace: 'nowrap',
              display: 'flex',
              alignItems: 'center',
              gap: 10,
            }}
          >
            <span style={{width: 10, height: 10, borderRadius: 10, background: ACCENT}} />
            ROSTER {'→'} 12 IN
          </div>
          <div
            style={{
              width: 76,
              height: 62,
              borderRadius: 14,
              background: 'rgba(236,231,220,0.08)',
              border: `1.5px solid ${LINE}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontFamily: mono,
              fontSize: 28,
              color: TEXT,
              transform: `translateY(${enter * 4}px)`,
              boxShadow: enter ? 'none' : '0 4px 0 rgba(0,0,0,0.5)',
            }}
          >
            {'↵'}
          </div>
        </div>
      ) : null}

      {/* chips */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 750, display: 'flex', justifyContent: 'center', gap: 18}}>
        {['Rotis', 'Shared meal', 'Runner', 'Month-end'].map((c, i) => {
          const p = prog(f, P.chips + i * 2.5, 8, quintOut);
          return (
            <div
              key={c}
              style={{
                opacity: p,
                transform: `translateY(${(1 - p) * 16}px)`,
                padding: '12px 26px',
                borderRadius: 999,
                border: `1.5px solid ${LINE}`,
                fontFamily: jakarta,
                fontWeight: 500,
                fontSize: 30,
                color: 'rgba(236,231,220,0.75)',
                whiteSpace: 'nowrap',
              }}
            >
              <span style={{color: ACCENT, marginRight: 12, fontWeight: 700}}>/</span>
              {c}
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

/** The green flood from part 1, collapsing into the prompt's cursor. */
export const FloodToCursor: React.FC = () => {
  const f = useCurrentFrame();
  const P = T.prompt;
  const m = prog(f, P.morphStart, P.morphEnd - P.morphStart, inOut);
  const w = lerp(1920, 8, m);
  const h = lerp(1080, 92, m);
  const x = lerp(0, 956, m);
  const y = lerp(0, 540 - 46, m);
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: w,
        height: h,
        background: ACCENT,
        borderRadius: lerp(0, 2, m),
        boxShadow: `0 0 ${lerp(0, 18, m)}px ${rgbaHex(ACCENT, 0.7)}`,
      }}
    />
  );
};

// --- 02 · roster grid ----------------------------------------------------------------------
type Entry = {who: string; dish: string; rotis: number; bg: string; fg: string; icon: string};
const ROSTER: Entry[] = [
  {who: 'ali', dish: 'Daal mash', rotis: 3, bg: LUNCH.primary, fg: '#F7ECE3', icon: 'salan'},
  {who: 'sara', dish: 'Chicken karahi', rotis: 2, bg: LUNCH.fill, fg: INK, icon: 'plate'},
  {who: 'bilal', dish: 'Eating only', rotis: 4, bg: LUNCH.accentSoft, fg: INK, icon: 'roti'},
  {who: 'hina', dish: 'Aloo gobi', rotis: 3, bg: LUNCH.fixed, fg: INK, icon: 'salan'},
  {who: 'shan', dish: 'Biryani', rotis: 0, bg: GROUND.primary, fg: '#F7ECE3', icon: 'plate'},
  {who: 'talha', dish: 'Chana', rotis: 2, bg: GROUND.fill, fg: INK, icon: 'salan'},
  {who: 'umar', dish: 'Keema', rotis: 3, bg: LUNCH.soft, fg: INK, icon: 'plate'},
  {who: 'usman', dish: 'Eating only', rotis: 2, bg: LUNCH.deep, fg: '#F7ECE3', icon: 'roti'},
  {who: 'waqas', dish: 'Mix sabzi', rotis: 3, bg: GROUND.fixed, fg: INK, icon: 'salan'},
  {who: 'yasir', dish: 'Haleem', rotis: 2, bg: GROUND.accentSoft, fg: INK, icon: 'plate'},
  {who: 'zain', dish: 'Raita', rotis: 1, bg: LUNCH.accent, fg: '#F7ECE3', icon: 'tandoor'},
  {who: 'zubair', dish: 'Eating only', rotis: 3, bg: GROUND.deep, fg: '#F7ECE3', icon: 'roti'},
];
const CW = 270;
const CH = 340;
const CG = 24;

const RosterCard: React.FC<{e: Entry; i: number; f: number}> = ({e, i, f}) => {
  const at = T.grid.firstCard + i * T.grid.cardStep;
  const ph = prog(f, at - 8, 6);
  const reveal = prog(f, at, 9, inOut);
  return (
    <div style={{position: 'relative', width: CW, height: CH, opacity: ph}}>
      {/* the placeholder while it "generates" */}
      <div style={{position: 'absolute', inset: 0, borderRadius: 20, background: CARD_BG, border: `1.5px solid ${LINE}`, boxSizing: 'border-box', overflow: 'hidden'}}>
        {[0, 1, 2].map((k) => (
          <div key={k} style={{position: 'absolute', left: 24, right: k === 1 ? 90 : 40, top: 220 + k * 30, height: 14, borderRadius: 7, background: 'rgba(236,231,220,0.06)'}} />
        ))}
      </div>
      {/* the card, wiping down behind a glowing edge */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          borderRadius: 20,
          background: e.bg,
          color: e.fg,
          overflow: 'hidden',
          clipPath: `inset(0 0 ${(1 - reveal) * 100}% 0 round 20px)`,
          padding: '20px 22px',
          boxSizing: 'border-box',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <div style={{display: 'flex', justifyContent: 'space-between', fontFamily: mono, fontSize: 17, opacity: 0.7, letterSpacing: '0.04em'}}>
          <span>{e.who}</span>
          <span>{String(i + 1).padStart(2, '0')}</span>
        </div>
        <div style={{flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
          <div style={{width: 118, height: 118, borderRadius: 26, background: 'rgba(255,255,255,0.85)', display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
            <AppIcon asset={e.icon} size={78} />
          </div>
        </div>
        <div style={{fontFamily: jakarta, fontWeight: 800, fontSize: 27, letterSpacing: '-0.02em', lineHeight: 1.1}}>{e.dish}</div>
        <div style={{display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6}}>
          <span style={{fontFamily: anton, fontSize: 52, lineHeight: 1}}>{e.rotis}</span>
          <span style={{fontFamily: mono, fontSize: 16, letterSpacing: '0.12em', opacity: 0.75}}>{e.rotis === 1 ? 'ROTI' : 'ROTIS'}</span>
        </div>
      </div>
      {reveal > 0 && reveal < 1 ? (
        <div
          style={{
            position: 'absolute',
            left: 0,
            right: 0,
            top: reveal * CH - 2,
            height: 4,
            background: ACCENT,
            boxShadow: `0 0 24px 4px ${rgbaHex(ACCENT, 0.8)}`,
          }}
        />
      ) : null}
    </div>
  );
};

export const GridScene: React.FC = () => {
  const f = useCurrentFrame();
  const G = T.grid;
  const t = prog(f, G.start, T.tools.words[0] - G.start, inOut);
  const enter = prog(f, G.start, 16, quintOut);
  const rx = lerp(58, 40, t);
  const rz = lerp(-20, -11, t);
  const s = lerp(0.62, 1.04, t) * (0.9 + 0.1 * enter);
  const done = ROSTER.filter((_, i) => f >= G.firstCard + i * G.cardStep + 4).length;
  const out = prog(f, T.tools.words[0] - 3, 6, inOut);
  return (
    <AbsoluteFill style={{opacity: enter * (1 - out)}}>
      <AbsoluteFill style={{perspective: 2600, perspectiveOrigin: '50% 40%'}}>
        <div
          style={{
            position: 'absolute',
            left: 960 - (6 * CW + 5 * CG) / 2,
            top: 420 - (2 * CH + CG) / 2,
            width: 6 * CW + 5 * CG,
            display: 'grid',
            gridTemplateColumns: `repeat(6, ${CW}px)`,
            gap: CG,
            transform: `rotateX(${rx}deg) rotateZ(${rz}deg) scale(${s})`,
            transformStyle: 'preserve-3d',
          }}
        >
          {ROSTER.map((e, i) => (
            <RosterCard key={e.who} e={e} i={i} f={f} />
          ))}
        </div>
      </AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(to top, rgba(11,15,13,0.95) 0%, rgba(11,15,13,0.6) 22%, transparent 45%)'}} />
      {/* caption */}
      <div style={{position: 'absolute', left: 96, bottom: 130, display: 'flex', alignItems: 'baseline', gap: 34, whiteSpace: 'nowrap'}}>
        <Rising at={G.caption1}>
          <span style={{fontFamily: serif, fontStyle: 'italic', fontSize: 118, color: TEXT, letterSpacing: '-0.01em'}}>One list.</span>
        </Rising>
        <Rising at={G.caption2}>
          <span style={{fontFamily: jakarta, fontWeight: 800, fontSize: 100, color: ACCENT, letterSpacing: '-0.04em', textShadow: `0 0 30px ${rgbaHex(ACCENT, 0.3)}`}}>
            Twelve lunches.
          </span>
        </Rising>
      </div>
      {/* counter */}
      <div style={{position: 'absolute', right: 96, bottom: 132, textAlign: 'right'}}>
        <div style={{fontFamily: mono, fontSize: 16, letterSpacing: '0.24em', color: DIM}}>PEOPLE IN</div>
        <div style={{display: 'flex', alignItems: 'baseline', justifyContent: 'flex-end', gap: 6}}>
          <span style={{fontFamily: mono, fontWeight: 600, fontSize: 100, color: ACCENT, textShadow: `0 0 24px ${rgbaHex(ACCENT, 0.4)}`, transform: `scale(${1 + punch(f, G.firstCard + Math.max(0, done - 1) * G.cardStep + 4, 8, 0.06)})`, display: 'inline-block'}}>
            {String(done).padStart(2, '0')}
          </span>
          <span style={{fontFamily: mono, fontSize: 38, color: DIM}}>/12</span>
        </div>
      </div>
    </AbsoluteFill>
  );
};

const Rising: React.FC<{at: number; children: React.ReactNode}> = ({at, children}) => {
  const f = useCurrentFrame();
  const p = prog(f, at, 14, expoOut);
  return (
    <span style={{display: 'inline-block', overflow: 'hidden', padding: '0.1em 0.12em 0.18em', margin: '-0.1em -0.12em -0.18em'}}>
      <span style={{display: 'inline-block', transform: `translateY(${(1 - p) * 120}%)`, opacity: Math.min(1, p * 3)}}>{children}</span>
    </span>
  );
};

// --- 03 · toolkit --------------------------------------------------------------------------
const TOOLS = [
  {word: 'SHARED MEALS', sub: 'invite · accept · split', bg: ACCENT, fg: INK},
  {word: 'RUNNER', sub: 'one person fetches it all', bg: CONSOLE, fg: TEXT},
  {word: 'LIST LOCKS', sub: 'the moment the runner leaves', bg: COPPER_DARK, fg: INK},
  {word: 'CHEF AI', sub: 'checks the food covers everyone', bg: CONSOLE, fg: ACCENT},
  {word: 'PING', sub: 'nudge the one person', bg: INFO, fg: TEXT},
];

const ToolPanel: React.FC<{i: number; f: number}> = ({i, f}) => {
  const tool = TOOLS[i];
  const at = T.tools.words[i];
  const t = f - at;
  const settle = prog(f, at, 10, quintOut);
  const light = tool.bg === ACCENT || tool.bg === COPPER_DARK;
  const ink = light ? 'rgba(24,24,27,0.6)' : DIM;

  let deco: React.ReactNode = null;
  let wordStyle: React.CSSProperties = {};
  if (i === 0) {
    // a dashed selection box draws itself around the word
    const d = prog(f, at + 2, 10, inOut);
    wordStyle = {outline: `3px dashed rgba(24,24,27,${0.8 * d})`, outlineOffset: 24};
    deco = (
      <>
        {[
          [0, 0],
          [1, 0],
          [0, 1],
          [1, 1],
        ].map(([x, y]) => (
          <div
            key={`${x}${y}`}
            style={{
              position: 'absolute',
              left: x ? 'calc(100% + 18px)' : -30,
              top: y ? 'calc(100% + 18px)' : -30,
              width: 12,
              height: 12,
              background: CONSOLE,
              opacity: d,
            }}
          />
        ))}
      </>
    );
  } else if (i === 1) {
    wordStyle = {transform: `translateX(${(1 - prog(f, at, 10, quintOut)) * -260}px)`};
    deco = (
      <>
        {[0, 1, 2].map((k) => (
          <div
            key={k}
            style={{
              position: 'absolute',
              right: '104%',
              top: `${28 + k * 22}%`,
              height: 6,
              width: 260 - k * 60,
              borderRadius: 6,
              background: ACCENT,
              opacity: (1 - prog(f, at + 4, 8)) * 0.8,
              transform: `translateX(${(1 - prog(f, at, 10, quintOut)) * -260}px)`,
            }}
          />
        ))}
      </>
    );
  } else if (i === 3) {
    const sweep = t * 14;
    deco = (
      <div style={{position: 'absolute', left: '50%', top: '50%', width: 0, height: 0}}>
        {[220, 420, 640].map((r) => (
          <div key={r} style={{position: 'absolute', left: -r, top: -r, width: r * 2, height: r * 2, borderRadius: '50%', border: `1.5px solid ${rgbaHex(ACCENT, 0.18)}`}} />
        ))}
        <div
          style={{
            position: 'absolute',
            left: -640,
            top: -640,
            width: 1280,
            height: 1280,
            borderRadius: '50%',
            background: `conic-gradient(from ${sweep}deg, ${rgbaHex(ACCENT, 0.35)} 0deg, transparent 50deg, transparent 360deg)`,
          }}
        />
        <div style={{position: 'absolute', left: 300, top: 180, width: 12, height: 12, borderRadius: 12, background: ACCENT, opacity: t > 6 ? 1 : 0, boxShadow: `0 0 16px ${ACCENT}`}} />
      </div>
    );
  } else if (i === 4) {
    wordStyle = {transform: `translateX(${Math.sin(t * 2.4) * 10 * (1 - prog(f, at + 2, 10))}px)`};
    deco = (
      <div style={{position: 'absolute', left: '50%', top: '50%', width: 0, height: 0}}>
        {[0, 5, 10].map((d) => {
          const p = prog(f, at + d, 14, expoOut);
          const r = 120 + p * 620;
          return p > 0 && p < 1 ? (
            <div key={d} style={{position: 'absolute', left: -r, top: -r, width: r * 2, height: r * 2, borderRadius: '50%', border: `3px solid rgba(236,231,220,${0.5 * (1 - p)})`}} />
          ) : null;
        })}
      </div>
    );
  }

  // LIST LOCKS: an ink highlight sweeps through and flips the letters to cream.
  const bar = i === 2 ? prog(f, at + 2, 9, inOut) : 0;

  return (
    <AbsoluteFill style={{background: tool.bg, overflow: 'hidden'}}>
      <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
        <div style={{position: 'absolute', top: 300, fontFamily: mono, fontSize: 20, letterSpacing: '0.3em', color: ink}}>
          TOOLKIT {'▪'} {String(i + 1).padStart(2, '0')} / 05
        </div>
        <div style={{position: 'relative', transform: `scale(${1.06 - 0.06 * settle})`}}>
          {deco}
          <div style={{position: 'relative', fontFamily: archivo, fontSize: tool.word.length > 9 ? 168 : 200, color: tool.fg, letterSpacing: '-0.02em', lineHeight: 1, whiteSpace: 'nowrap', ...wordStyle}}>
            {tool.word}
            {i === 2 ? (
              <div style={{position: 'absolute', inset: '-8px -16px', clipPath: `inset(0 ${(1 - bar) * 100}% 0 0)`, background: INK, color: '#F7ECE3', padding: '8px 16px', boxSizing: 'border-box'}}>
                {tool.word}
              </div>
            ) : null}
          </div>
        </div>
        <div style={{position: 'absolute', top: 680, fontFamily: mono, fontSize: 30, color: ink, letterSpacing: '0.06em'}}>{tool.sub}</div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

export const ToolkitScene: React.FC = () => {
  const f = useCurrentFrame();
  const W = T.tools.words;
  return (
    <AbsoluteFill>
      {W.map((at, i) => {
        const next = W[i + 1] ?? T.tools.end;
        if (f < at - 3 || f >= next + 4) return null;
        // a symmetric 6-frame dissolve between words, centred on the beat
        const vis = prog(f, at - 3, 6, inOut) * (1 - (i < W.length - 1 ? 0 : prog(f, next - 3, 7, inOut)));
        return (
          <AbsoluteFill key={i} style={{opacity: vis}}>
            <ToolPanel i={i} f={f} />
          </AbsoluteFill>
        );
      })}
    </AbsoluteFill>
  );
};

// --- 04 · settle chart ------------------------------------------------------------------------
const DAYS = [12, 10, 14, 11, 13, 12, 9, 12, 13, 12, 14]; // rotis per working day, Oct 1–15 → 132
const PRICE = 25;
const CUM = DAYS.reduce<number[]>((a, d) => [...a, (a[a.length - 1] ?? 0) + d], []);
const TOTAL = CUM[CUM.length - 1] * PRICE; // Rs 3,300

export const ChartScene: React.FC = () => {
  const f = useCurrentFrame();
  const C = T.chart;
  const enter = prog(f, C.start - 2, 10, inOut);
  const card = prog(f, C.card, 14, quintOut);
  const grow = prog(f, C.countStart, C.countEnd - C.countStart, inOut);
  const bill = Math.round(TOTAL * grow);
  const W = 860;
  const H = 230;
  const X0 = 40;
  const Y0 = 520;
  const pts = CUM.map((c, i) => [X0 + (i / (DAYS.length - 1)) * W, Y0 - (c / CUM[CUM.length - 1]) * H] as const);
  const path = pts.map(([x, y], i) => (i === 0 ? `M${x},${y}` : `L${x},${y}`)).join(' ');
  const area = `${path} L${X0 + W},${Y0} L${X0},${Y0} Z`;
  const settled = f >= C.countEnd;
  const end = pts[pts.length - 1];
  const ring = prog(f, C.countEnd, 16, expoOut);
  const out = prog(f, T.tiles.full - 6, 6, inOut);
  return (
    <AbsoluteFill style={{opacity: enter * (1 - out)}}>
      <div style={{position: 'absolute', left: 118, top: 250, lineHeight: 1}}>
        {[
          {t: 'Order.', at: C.lines[0], s: {fontFamily: jakarta, fontWeight: 800, fontSize: 150, color: TEXT, letterSpacing: '-0.045em'}},
          {t: 'Fetch.', at: C.lines[1], s: {fontFamily: jakarta, fontWeight: 800, fontSize: 150, color: 'rgba(236,231,220,0.5)', letterSpacing: '-0.045em'}},
          {
            t: 'Settle.',
            at: C.lines[2],
            s: {fontFamily: serif, fontStyle: 'italic' as const, fontSize: 178, color: ACCENT, letterSpacing: '-0.01em', textShadow: `0 0 34px ${rgbaHex(ACCENT, 0.35)}`},
          },
        ].map((l) => (
          <div key={l.t} style={{height: 146}}>
            <Rising at={l.at}>
              <span style={l.s}>{l.t}</span>
            </Rising>
          </div>
        ))}
        <div style={{marginTop: 30, fontFamily: mono, fontSize: 28, color: DIM, letterSpacing: '0.04em', opacity: prog(f, C.sub, 10)}}>
          one price per roti {'·'} billed monthly
        </div>
      </div>

      <div
        style={{
          position: 'absolute',
          left: 860,
          top: 236,
          width: 940,
          height: 600,
          borderRadius: 32,
          background: CARD_BG,
          border: `1.5px solid ${LINE}`,
          boxSizing: 'border-box',
          opacity: card,
          transform: `translateY(${(1 - card) * 40}px)`,
          overflow: 'hidden',
          boxShadow: '0 40px 80px -40px rgba(0,0,0,0.9)',
        }}
      >
        <div style={{position: 'absolute', left: 40, top: 36, fontFamily: mono, fontSize: 24, color: DIM}}>bite size {'·'} october {'·'} 11 days</div>
        <div
          style={{
            position: 'absolute',
            right: 32,
            top: 26,
            padding: '10px 20px',
            borderRadius: 999,
            border: `1.5px solid ${rgbaHex(settled ? ACCENT : '#ECE7DC', 0.45)}`,
            background: settled ? rgbaHex(ACCENT, 0.12) : 'transparent',
            fontFamily: mono,
            fontSize: 20,
            letterSpacing: '0.12em',
            color: settled ? ACCENT : DIM,
            display: 'flex',
            alignItems: 'center',
            gap: 10,
          }}
        >
          <span style={{width: 10, height: 10, borderRadius: 10, background: settled ? ACCENT : DIM}} />
          {settled ? 'SETTLED' : 'UNSETTLED'}
        </div>
        <div style={{position: 'absolute', left: 40, top: 96, fontFamily: mono, fontSize: 20, letterSpacing: '0.24em', color: DIM}}>TOTAL BILL</div>
        <div style={{position: 'absolute', left: 36, top: 126, fontFamily: mono, fontWeight: 600, fontSize: 108, color: ACCENT, letterSpacing: '-0.02em', textShadow: `0 0 28px ${rgbaHex(ACCENT, 0.4)}`}}>
          Rs {bill.toLocaleString('en-US')}
        </div>
        <svg width={940} height={600} style={{position: 'absolute', left: 0, top: 0}}>
          <defs>
            <linearGradient id="area" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor={ACCENT} stopOpacity={0.35} />
              <stop offset="100%" stopColor={ACCENT} stopOpacity={0} />
            </linearGradient>
            <clipPath id="grow">
              <rect x={0} y={0} width={X0 + W * grow + 2} height={600} />
            </clipPath>
          </defs>
          {[0.33, 0.66].map((g) => (
            <line key={g} x1={X0} x2={X0 + W} y1={Y0 - H * g} y2={Y0 - H * g} stroke="rgba(236,231,220,0.08)" strokeDasharray="4 8" />
          ))}
          {DAYS.map((d, i) => {
            const bw = 34;
            const x = X0 + (i / (DAYS.length - 1)) * W - bw / 2;
            const h = (d / 14) * 120 * prog(f, C.card + 4 + i * 1.5, 10, expoOut);
            return <rect key={i} x={x} y={Y0 - h} width={bw} height={h} rx={4} fill="rgba(236,231,220,0.09)" />;
          })}
          <g clipPath="url(#grow)">
            <path d={area} fill="url(#area)" />
            <path d={path} fill="none" stroke={ACCENT} strokeWidth={5} strokeLinejoin="round" strokeLinecap="round" style={{filter: `drop-shadow(0 0 8px ${ACCENT})`}} />
          </g>
          {settled ? (
            <>
              <circle cx={end[0]} cy={end[1]} r={10} fill={ACCENT} />
              <circle cx={end[0]} cy={end[1]} r={10 + 26 * ring} fill="none" stroke={ACCENT} strokeOpacity={0.8 * (1 - ring) + 0.25} strokeWidth={2} />
            </>
          ) : null}
          <text x={X0 - 6} y={Y0 + 40} fill="rgba(236,231,220,0.45)" fontFamily={mono} fontSize={18} letterSpacing={2}>
            OCT 1
          </text>
          <text x={X0 + W - 64} y={Y0 + 40} fill="rgba(236,231,220,0.45)" fontFamily={mono} fontSize={18} letterSpacing={2}>
            OCT 15
          </text>
        </svg>
        {/* tags */}
        {[
          {at: C.tags[0], x: pts[4][0] - 70, y: pts[4][1] - 74, html: <>Rs 25 <span style={{color: ACCENT}}>/ roti</span></>},
          {at: C.tags[1], x: end[0] - 250, y: end[1] - 64, html: <>132 rotis <span style={{color: ACCENT}}>billed</span></>},
        ].map((tg, k) => (
          <div
            key={k}
            style={{
              position: 'absolute',
              left: tg.x,
              top: tg.y,
              padding: '10px 18px',
              borderRadius: 12,
              background: '#1B201D',
              border: `1.5px solid ${LINE}`,
              fontFamily: mono,
              fontSize: 22,
              color: TEXT,
              whiteSpace: 'nowrap',
              opacity: prog(f, tg.at, 5),
              transform: `translateY(${(1 - prog(f, tg.at, 10, backOut)) * 14}px)`,
            }}
          >
            {tg.html}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

// --- tile wipe → logo -------------------------------------------------------------------------
const TILE = 56;
const TGAP = 8;
const COLS = Math.ceil(1920 / (TILE + TGAP)) + 1;
const ROWS = Math.ceil(1080 / (TILE + TGAP)) + 1;
export const LOGO_AT = {x: 616, y: 470};

export const TileWipe: React.FC = () => {
  const f = useCurrentFrame();
  const TL = T.tiles;
  const span = TL.full - TL.start - 6;
  const tiles: React.ReactNode[] = [];
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const diag = (c / COLS + (ROWS - 1 - r) / ROWS) / 2; // bottom-left first
      const jitter = random(`t${r}-${c}`) * 0.18;
      const at = TL.start + (diag * 0.82 + jitter) * span;
      const pin = prog(f, at, 7, backOut);
      // out: shrink toward the logo, nearest last
      const x = c * (TILE + TGAP);
      const y = r * (TILE + TGAP);
      const dist = Math.hypot(x - LOGO_AT.x, y - LOGO_AT.y) / 2200;
      const outAt = T.end.start + (1 - dist) * 8 + random(`o${r}-${c}`) * 4;
      const po = prog(f, outAt, 10, expoIn);
      const s = pin * (1 - po);
      if (s <= 0.01) continue;
      const shade = 0.82 + random(`s${r}-${c}`) * 0.18;
      tiles.push(
        <div
          key={`${r}-${c}`}
          style={{
            position: 'absolute',
            left: lerp(x, LOGO_AT.x, po * 0.35),
            top: lerp(y, LOGO_AT.y, po * 0.35),
            width: TILE,
            height: TILE,
            borderRadius: 10,
            background: ACCENT,
            filter: `brightness(${shade})`,
            transform: `scale(${s}) rotate(${(1 - pin) * 25}deg)`,
          }}
        />,
      );
    }
  }
  return <AbsoluteFill>{tiles}</AbsoluteFill>;
};

const WORD = 'bite size';

export const EndScene: React.FC = () => {
  const f = useCurrentFrame();
  const E = T.end;
  const assemble = prog(f, E.logo, 22, (t) => t);
  const slide = prog(f, E.word - 2, 14, inOut);
  const typed = Math.max(0, Math.min(WORD.length, Math.floor((f - E.word) / 1.4)));
  const glow = prog(f, E.logo, 30, expoOut);
  const logoX = lerp(960, LOGO_AT.x, slide);
  return (
    <AbsoluteFill>
      <ConsoleBg glow={glow} glowAt={{x: logoX, y: LOGO_AT.y}} />
      {/* radar rings + drifting particles */}
      {[0, 8].map((d) => {
        const p = prog(f, E.logo + d, 26, expoOut);
        const r = 90 + p * 900;
        return p > 0 && p < 1 ? (
          <div key={d} style={{position: 'absolute', left: logoX - r, top: LOGO_AT.y - r, width: r * 2, height: r * 2, borderRadius: '50%', border: `2px solid ${rgbaHex(ACCENT, 0.5 * (1 - p))}`}} />
        ) : null;
      })}
      {Array.from({length: 46}).map((_, i) => {
        const a = random(`pa${i}`) * Math.PI * 2;
        const sp = 80 + random(`ps${i}`) * 420;
        const p = prog(f, E.logo + random(`pd${i}`) * 8, 70, expoOut);
        if (p <= 0) return null;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: logoX + Math.cos(a) * sp * p,
              top: LOGO_AT.y + Math.sin(a) * sp * p * 0.7,
              width: 4,
              height: 4,
              borderRadius: 4,
              background: ACCENT,
              opacity: (1 - p) * 0.9,
            }}
          />
        );
      })}
      <div style={{position: 'absolute', left: logoX - 78, top: LOGO_AT.y - 78}}>
        <PixelRoti cell={14} gap={4} assemble={assemble} seed="end" />
      </div>
      <div
        style={{
          position: 'absolute',
          left: logoX + 112,
          top: LOGO_AT.y - 72,
          fontFamily: mono,
          fontWeight: 500,
          fontSize: 124,
          color: TEXT,
          letterSpacing: '-0.02em',
          whiteSpace: 'pre',
          display: 'flex',
          alignItems: 'center',
          opacity: prog(f, E.word - 2, 3),
        }}
      >
        {WORD.slice(0, typed)}
        <span style={{display: 'inline-block', width: 10, height: 112, marginLeft: 8, background: ACCENT, opacity: typed < WORD.length || Math.floor(f / 9) % 2 === 0 ? 1 : 0.1, boxShadow: `0 0 18px ${rgbaHex(ACCENT, 0.7)}`}} />
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 600, textAlign: 'center', fontFamily: serif, fontStyle: 'italic', fontSize: 64, color: TEXT, whiteSpace: 'nowrap'}}>
        <Rising at={E.tagline}>
          <span>Any other orders?</span>
        </Rising>
      </div>
      <div style={{position: 'absolute', left: 0, right: 0, top: 700, display: 'flex', justifyContent: 'center', opacity: prog(f, E.url, 10)}}>
        <span style={{fontFamily: mono, fontSize: 28, color: ACCENT, letterSpacing: '0.06em', borderBottom: `2px solid ${rgbaHex(ACCENT, 0.6)}`, paddingBottom: 6}}>
          office lunch {'·'} ground booking
        </span>
      </div>
    </AbsoluteFill>
  );
};
