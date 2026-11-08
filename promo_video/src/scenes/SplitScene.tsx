import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {Trail} from '@remotion/motion-blur';
import {backOut, expoOut, inOut, lerp, prog, punch, quintOut, T} from '../anim';
import {Echo} from '../components/Echo';
import {
  Avatar,
  BowlIcon,
  Card,
  CheckBadge,
  CheckIcon,
  ClickRing,
  Cursor,
  LockIcon,
  Pill,
  PlusIcon,
  RotiIcon,
  RunnerIcon,
} from '../components/Ui';
import {c, lunchPack, mono, palette, rs, sans, serif, tint, withAlpha} from '../theme';
import {PUSH_SCALE, runRows} from './SolutionScene';

const CARD1 = {x: 100, y: 118, w: 554, h: 862};
const CARD2 = {x: 682, y: 118, w: 554, h: 470};
const CARD3 = {x: 682, y: 616, w: 554, h: 364};
const CARD4 = {x: 1264, y: 118, w: 554, h: 862};
const PAD = 36;
const JOIN = {x: PAD, y: CARD2.h - PAD - 78, w: CARD2.w - PAD * 2, h: 78};
const JOIN_CENTER = {x: CARD2.x + JOIN.x + JOIN.w / 2, y: CARD2.y + JOIN.y + JOIN.h / 2};
// Phone button text is 26px, this one 32px: start the pull so both read the same size.
const PULL_SCALE = (PUSH_SCALE * 26) / 32;

const P = lunchPack.primary;
const A = lunchPack.accent;

const Label: React.FC<{text: string; right?: React.ReactNode}> = ({text, right}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      fontFamily: mono,
      fontSize: 24,
      color: c.textTertiary,
      height: 40,
    }}
  >
    <span>{text}</span>
    {right}
  </div>
);

const enterStyle = (frame: number, at: number): React.CSSProperties => {
  const p = prog(frame, at, 18, expoOut);
  return {
    opacity: prog(frame, at, 6),
    transform: `translateY(${(1 - p) * 70}px) rotate(${(1 - p) * 2.5}deg) scale(${0.96 + 0.04 * p})`,
    transformOrigin: '50% 100%',
  };
};

const lineIn = (frame: number, at: number): React.CSSProperties => {
  const p = prog(frame, at, 12, expoOut);
  return {opacity: prog(frame, at, 5), transform: `translateY(${(1 - p) * 16}px)`};
};

const count = (frame: number, at: number, to: number, dur = 14) =>
  Math.round(to * prog(frame, at, dur, quintOut));

