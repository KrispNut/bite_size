import React from 'react';
import {AbsoluteFill, random, useCurrentFrame} from 'remotion';
import {Echo} from '../components/Echo';
import {backOut, expoIn, expoOut, inOut, lerp, prog, punch, T} from '../anim';
import {Accent, MonoLabel, Words} from '../components/Type';
import {Avatar, BowlIcon, cardShadow, ClickRing, Cursor, Pill, RotiIcon} from '../components/Ui';
import {c, lunchPack, mono, palette, sans, tint, withAlpha} from '../theme';

export const PHONE = {x: 1190, y: 92, w: 470, h: 896, r: 66};
export const SCREEN = {x: 1202, y: 104, w: 446, h: 872, r: 54};
const HEADER_H = 300;
const BIG = {x: 1110, y0: 300, step: 128, w: 620, h: 108};
const SMALL = {scale: 0.6, y0: 466, step: 74};
const SMALL_X = SCREEN.x + (SCREEN.w - BIG.w * SMALL.scale) / 2;
export const INVITE = {x: SCREEN.x + 20, y: 776, w: 406, h: 176};
export const PHONE_JOIN = {x: INVITE.x + 20, y: INVITE.y + 102, w: 366, h: 56};
export const PHONE_JOIN_CENTER = {
  x: PHONE_JOIN.x + PHONE_JOIN.w / 2,
  y: PHONE_JOIN.y + PHONE_JOIN.h / 2,
};
export const PUSH_SCALE = 24;

export const runRows = [
  {name: 'Ali', initial: 'A', rotis: 3, color: tint(lunchPack.accent, 0.2)},
  {name: 'Sara', initial: 'S', rotis: 2, color: tint(lunchPack.primary, 0.16)},
  {name: 'Bilal', initial: 'B', rotis: 4, color: tint(palette.info, 0.16)},
  {name: 'Hina', initial: 'H', rotis: 3, color: tint(palette.grey600, 0.14)},
];

const RunRow: React.FC<{i: number}> = ({i}) => {
  const r = runRows[i];
  return (
    <div
      style={{
        width: BIG.w,
        height: BIG.h,
        borderRadius: 26,
        background: c.surface,
        boxShadow: cardShadow,
        display: 'flex',
        alignItems: 'center',
        padding: '0 32px 0 26px',
        gap: 20,
        boxSizing: 'border-box',
      }}
    >
      <Avatar initial={r.initial} bg={r.color} size={58} />
      <div style={{fontFamily: sans, fontWeight: 600, fontSize: 36, color: c.text, flex: 1}}>
        {r.name}
        {r.name === 'Hina' ? (
          <span style={{fontFamily: mono, fontWeight: 400, fontSize: 22, color: c.textTertiary}}> (you)</span>
        ) : null}
      </div>
      <RotiIcon size={38} color={lunchPack.accent} />
      <div style={{fontFamily: mono, fontWeight: 500, fontSize: 32, color: c.text}}>
        {r.rotis} rotis
      </div>
    </div>
  );
};

export const Wordmark: React.FC<{at: number; color: string; size: number}> = ({at, color, size}) => {
  const frame = useCurrentFrame();
  const letters = 'Bite Size'.split('');
  return (
    <div
      style={{
        fontFamily: sans,
        fontWeight: 700,
        fontSize: size,
        letterSpacing: '-0.045em',
        color,
        lineHeight: 1,
        whiteSpace: 'pre',
        display: 'flex',
      }}
    >
      {letters.map((l, i) => {
        const p = prog(frame, at + i * 2, 16, backOut);
        return (
          <span key={i} style={{display: 'inline-block', overflow: 'hidden', padding: '0.04em 0.02em 0.08em', margin: '-0.04em -0.02em -0.08em'}}>
            <span style={{display: 'inline-block', transform: `translateY(${(1 - p) * 105}%)`}}>{l}</span>
          </span>
        );
      })}
    </div>
  );
};

