import React from 'react';
import {AbsoluteFill, random, useCurrentFrame} from 'remotion';
import {backOut, expoOut, inOut, lerp, prog, punch, T} from '../anim';
import {Accent, MonoLabel, Words} from '../components/Type';
import {Avatar, Card} from '../components/Ui';
import {CircleWipe} from '../components/Transitions';
import {c, lunchPack, mono, palette, sans, tint} from '../theme';

const people: Record<string, {initial: string; color: string}> = {
  Sara: {initial: 'S', color: tint(lunchPack.primary, 0.16)},
  Ali: {initial: 'A', color: tint(lunchPack.accent, 0.2)},
  Bilal: {initial: 'B', color: tint(palette.info, 0.16)},
  You: {initial: 'H', color: tint(palette.grey600, 0.14)},
};

// The problem, in the group's own words: counts drift, payments get lost.
const messages: {who: keyof typeof people; text: string}[] = [
  {who: 'Sara', text: "who's in for roti?"},
  {who: 'Ali', text: 'me, 3'},
  {who: 'Bilal', text: '4 for me. salan too?'},
  {who: 'You', text: '2? no wait, 3'},
  {who: 'Sara', text: 'who paid on Friday??'},
  {who: 'Bilal', text: 'I sent 400 to someone'},
  {who: 'Ali', text: 'recount pls'},
  {who: 'You', text: 'how much do I owe?'},
];

const unread = [12, 17, 23, 28, 31, 36, 41, 47];

const CARD = {x: 1050, y: 110, w: 720, h: 860};
const STEP = 118;

const Bubble: React.FC<{i: number; frame: number}> = ({i, frame}) => {
  const at = T.chat.bubbles[i];
  const m = messages[i];
  const mine = m.who === 'You';
  const p = prog(frame, at, 12, backOut);
  const appear = prog(frame, at, 5, expoOut);
  // Mess builds as the thread grows: tilt and drift, then a jittery pile-up.
  const mess = prog(frame, T.chat.bubbles[3], 40, inOut);
  const rot = (random(`rot-${i}`) - 0.5) * 9 * mess;
  const dx = (random(`dx-${i}`) - 0.5) * 70 * mess;
  const jitter =
    frame > T.chat.shake ? (random(`j-${i}-${frame}`) - 0.5) * 5 * prog(frame, T.chat.shake, 20) : 0;

  return (
    <div
      style={{
        position: 'absolute',
        left: mine ? undefined : 34 + dx,
        right: mine ? 34 - dx : undefined,
        top: i * STEP,
        display: 'flex',
        flexDirection: mine ? 'row-reverse' : 'row',
        alignItems: 'flex-end',
        gap: 14,
        opacity: appear,
        transform: `translate(${jitter}px, ${(1 - p) * 40 + jitter}px) scale(${0.7 + 0.3 * p}) rotate(${rot}deg)`,
        transformOrigin: mine ? '100% 100%' : '0% 100%',
      }}
    >
      {mine ? null : <Avatar initial={people[m.who].initial} bg={people[m.who].color} size={48} />}
      <div
        style={{
          background: mine ? tint(lunchPack.primary, 0.12) : c.surfaceAlt,
          borderRadius: 26,
          borderBottomLeftRadius: mine ? 26 : 8,
          borderBottomRightRadius: mine ? 8 : 26,
          padding: '14px 24px 16px',
          maxWidth: 520,
        }}
      >
        {mine ? null : (
          <div style={{fontFamily: mono, fontSize: 19, color: c.textTertiary, marginBottom: 4}}>
            {m.who.toLowerCase()}
          </div>
        )}
        <div style={{fontFamily: sans, fontSize: 32, fontWeight: 500, color: c.text, whiteSpace: 'nowrap'}}>
          {m.text}
        </div>
      </div>
    </div>
  );
};