// --- Card 1: the run --------------------------------------------------------
const RunCard: React.FC<{frame: number}> = ({frame}) => {
  const locked = frame >= T.split.lock;
  const lockPunch = punch(frame, T.split.lock, 16, 1);
  const lockDrop = prog(frame, T.split.lock, 12, backOut);
  const totalRotis = runRows.reduce((s, r) => s + r.rotis, 0);
  return (
    <Card
      style={{
        left: CARD1.x,
        top: CARD1.y,
        width: CARD1.w,
        height: CARD1.h,
        padding: PAD,
        ...enterStyle(frame, T.split.card1),
        translate: `${lockPunch * 6}px 0`,
      }}
    >
      <Label
        text="// the run"
        right={
          locked ? (
            <Pill bg={c.text} fg="#FFFFFF" size={20} style={{transform: `scale(${1 + lockPunch * 0.25})`}}>
              <LockIcon size={20} color="#FFFFFF" stroke={2.8} />
              locked
            </Pill>
          ) : (
            <Pill bg={tint(P, 0.1)} fg={P} size={20}>
              <span style={{width: 10, height: 10, borderRadius: 10, background: P}} />
              open
            </Pill>
          )
        }
      />
      <div style={{marginTop: 22, fontFamily: sans, fontWeight: 600, fontSize: 50, letterSpacing: '-0.03em', color: c.text}}>
        Tandoor run
      </div>
      <div style={{display: 'flex', alignItems: 'center', gap: 10, marginTop: 6, fontFamily: mono, fontSize: 23, color: c.textSecondary}}>
        <RotiIcon size={26} color={A} />
        rotis · Rs 25 each
      </div>

      {/* Runner: who is fetching */}
      <div
        style={{
          marginTop: 28,
          height: 96,
          borderRadius: 22,
          background: tint(A, 0.1),
          display: 'flex',
          alignItems: 'center',
          gap: 16,
          padding: '0 22px',
          ...lineIn(frame, T.split.runner),
        }}
      >
        <Avatar initial="A" bg={tint(A, 0.25)} size={54} />
        <div style={{flex: 1, whiteSpace: 'nowrap'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 10}}>
            <span style={{fontFamily: sans, fontWeight: 600, fontSize: 30, color: c.text}}>Ali</span>
            <Pill bg={A} fg="#FFFFFF" size={17}>
              runner
            </Pill>
          </div>
          <div style={{fontFamily: mono, fontSize: 20, color: c.textSecondary, marginTop: 2}}>
            fetching · {locked ? 'left 1:15' : 'leaves 1:15'}
          </div>
        </div>
        <RunnerIcon
          size={34}
          color={A}
          style={{transform: `translateX(${locked ? lockDrop * 10 : 0}px)`, opacity: locked ? 1 - 0.5 * lockDrop : 1}}
        />
      </div>

      <div style={{marginTop: 30, display: 'flex', justifyContent: 'space-between', fontFamily: mono, fontSize: 22, color: c.textTertiary, ...lineIn(frame, T.split.rows[0] - 2)}}>
        <span>// who's in</span>
        <span>{runRows.filter((_, i) => frame >= T.split.rows[i]).length} people</span>
      </div>
      <div style={{marginTop: 10}}>
        {runRows.map((r, i) => (
          <div
            key={r.name}
            style={{
              height: 64,
              display: 'flex',
              alignItems: 'center',
              gap: 16,
              borderBottom: `1.5px solid ${c.divider}`,
              ...lineIn(frame, T.split.rows[i]),
            }}
          >
            <Avatar initial={r.initial} bg={r.color} size={44} />
            <div style={{flex: 1, fontFamily: sans, fontWeight: 500, fontSize: 29, color: c.text}}>
              {r.name}
              {r.name === 'Hina' ? <span style={{fontFamily: mono, fontSize: 19, color: c.textTertiary}}> (you)</span> : null}
            </div>
            <div style={{fontFamily: mono, fontWeight: 500, fontSize: 28, color: c.text}}>{r.rotis}</div>
            <RotiIcon size={26} color={A} />
          </div>
        ))}
        {/* Join slot → lock row */}
        <div style={{height: 70, marginTop: 10, position: 'relative', ...lineIn(frame, T.split.rows[3] + 4)}}>
          <div
            style={{
              position: 'absolute',
              inset: 0,
              borderRadius: 18,
              border: `2px dashed ${c.border}`,
              display: 'flex',
              alignItems: 'center',
              gap: 10,
              padding: '0 18px',
              fontFamily: mono,
              fontSize: 22,
              color: c.textTertiary,
              opacity: locked ? 1 - prog(frame, T.split.lock, 6) : 1,
            }}
          >
            <PlusIcon size={24} color={c.textTertiary} />
            I'm in
          </div>
          {locked ? (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                borderRadius: 18,
                background: c.text,
                display: 'flex',
                alignItems: 'center',
                gap: 14,
                padding: '0 18px',
                fontFamily: sans,
                fontWeight: 600,
                fontSize: 25,
                color: '#FFFFFF',
                opacity: prog(frame, T.split.lock, 5),
                transform: `scale(${1 + lockPunch * 0.06})`,
              }}
            >
              <div style={{transform: `translateY(${(1 - lockDrop) * -26}px)`}}>
                <LockIcon size={30} color="#FFFFFF" stroke={2.6} />
              </div>
              List locked
              <span style={{fontFamily: mono, fontWeight: 400, fontSize: 20, color: 'rgba(255,255,255,0.7)'}}>
                · runner left
              </span>
            </div>
          ) : null}
        </div>
      </div>

      <div
        style={{
          position: 'absolute',
          left: PAD,
          right: PAD,
          bottom: PAD,
          paddingTop: 22,
          borderTop: `1.5px solid ${c.divider}`,
          display: 'flex',
          alignItems: 'baseline',
          justifyContent: 'space-between',
          ...lineIn(frame, T.split.total),
        }}
      >
        <span style={{fontFamily: mono, fontSize: 23, color: c.textSecondary}}>
          {totalRotis} rotis × Rs 25
        </span>
        <span style={{fontFamily: mono, fontWeight: 600, fontSize: 42, color: c.text}}>
          {rs(count(frame, T.split.total, 300))}
        </span>
      </div>
    </Card>
  );
};