const PhoneHeaderContent: React.FC<{frame: number}> = ({frame}) => {
  const a = (d: number) => prog(frame, T.brand.morphEnd - 6 + d, 14, expoOut);
  const rise = (d: number): React.CSSProperties => ({
    opacity: a(d),
    transform: `translateY(${(1 - a(d)) * 18}px)`,
  });
  return (
    <>
      <div style={{position: 'absolute', left: 34, top: 20, fontFamily: sans, fontWeight: 600, fontSize: 19, color: '#FFFFFF', ...rise(0)}}>
        9:41
      </div>
      <div
        style={{
          position: 'absolute',
          right: 34,
          top: 24,
          width: 30,
          height: 14,
          borderRadius: 4,
          border: '2px solid rgba(255,255,255,0.85)',
          ...rise(0),
        }}
      >
        <div style={{position: 'absolute', left: 2, top: 2, bottom: 2, width: 18, borderRadius: 2, background: '#FFFFFF'}} />
      </div>
      <div style={{position: 'absolute', left: 30, top: 70, ...rise(2)}}>
        <Pill bg="rgba(255,255,255,0.16)" fg="#FFFFFF" size={18}>
          <RotiIcon size={20} color="#FFFFFF" stroke={2.6} />
          Office Lunch
        </Pill>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 30,
          top: 122,
          fontFamily: sans,
          fontWeight: 600,
          fontSize: 46,
          letterSpacing: '-0.03em',
          color: '#FFFFFF',
          ...rise(4),
        }}
      >
        Tandoor run
      </div>
      <div
        style={{
          position: 'absolute',
          left: 24,
          right: 24,
          top: 202,
          height: 70,
          borderRadius: 20,
          background: 'rgba(255,255,255,0.12)',
          display: 'flex',
          alignItems: 'center',
          gap: 14,
          padding: '0 16px',
          ...rise(6),
        }}
      >
        <Avatar initial="A" bg={tint(lunchPack.accent, 0.25)} size={44} />
        <div style={{flex: 1}}>
          <div style={{fontFamily: sans, fontWeight: 600, fontSize: 22, color: '#FFFFFF'}}>Ali is the runner</div>
          <div style={{fontFamily: mono, fontSize: 16, color: 'rgba(255,255,255,0.72)'}}>leaves for the tandoor 1:15</div>
        </div>
      </div>
    </>
  );
};

