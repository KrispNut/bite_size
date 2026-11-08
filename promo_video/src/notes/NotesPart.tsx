// Part 1, after reference B: one word on the page, reshaped by every note
// the group chat sends, version by version — the lunch order as a client
// who never stops revising.
import React from 'react';
import {AbsoluteFill, random, useCurrentFrame} from 'remotion';
import {backOut, expoIn, expoOut, inOut, lerp, prog, quintOut} from '../anim';
import {anton, CREAM, GREY_INK, INK, newsreader, NIGHT, PAPER, COPPER, sans, serif, ACCENT} from './look';
import T from './timeline_notes.json';

const V = T.notes.versions;

// Each note: what the chat said, who said it, and the version it produced.
const NOTES = [
  {q: 'who’s in for lunch?', who: 'sara', v: 'v1'},
  {q: 'me! 3 rotis', who: 'ali', v: 'v2'},
  {q: '+4 for me. salan too?', who: 'bilal', v: 'v3'},
  {q: 'whole floor’s in. bigger.', who: 'hina', v: 'v4'},
  {q: 'wait… who’s paying?', who: 'sara', v: 'v5'},
  {q: 'hmm… who paid on friday??', who: 'bilal', v: 'v6'},
  {q: 'can someone just keep track?', who: 'ali', v: 'v7_final'},
  {q: 'ugh. is there an app for this?', who: 'hina', v: 'v8_final_FINAL'},
];

const versionAt = (f: number) => {
  let i = 0;
  for (let k = 0; k < V.length; k++) if (f >= V[k]) i = k;
  return i;
};

/** The quote, top left: the old one lifts away, the new one types in. */
const Quote: React.FC<{f: number; dark: boolean}> = ({f, dark}) => {
  const i = versionAt(f);
  const n = NOTES[i];
  const since = f - V[i];
  const shown = Math.min(n.q.length, Math.max(0, Math.floor(since * 2.2)));
  const color = dark ? CREAM : INK;
  const prevI = i - 1;
  const out = prevI >= 0 ? prog(f, V[i], 6, expoIn) : 1;
  return (
    <>
      {prevI >= 0 && out < 1 ? (
        <div style={{position: 'absolute', left: 46, top: 40, opacity: 1 - out, transform: `translateY(${-out * 18}px)`}}>
          <QuoteLine text={NOTES[prevI].q} who={NOTES[prevI].who} color={color} />
        </div>
      ) : null}
      <div style={{position: 'absolute', left: 46, top: 40, opacity: prog(f, V[i] + 2, 4)}}>
        <QuoteLine text={n.q.slice(0, shown)} who={shown >= n.q.length ? n.who : ''} color={color} />
      </div>
    </>
  );
};

const QuoteLine: React.FC<{text: string; who: string; color: string}> = ({text, who, color}) => (
  <div style={{fontFamily: newsreader, fontStyle: 'italic', fontSize: 34, color, whiteSpace: 'nowrap'}}>
    {'“'}
    {text}
    {'”'}
    {who ? (
      <span style={{fontFamily: sans, fontStyle: 'normal', fontSize: 20, opacity: 0.5, marginLeft: 14, letterSpacing: '0.04em'}}>
        {'—'} {who}
      </span>
    ) : null}
  </div>
);

const Version: React.FC<{f: number; dark: boolean}> = ({f, dark}) => (
  <div style={{position: 'absolute', left: 46, bottom: 38, fontFamily: sans, fontWeight: 600, fontSize: 24, color: dark ? CREAM : INK}}>
    {NOTES[versionAt(f)].v}
  </div>
);

const Center: React.FC<{children: React.ReactNode; style?: React.CSSProperties}> = ({children, style}) => (
  <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', ...style}}>{children}</AbsoluteFill>
);

/** Condensed heavy type, B's "OPUS 5.5" voice. */
const Heavy: React.FC<{text: string; size: number; color: string; style?: React.CSSProperties}> = ({text, size, color, style}) => (
  <div style={{fontFamily: anton, fontSize: size, color, lineHeight: 1, letterSpacing: '-0.01em', whiteSpace: 'nowrap', textTransform: 'uppercase', ...style}}>
    {text}
  </div>
);