// --- Card 2: shared cost as an invitation ----------------------------------
const SharedCard: React.FC<{frame: number}> = ({frame}) => {
  const joined = frame >= T.split.joined;
  const flip = punch(frame, T.split.joined, 12, 1);
  const people = [
    {i: 'B', bg: tint(palette.info, 0.16), at: -1},
    {i: 'H', bg: tint(palette.grey600, 0.14), at: T.split.avatars[0], you: true},
    {i: 'S', bg: tint(P, 0.16), at: T.split.avatars[1]},
  ];
  const n = people.filter((p) => frame >= p.at).length;
  const each = 480 / n;
  const eachPunch = punch(frame, T.split.avatars[Math.max(0, n - 2)] ?? 0, 10, 0.12);
  return (
    <Card style={{left: CARD2.x, top: CARD2.y, width: CARD2.w, height: CARD2.h, padding: PAD}}>
      <Label
        text="// shared cost"
        right={
          <Pill bg={tint(A, 0.12)} fg={A} size={20}>
            invite
          </Pill>
        }
      />
      <div style={{display: 'flex', alignItems: 'center', gap: 18, marginTop: 24}}>
        <div
          style={{
            width: 76,
            height: 76,
            borderRadius: 22,
            background: tint(A, 0.14),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <BowlIcon size={44} color={A} />
        </div>
        <div>
          <div style={{fontFamily: sans, fontWeight: 600, fontSize: 44, letterSpacing: '-0.03em', color: c.text, whiteSpace: 'nowrap'}}>
            Extra salan
          </div>
          <div style={{fontFamily: mono, fontSize: 22, color: c.textSecondary, whiteSpace: 'nowrap'}}>
            <span style={{fontWeight: 600, color: c.text}}>Rs 480</span> · shared by Bilal
          </div>
        </div>
      </div>

      <div style={{display: 'flex', alignItems: 'center', gap: 18, marginTop: 34}}>
        <div style={{display: 'flex'}}>
          {people.map((p, k) => {
            const s = p.at < 0 ? 1 : prog(frame, p.at, 12, backOut);
            if (s <= 0) return null;
            return (
              <Avatar
                key={p.i}
                initial={p.i}
                bg={p.bg}
                size={58}
                ring={p.you ? P : c.surface}
                style={{marginLeft: k === 0 ? 0 : -12, transform: `scale(${s})`, zIndex: 3 - k}}
              />
            );
          })}
        </div>
        <div style={{fontFamily: mono, fontSize: 25, color: c.textSecondary}}>
          {n} in ·{' '}
          <span
            style={{
              display: 'inline-block',
              fontWeight: 600,
              color: n > 1 ? P : c.text,
              transform: `scale(${1 + eachPunch})`,
              transformOrigin: '0% 50%',
            }}
          >
            {rs(each)} each
          </span>
        </div>
      </div>

      <div
        style={{
          position: 'absolute',
          left: JOIN.x,
          top: JOIN.y,
          width: JOIN.w,
          height: JOIN.h,
          borderRadius: 20,
          background: joined ? tint(P, 0.12) : P,
          color: joined ? P : '#FFFFFF',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 12,
          fontFamily: sans,
          fontWeight: 600,
          fontSize: 32,
          transform: `scale(${1 + flip * 0.05})`,
        }}
      >
        {joined ? <CheckIcon size={34} color={P} stroke={3.2} draw={prog(frame, T.split.joined, 10)} /> : null}
        {joined ? 'Joined' : 'Join'}
      </div>
    </Card>
  );
};

// --- Card 3: your share today ----------------------------------------------
const ShareCard: React.FC<{frame: number}> = ({frame}) => {
  const row = (at: number, left: string, right: number, strong = false) => (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'baseline',
        marginTop: strong ? 0 : 14,
        ...lineIn(frame, at),
      }}
    >
      <span style={{fontFamily: strong ? sans : mono, fontWeight: strong ? 600 : 400, fontSize: strong ? 32 : 25, color: strong ? c.text : c.textSecondary}}>
        {left}
      </span>
      <span style={{fontFamily: mono, fontWeight: 600, fontSize: strong ? 44 : 28, color: strong ? P : c.text}}>
        {rs(count(frame, at, right))}
      </span>
    </div>
  );
  return (
    <Card style={{left: CARD3.x, top: CARD3.y, width: CARD3.w, height: CARD3.h, padding: PAD, ...enterStyle(frame, T.split.card3)}}>
      <Label text="// your share · today" right={<Avatar initial="H" bg={tint(palette.grey600, 0.14)} size={40} ring={P} />} />
      <div style={{marginTop: 18}}>
        {row(T.split.share[0], '3 rotis × Rs 25', 75)}
        {row(T.split.share[1], 'salan ÷ 3', 160)}
      </div>
      <div style={{marginTop: 22, paddingTop: 18, borderTop: `1.5px solid ${c.divider}`}}>{row(T.split.share[2], 'Hina pays', 235, true)}</div>
    </Card>
  );
};