const Inner: React.FC = () => {
  const frame = useCurrentFrame();
  const morph = prog(frame, T.brand.morphStart, T.brand.morphEnd - T.brand.morphStart, inOut);

  // Emerald field → phone header.
  const fx = lerp(0, SCREEN.x, morph);
  const fy = lerp(0, SCREEN.y, morph);
  const fw = lerp(1920, SCREEN.w, morph);
  const fh = lerp(1080, HEADER_H, morph);
  const fr = lerp(0, SCREEN.r, morph);

  const brandOut = prog(frame, T.brand.morphStart, 10, expoIn);
  const phoneIn = prog(frame, T.brand.morphStart + 6, 14, expoOut);

  const invite = prog(frame, T.phone.invite, 14, backOut);
  const inviteA = prog(frame, T.phone.invite, 6, expoOut);

  // Cursor glides to the Join button, presses it.
  const cur = prog(frame, T.phone.cursorIn, T.phone.click - T.phone.cursorIn - 2, inOut);
  const cx = lerp(1720, PHONE_JOIN_CENTER.x + 14, cur);
  const cy = lerp(1100, PHONE_JOIN_CENTER.y + 4, cur);
  const press = Math.max(0, punch(frame, T.phone.click, 8, 1));
  const pressed = frame >= T.phone.click && frame < T.phone.click + 4 ? 1 : 0;

  return (
    <AbsoluteFill style={{background: c.bg}}>
      {/* Left statement (appears as the phone lands) */}
      <div style={{position: 'absolute', left: 150, top: 352}}>
        <MonoLabel at={T.phone.headline[0] - 4} text="// one list, one runner" color={c.textTertiary} size={26} />
        <div
          style={{
            marginTop: 26,
            fontFamily: sans,
            fontWeight: 600,
            fontSize: 112,
            lineHeight: 1.06,
            letterSpacing: '-0.035em',
            color: c.text,
          }}
        >
          <div>
            <Words text="One list." at={T.phone.headline[0]} />
          </div>
          <div style={{whiteSpace: 'nowrap'}}>
            <Words text="Zero" at={T.phone.headline[1]} />{' '}
            <Accent at={T.phone.headline[2]} color={lunchPack.primary}>
              arguments.
            </Accent>
          </div>
        </div>
      </div>

      {/* Phone body + bezel */}
      <div
        style={{
          position: 'absolute',
          left: PHONE.x,
          top: PHONE.y,
          width: PHONE.w,
          height: PHONE.h,
          borderRadius: PHONE.r,
          background: palette.navy900,
          opacity: phoneIn,
          transform: `scale(${1.03 - 0.03 * phoneIn})`,
          boxShadow: `0 40px 80px -30px ${withAlpha(palette.shadowLight, 0.45)}`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: SCREEN.x,
          top: SCREEN.y,
          width: SCREEN.w,
          height: SCREEN.h,
          borderRadius: SCREEN.r,
          background: c.bg,
          opacity: phoneIn,
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            position: 'absolute',
            left: 26,
            right: 26,
            top: HEADER_H + 22,
            display: 'flex',
            justifyContent: 'space-between',
            fontFamily: mono,
            fontSize: 18,
            color: c.textTertiary,
            opacity: prog(frame, T.brand.morphEnd - 2, 10),
          }}
        >
          <span>// who's in</span>
          <span>12 rotis</span>
        </div>
      </div>

      {/* Emerald field: full-bleed brand moment, then the phone's header */}
      <div
        style={{
          position: 'absolute',
          left: fx,
          top: fy,
          width: fw,
          height: fh,
          background: lunchPack.primary,
          borderTopLeftRadius: fr,
          borderTopRightRadius: fr,
          overflow: 'hidden',
        }}
      >
        {morph > 0.6 ? <PhoneHeaderContent frame={frame} /> : null}
      </div>
      {/* Dynamic island sits above the header */}
      <div
        style={{
          position: 'absolute',
          left: PHONE.x + PHONE.w / 2 - 62,
          top: SCREEN.y + 12,
          width: 124,
          height: 36,
          borderRadius: 20,
          background: palette.navy900,
          opacity: phoneIn,
        }}
      />

      {/* Brand */}
      <div
        style={{
          position: 'absolute',
          left: 150,
          top: 372,
          opacity: 1 - brandOut,
          transform: `translateX(${-brandOut * 80}px)`,
        }}
      >
        <MonoLabel at={T.brand.label} text="// shared costs, sorted" color="rgba(255,255,255,0.72)" size={26} />
        <div style={{marginTop: 30}}>
          <Wordmark at={T.brand.letters} color="#FFFFFF" size={210} />
        </div>
      </div>

      {/* Chat bubbles land as tidy rows, then file into the phone */}
      {runRows.map((_, i) => {
        const start = T.brand.rowsIn + i * 4;
        const snap = T.brand.rowSnaps[i];
        const travel = prog(frame, start, snap - start, expoOut);
        const settle = prog(frame, snap, 10, backOut);
        const tilt = (random(`tilt-${i}`) - 0.5) * 22;
        const sx = -520 - i * 60;
        const sy = (random(`sy-${i}`) - 0.5) * 260;
        const rot = tilt * (1 - settle);

        const into = prog(frame, T.brand.morphStart + 2 + i * 1.5, 16, inOut);
        const bx = BIG.x + sx * (1 - travel);
        const by = BIG.y0 + i * BIG.step + sy * (1 - travel);
        const x = lerp(bx, SMALL_X, into);
        const y = lerp(by, SMALL.y0 + i * SMALL.step, into);
        const s = lerp(0.94 + 0.06 * settle, SMALL.scale, into);
        if (frame < start) return null;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              transform: `scale(${s}) rotate(${rot}deg)`,
              transformOrigin: '0 0',
              opacity: prog(frame, start, 5),
            }}
          >
            <RunRow i={i} />
          </div>
        );
      })}

      {/* Shared-cost invite: a cost arrives as an invitation, not a demand */}
      {frame >= T.phone.invite ? (
        <div
          style={{
            position: 'absolute',
            left: INVITE.x,
            top: INVITE.y,
            width: INVITE.w,
            height: INVITE.h,
            borderRadius: 26,
            background: c.surface,
            border: `1.5px solid ${tint(lunchPack.accent, 0.45)}`,
            boxShadow: cardShadow,
            boxSizing: 'border-box',
            opacity: inviteA,
            transform: `translateY(${(1 - invite) * 40}px) scale(${0.92 + 0.08 * invite})`,
          }}
        >
          <div style={{display: 'flex', alignItems: 'center', gap: 14, padding: '18px 20px 0'}}>
            <div
              style={{
                width: 54,
                height: 54,
                borderRadius: 16,
                background: tint(lunchPack.accent, 0.14),
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <BowlIcon size={32} color={lunchPack.accent} />
            </div>
            <div style={{flex: 1}}>
              <div style={{fontFamily: sans, fontWeight: 600, fontSize: 28, color: c.text}}>Extra salan</div>
              <div style={{fontFamily: mono, fontSize: 17, color: c.textTertiary}}>Rs 480 · shared by Bilal</div>
            </div>
          </div>
          <div
            style={{
              position: 'absolute',
              left: 20,
              top: 102,
              width: PHONE_JOIN.w,
              height: PHONE_JOIN.h,
              borderRadius: 16,
              background: lunchPack.primary,
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontFamily: sans,
              fontWeight: 600,
              fontSize: 26,
              transform: `scale(${1 - pressed * 0.04})`,
            }}
          >
            Join
          </div>
        </div>
      ) : null}

      {frame >= T.phone.cursorIn ? (
        <>
          <ClickRing
            x={PHONE_JOIN_CENTER.x + 14}
            y={PHONE_JOIN_CENTER.y + 4}
            t={prog(frame, T.phone.click, 12, expoOut)}
            color={tint(lunchPack.primary, 0.5)}
          />
          <Cursor x={cx - 8} y={cy - 4} press={press} opacity={prog(frame, T.phone.cursorIn, 6)} />
        </>
      ) : null}
    </AbsoluteFill>
  );
};