export const ChatScene: React.FC<{accent?: string; wipeColor?: string}> = ({accent = lunchPack.primary, wipeColor = lunchPack.primary}) => {
  const frame = useCurrentFrame();
  const enter = prog(frame, 0, 22, expoOut);

  // Thread scrolls as new messages arrive, keeping the newest at the bottom.
  let shown = 0;
  for (let i = 0; i < T.chat.bubbles.length; i++) {
    shown += prog(frame, T.chat.bubbles[i], 12, expoOut);
  }
  const visibleSlots = 5.3;
  const scroll = Math.max(0, shown - visibleSlots) * STEP;

  const countIdx = T.chat.bubbles.filter((b) => frame >= b).length - 1;
  const badge = countIdx >= 0 ? unread[countIdx] : 9;
  const lastBubble = T.chat.bubbles[Math.max(0, countIdx)];
  const badgePunch = punch(frame, lastBubble, 10, 0.18);

  const shake =
    frame > T.chat.shake
      ? (random(`shake-${frame}`) - 0.5) * 6 * prog(frame, T.chat.shake, 24)
      : 0;

  // "?" dot → emerald circle wipe.
  const dotPop = punch(frame, T.chat.qdot, 12, 0.6);
  const wipe = prog(frame, T.chat.wipeStart, T.chat.wipeFull - T.chat.wipeStart, inOut);
  const dotR = 9 * (1 + dotPop) + lerp(0, 2400, wipe);
  const dotVisible = frame >= T.chat.qdot;

  return (
    <AbsoluteFill style={{background: c.bg}}>
      {/* Chat window */}
      <Card
        style={{
          left: CARD.x,
          top: CARD.y,
          width: CARD.w,
          height: CARD.h,
          transform: `translate(${(1 - enter) * 120 + shake}px, ${shake * 0.6}px) rotate(${(1 - enter) * 4}deg)`,
          opacity: enter,
        }}
      >
        <div
          style={{
            height: 112,
            borderBottom: `1.5px solid ${c.divider}`,
            display: 'flex',
            alignItems: 'center',
            padding: '0 34px',
            gap: 18,
          }}
        >
          <div style={{display: 'flex'}}>
            {(['Sara', 'Ali', 'Bilal'] as const).map((k, i) => (
              <Avatar
                key={k}
                initial={people[k].initial}
                bg={people[k].color}
                size={50}
                ring={c.surface}
                style={{marginLeft: i === 0 ? 0 : -16}}
              />
            ))}
          </div>
          <div style={{flex: 1}}>
            <div style={{fontFamily: sans, fontWeight: 600, fontSize: 34, color: c.text}}>Lunch group</div>
            <div style={{fontFamily: mono, fontSize: 20, color: c.textTertiary}}>14 members</div>
          </div>
          <div
            style={{
              minWidth: 74,
              height: 52,
              borderRadius: 26,
              background: palette.danger,
              color: '#FFFFFF',
              fontFamily: mono,
              fontWeight: 600,
              fontSize: 26,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              padding: '0 16px',
              transform: `scale(${1 + badgePunch})`,
            }}
          >
            {badge}
          </div>
        </div>
        <div style={{position: 'absolute', top: 112, left: 0, right: 0, bottom: 96, overflow: 'hidden'}}>
          <div style={{position: 'absolute', left: 0, right: 0, top: 34 - scroll}}>
            {messages.map((_, i) => (frame >= T.chat.bubbles[i] ? <Bubble key={i} i={i} frame={frame} /> : null))}
          </div>
        </div>
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            height: 96,
            borderTop: `1.5px solid ${c.divider}`,
            display: 'flex',
            alignItems: 'center',
            padding: '0 34px',
            fontFamily: mono,
            fontSize: 22,
            color: c.textTertiary,
            gap: 10,
          }}
        >
          <span>3 people typing</span>
          {[0, 1, 2].map((d) => (
            <span
              key={d}
              style={{
                width: 9,
                height: 9,
                borderRadius: 9,
                background: c.textTertiary,
                opacity: 0.35 + 0.65 * Math.max(0, Math.sin((frame - d * 4) / 4)),
              }}
            />
          ))}
        </div>
      </Card>

      {/* Statement */}
      <div style={{position: 'absolute', left: 150, top: 330, zIndex: 5}}>
        <MonoLabel at={T.chat.label} text="// lunch at the office, 12:40" color={c.textTertiary} size={26} />
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
            <Words text="Splitting costs" at={T.chat.line1} />
          </div>
          <div style={{whiteSpace: 'nowrap'}}>
            <Words text="in a group" at={T.chat.line2} />{' '}
            <span style={{position: 'relative', display: 'inline-block'}}>
              <Accent at={T.chat.accent} color={accent} underline={false}>
                chat?
              </Accent>
              {dotVisible ? (
                <div style={{position: 'absolute', left: DOT.x, top: DOT.y, width: 0, height: 0}}>
                  <CircleWipe x={0} y={0} r={dotR} color={wipeColor} />
                </div>
              ) : null}
            </span>
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// Position of the question mark's dot inside the accent word's box (px at
// 112px headline size), tuned against a rendered still.
export const DOT = {x: 223, y: 100};