// --- Card 4: month-end ledger ------------------------------------------------
const ledger = [
  {name: 'Ali', initial: 'A', bg: tint(A, 0.2), amount: 1840},
  {name: 'Sara', initial: 'S', bg: tint(P, 0.16), amount: -620},
  {name: 'Bilal', initial: 'B', bg: tint(palette.info, 0.16), amount: -740},
  {name: 'Hina', initial: 'H', bg: tint(palette.grey600, 0.14), amount: -480},
];

const LedgerCard: React.FC<{frame: number}> = ({frame}) => {
  const bars = prog(frame, T.split.net - 8, 16, inOut);
  const owed = ledger.filter((l) => l.amount < 0);
  const owedTotal = owed.reduce((s, l) => s - l.amount, 0);
  const shades = [A, tint(A, 0.62), tint(A, 0.38)];
  return (
    <Card style={{left: CARD4.x, top: CARD4.y, width: CARD4.w, height: CARD4.h, padding: PAD, ...enterStyle(frame, T.split.card4)}}>
      <Label
        text="// october ledger"
        right={
          <Pill bg={tint(P, 0.1)} fg={P} size={20}>
            month-end
          </Pill>
        }
      />
      <div style={{marginTop: 22, fontFamily: sans, fontWeight: 600, fontSize: 50, letterSpacing: '-0.03em', color: c.text}}>Settle up</div>
      <div style={{marginTop: 6, fontFamily: mono, fontSize: 23, color: c.textSecondary}}>31 Oct · 4 people</div>

      <div style={{marginTop: 26}}>
        {ledger.map((l, i) => {
          const gets = l.amount > 0;
          return (
            <div
              key={l.name}
              style={{
                height: 82,
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                borderBottom: `1.5px solid ${c.divider}`,
                ...lineIn(frame, T.split.ledger[i]),
              }}
            >
              <Avatar initial={l.initial} bg={l.bg} size={48} />
              <div style={{flex: 1}}>
                <div style={{fontFamily: sans, fontWeight: 500, fontSize: 29, color: c.text}}>{l.name}</div>
                <div style={{fontFamily: mono, fontSize: 19, color: gets ? P : A}}>{gets ? 'gets back' : 'owes'}</div>
              </div>
              <div style={{fontFamily: mono, fontWeight: 600, fontSize: 31, color: gets ? P : c.text}}>
                {rs(count(frame, T.split.ledger[i], Math.abs(l.amount), 16))}
              </div>
            </div>
          );
        })}
      </div>

      {/* The two sides, drawn to scale: they end at the same point. */}
      <div style={{marginTop: 26, opacity: prog(frame, T.split.net - 8, 6)}}>
        <div style={{height: 22, borderRadius: 11, background: tint(P, 0.08), overflow: 'hidden'}}>
          <div style={{width: `${bars * 100}%`, height: '100%', background: P, borderRadius: 11}} />
        </div>
        <div style={{height: 22, marginTop: 10, borderRadius: 11, background: tint(A, 0.08), overflow: 'hidden', display: 'flex'}}>
          {owed.map((l, k) => (
            <div
              key={l.name}
              style={{
                width: `${(-l.amount / owedTotal) * bars * 100}%`,
                height: '100%',
                background: shades[k],
                borderRight: k < owed.length - 1 ? `3px solid ${c.surface}` : undefined,
              }}
            />
          ))}
        </div>
        <div style={{display: 'flex', justifyContent: 'space-between', marginTop: 10, fontFamily: mono, fontSize: 19, color: c.textTertiary}}>
          <span>gets back {rs(1840)}</span>
          <span>owes {rs(owedTotal)}</span>
        </div>
      </div>

      <div
        style={{
          position: 'absolute',
          left: PAD,
          right: PAD,
          bottom: PAD,
          paddingTop: 22,
          borderTop: `1.5px solid ${c.divider}`,
          display: 'flex',
          alignItems: 'center',
          gap: 14,
          ...lineIn(frame, T.split.net),
        }}
      >
        <span style={{flex: 1, fontFamily: sans, fontWeight: 600, fontSize: 34, color: c.text}}>Net</span>
        <span style={{fontFamily: mono, fontWeight: 600, fontSize: 44, color: P}}>Rs 0</span>
        <div style={{position: 'relative', width: 44, height: 44}}>
          <CheckBadge
            size={44}
            bg={P}
            pop={prog(frame, T.split.net + 2, 12, backOut)}
            draw={prog(frame, T.split.net + 6, 10)}
            style={{left: 0, top: 0, boxShadow: 'none'}}
          />
        </div>
      </div>
    </Card>
  );
};