/** Camera push: whip into the Join button. Reads its own (trail-shifted) frame. */
const Pushed: React.FC = () => {
  const frame = useCurrentFrame();
  // Lands at full zoom on the last phone frame so the cut to the grid's own
  // full-zoom "Join" is a true match cut.
  const p = prog(frame, T.phone.zoomStart, T.split.pullStart - 1 - T.phone.zoomStart, (t) => t);
  const zs = Math.pow(PUSH_SCALE, expoIn(p));
  // Recentre in step with the zoom so the scaled layer always covers the frame.
  const k = (zs - 1) / (PUSH_SCALE - 1);
  const tx = (960 - PHONE_JOIN_CENTER.x) * k;
  const ty = (540 - PHONE_JOIN_CENTER.y) * k;
  return (
    <AbsoluteFill
      style={{
        transform: `translate(${tx}px, ${ty}px) scale(${zs})`,
        transformOrigin: `${PHONE_JOIN_CENTER.x}px ${PHONE_JOIN_CENTER.y}px`,
      }}
    >
      <Inner />
    </AbsoluteFill>
  );
};

export const SolutionScene: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{background: c.bg, overflow: 'hidden'}}>
      {frame >= T.phone.zoomStart ? (
        <Echo layers={3} lag={1} strength={0.34}>
          <Pushed />
        </Echo>
      ) : (
        <Pushed />
      )}
    </AbsoluteFill>
  );
};