// v7's dot, placed by hand so v8 can zoom into it exactly.
export const DOT = {x: 1181, y: 588, r: 13};

export const NotesPart: React.FC = () => {
  const f = useCurrentFrame();
  const [v1, v2, v3, v4, v5, v6, v7, v8] = V;

  // Background: paper, then the contrast wipe takes it to night.
  const panel = prog(f, v5 + 6, 20, inOut);
  const dark = f >= v5 + 16;

  // v8: the camera dives into v7's full stop until it is the whole frame.
  const zoom = Math.pow(90, inOut(prog(f, T.notes.zoomStart, T.notes.fill - T.notes.zoomStart, (t) => t)));
  const dotTint = prog(f, T.notes.zoomStart + 6, 12, inOut);

  return (
    <AbsoluteFill style={{background: PAPER}}>
      <div style={{position: 'absolute', left: 0, top: 0, bottom: 0, width: `${panel * 100}%`, background: NIGHT}} />

      <AbsoluteFill style={{transform: `scale(${zoom})`, transformOrigin: `${DOT.x}px ${DOT.y}px`}}>
        {/* v1 — the question, small and grey */}
        {f < v2 + 8 ? (
          <Center style={{opacity: prog(f, v1 + 2, 8) * (1 - prog(f, v2, 6))}}>
            <div style={{fontFamily: sans, fontSize: 60, color: GREY_INK, transform: `scale(${1 - 0.2 * prog(f, v2, 6)})`}}>Lunch?</div>
          </Center>
        ) : null}

        {/* v2 — "make it pop": a copper disc, the order letter by letter */}
        {f >= v2 && f < v3 + 10 ? (
          <Center>
            <div
              style={{
                position: 'absolute',
                width: 600,
                height: 600,
                borderRadius: '50%',
                background: COPPER,
                transform: `scale(${prog(f, v2, 14, backOut) * (1 - prog(f, v3, 10, inOut))})`,
              }}
            />
            <div style={{display: 'flex', opacity: 1 - prog(f, v3, 6)}}>
              {'3 ROTIS'.split('').map((ch, i) => {
                const p = prog(f, v2 + 3 + i * 1.5, 12, quintOut);
                const dx = (random(`lx${i}`) - 0.5) * 260;
                const dy = (random(`ly${i}`) - 0.5) * 200;
                return (
                  <span
                    key={i}
                    style={{
                      display: 'inline-block',
                      whiteSpace: 'pre',
                      opacity: prog(f, v2 + 3 + i * 1.5, 4),
                      transform: `translate(${(1 - p) * dx}px, ${(1 - p) * dy}px) scale(${0.35 + 0.65 * p})`,
                    }}
                  >
                    <Heavy text={ch === ' ' ? ' ' : ch} size={170} color={INK} />
                  </span>
                );
              })}
            </div>
          </Center>
        ) : null}

        {/* v3 — "now make it move": three marquee rows */}
        {f >= v3 && f < v4 + 12 ? (
          <AbsoluteFill style={{opacity: prog(f, v3 + 2, 8) * (1 - prog(f, v4, 10, inOut))}}>
            {[0, 1, 2].map((r) => {
              const dir = r === 1 ? 1 : -1;
              const x = dir * (f - v3) * 9 - 400;
              return (
                <div key={r} style={{position: 'absolute', top: 540 - 220 + r * 160, left: x, display: 'flex', gap: 60}}>
                  {[0, 1, 2, 3, 4, 5, 6, 7].map((k) => (
                    <Heavy key={k} text={r === 1 ? '+4 rotis' : 'salan?'} size={140} color={r === 1 ? INK : COPPER} />
                  ))}
                </div>
              );
            })}
          </AbsoluteFill>
        ) : null}

        {/* v4 — "bigger.": the order grows until it crops */}
        {f >= v4 && f < v6 + 6 ? (
          <TwoTone
            panel={panel}
            text="12 rotis"
            scale={lerp(lerp(0.85, 3.4, prog(f, v4 + 4, 24, inOut)), 1, prog(f, v5, 14, inOut))}
            opacity={prog(f, v4 + 2, 6) * (1 - prog(f, v6, 6))}
          />
        ) : null}

        {/* v6 — "let it breathe": the question, letter-spaced out */}
        {f >= v6 && f < v7 + 10 ? (
          <Center style={{opacity: prog(f, v6 + 2, 6) * (1 - prog(f, v7, 10))}}>
            {(() => {
              const b = prog(f, v6 + 2, 26, inOut);
              return <Heavy text="who paid?" size={lerp(150, 104, b)} color={CREAM} style={{letterSpacing: `${lerp(0, 0.5, b)}em`, marginRight: `-${lerp(0, 0.5, b)}em`}} />;
            })()}
          </Center>
        ) : null}

        {/* v7 — "premium": an italic serif with hairlines */}
        {f >= v7 ? (
          <AbsoluteFill style={{opacity: prog(f, v7 + 2, 10), filter: `blur(${(1 - prog(f, v7 + 2, 12, expoOut)) * 10}px)`}}>
            <div style={{position: 'absolute', right: 1920 - DOT.x + DOT.r + 6, top: DOT.y - 150, fontFamily: serif, fontStyle: 'italic', fontSize: 190, color: CREAM, lineHeight: 1}}>
              Lunch
            </div>
            <div
              style={{
                position: 'absolute',
                left: DOT.x - DOT.r,
                top: DOT.y - DOT.r,
                width: DOT.r * 2,
                height: DOT.r * 2,
                borderRadius: '50%',
                background: dotTint > 0 ? mixHex(CREAM, ACCENT, dotTint) : CREAM,
              }}
            />
            {[-1, 1].map((s) => (
              <div
                key={s}
                style={{
                  position: 'absolute',
                  left: 960 - 230 * prog(f, v7 + 6, 14, expoOut) - 7,
                  width: 460 * prog(f, v7 + 6, 14, expoOut),
                  top: s < 0 ? DOT.y - 196 : DOT.y + 52,
                  height: 1.5,
                  background: 'rgba(236,231,220,0.45)',
                }}
              />
            ))}
            <div
              style={{
                position: 'absolute',
                left: 0,
                right: 14,
                top: DOT.y + 76,
                textAlign: 'center',
                fontFamily: sans,
                fontSize: 20,
                letterSpacing: '0.5em',
                color: 'rgba(236,231,220,0.55)',
                opacity: prog(f, v7 + 12, 10),
              }}
            >
              {'TODAY · 12:40'}
            </div>
          </AbsoluteFill>
        ) : null}
      </AbsoluteFill>

      <Quote f={f} dark={dark} />
      <Version f={f} dark={dark} />
      {/* v8 floods the frame with the brand's dark-mode green */}
      {f >= T.notes.fill - 2 ? <AbsoluteFill style={{background: ACCENT, opacity: prog(f, T.notes.fill - 2, 2)}} /> : null}
    </AbsoluteFill>
  );
};

/** Ink on paper, grey on night, split exactly at the wipe's edge on screen. */
const TwoTone: React.FC<{panel: number; text: string; scale: number; opacity: number}> = ({panel, text, scale, opacity}) => (
  <AbsoluteFill style={{opacity}}>
    {[
      {color: INK, clip: `inset(0 0 0 ${panel * 100}%)`},
      {color: '#A9AFA9', clip: `inset(0 ${(1 - panel) * 100}% 0 0)`},
    ].map((l) => (
      <AbsoluteFill key={l.color} style={{clipPath: l.clip, alignItems: 'center', justifyContent: 'center'}}>
        <div style={{transform: `scale(${scale})`, transformOrigin: '42% 55%'}}>
          <Heavy text={text} size={170} color={l.color} />
        </div>
      </AbsoluteFill>
    ))}
  </AbsoluteFill>
);

const mixHex = (a: string, b: string, t: number) => {
  const pa = [1, 3, 5].map((i) => parseInt(a.slice(i, i + 2), 16));
  const pb = [1, 3, 5].map((i) => parseInt(b.slice(i, i + 2), 16));
  return `rgb(${pa.map((v, i) => Math.round(v + (pb[i] - v) * t)).join(',')})`;
};