const Stamp: React.FC = () => {
  const frame = useCurrentFrame();
  const slam = prog(frame, T.split.stamp, 8, expoOut);
  const settle = prog(frame, T.split.stampSettle, 14, inOut);
  if (frame < T.split.stamp) return null;
  const s = lerp(lerp(2.3, 1, slam), 0.34, settle);
  const x = lerp(960, CARD3.x + CARD3.w / 2, settle);
  const y = lerp(540, 1012, settle);
  const rot = lerp(-8, -5, settle);
  const bands = 1 - settle;
  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        transform: `translate(-50%, -50%) rotate(${rot}deg) scale(${s})`,
        opacity: prog(frame, T.split.stamp, 3),
      }}
    >
      <div style={{position: 'relative', padding: '10px 70px 34px'}}>
        {/* Ribbon bands while it slams, a stamp border once it lands */}
        <div style={{position: 'absolute', left: -900, right: -900, top: 42, height: 26, background: P, opacity: bands}} />
        <div style={{position: 'absolute', left: -900, right: -900, bottom: 22, height: 14, background: P, opacity: bands * 0.85}} />
        <div
          style={{
            position: 'absolute',
            inset: 0,
            borderRadius: 60,
            border: `16px solid ${P}`,
            background: withAlpha(c.surface, 0.94),
            opacity: settle,
          }}
        />
        <div
          style={{
            position: 'relative',
            fontFamily: serif,
            fontStyle: 'italic',
            fontSize: 330,
            lineHeight: 1,
            color: P,
            whiteSpace: 'nowrap',
            letterSpacing: '-0.01em',
          }}
        >
          Adds up.
        </div>
      </div>
    </div>
  );
};

const Grid: React.FC = () => {
  const frame = useCurrentFrame();
  const g = prog(frame, T.split.pullStart, 20);
  const vx = [CARD1.x, CARD1.x + CARD1.w, CARD2.x, CARD2.x + CARD2.w, CARD4.x, CARD4.x + CARD4.w];
  const hy = [CARD1.y, CARD2.y + CARD2.h, CARD3.y, CARD1.y + CARD1.h];
  const stampDim = frame >= T.split.stamp ? (1 - prog(frame, T.split.stampSettle, 12)) * 0.55 : 0;

  const badgeCards = [CARD1, CARD2, CARD3, CARD4];
  return (
    <AbsoluteFill style={{background: c.bg}}>
      {vx.map((x) => (
        <div key={`v${x}`} style={{position: 'absolute', left: x, top: 0, bottom: 0, width: 1.5, background: c.divider, opacity: 0.8 * g}} />
      ))}
      {hy.map((y) => (
        <div key={`h${y}`} style={{position: 'absolute', top: y, left: 0, right: 0, height: 1.5, background: c.divider, opacity: 0.8 * g}} />
      ))}
      {/* Placeholders the cards land into */}
      {[CARD1, CARD3, CARD4].map((k, i) => (
        <Card key={i} dashed style={{left: k.x, top: k.y, width: k.w, height: k.h, opacity: g}} />
      ))}
      <RunCard frame={frame} />
      <SharedCard frame={frame} />
      <ShareCard frame={frame} />
      <LedgerCard frame={frame} />
      <AbsoluteFill style={{background: c.bg, opacity: stampDim}} />
      {badgeCards.map((k, i) => (
        <CheckBadge
          key={i}
          size={50}
          bg={P}
          pop={prog(frame, T.split.badges[i], 12, backOut)}
          draw={prog(frame, T.split.badges[i] + 3, 10)}
          style={{left: k.x + k.w - 25, top: k.y - 25, boxShadow: `0 0 0 6px ${c.bg}`}}
        />
      ))}
      {frame >= T.split.pullStart && frame < T.split.joined + 12 ? (
        <>
          <ClickRing x={JOIN_CENTER.x + 14} y={JOIN_CENTER.y + 4} t={prog(frame, T.split.joined, 12, expoOut)} color={tint(P, 0.5)} />
          <Cursor
            x={JOIN_CENTER.x + 6}
            y={JOIN_CENTER.y}
            press={Math.max(0, punch(frame, T.split.joined - 2, 8, 1))}
            opacity={1 - prog(frame, T.split.joined + 4, 8)}
          />
        </>
      ) : null}
    </AbsoluteFill>
  );
};

const Pulled: React.FC = () => {
  const frame = useCurrentFrame();
  const p = prog(frame, T.split.pullStart, T.split.pullEnd - T.split.pullStart, (t) => t);
  const s = Math.pow(PULL_SCALE, 1 - expoOut(p));
  const k = (s - 1) / (PULL_SCALE - 1);
  const tx = (960 - JOIN_CENTER.x) * k;
  const ty = (540 - JOIN_CENTER.y) * k;
  return (
    <AbsoluteFill
      style={{
        transform: `translate(${tx}px, ${ty}px) scale(${s})`,
        transformOrigin: `${JOIN_CENTER.x}px ${JOIN_CENTER.y}px`,
      }}
    >
      <Grid />
    </AbsoluteFill>
  );
};

export const SplitScene: React.FC = () => {
  const frame = useCurrentFrame();
  const pulling = frame < T.split.pullEnd + 2;
  const slamming = frame >= T.split.stamp && frame < T.split.stampSettle + 16;
  return (
    <AbsoluteFill style={{background: c.bg, overflow: 'hidden'}}>
      {pulling ? (
        <Echo layers={3} lag={1} strength={0.34}>
          <Pulled />
        </Echo>
      ) : (
        <Pulled />
      )}
      {slamming ? (
        <Trail layers={5} lagInFrames={1} trailOpacity={0.5}>
          <Stamp />
        </Trail>
      ) : (
        <Stamp />
      )}
    </AbsoluteFill>
  );
};
