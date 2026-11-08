import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {backOut, expoOut, inOut, lerp, prog, punch, T} from '../anim';
import {Accent, MonoLabel, Words} from '../components/Type';
import {
  BowlIcon,
  CheckBadge,
  ClockIcon,
  CricketBallIcon,
  LedgerIcon,
  RotiIcon,
  StumpsIcon,
} from '../components/Ui';
import {c, groundPack, lunchPack, mix, mono, Pack, palette, sans, tint, withAlpha} from '../theme';

const PANEL = {x: 1010, y: 182, w: 760, h: 716};
const TRACK = {x: 32, y: 32, w: 696, h: 92};
const KNOB_W = 342;
const KNOB_X0 = TRACK.x + 6;
const KNOB_X1 = TRACK.x + TRACK.w - 6 - KNOB_W;
// Where the new pack floods in from: the knob's resting point on the right.
const WIPE_ORIGIN = {x: KNOB_X1 + KNOB_W / 2, y: TRACK.y + TRACK.h / 2};

const lineIn = (frame: number, at: number): React.CSSProperties => {
  const p = prog(frame, at, 12, expoOut);
  return {opacity: prog(frame, at, 5), transform: `translateY(${(1 - p) * 18}px)`};
};

const Row: React.FC<{
  frame: number;
  at: number;
  icon: React.ReactNode;
  title: string;
  sub: string;
  right: React.ReactNode;
  last?: boolean;
}> = ({frame, at, icon, title, sub, right, last}) => (
  <div
    style={{
      height: 104,
      display: 'flex',
      alignItems: 'center',
      gap: 20,
      borderBottom: last ? undefined : `1.5px solid ${c.divider}`,
      ...lineIn(frame, at),
    }}
  >
    {icon}
    <div style={{flex: 1}}>
      <div style={{fontFamily: sans, fontWeight: 600, fontSize: 32, color: c.text}}>{title}</div>
      <div style={{fontFamily: mono, fontSize: 21, color: c.textSecondary, marginTop: 2}}>{sub}</div>
    </div>
    {right}
  </div>
);

const IconTile: React.FC<{pack: Pack; children: React.ReactNode}> = ({pack, children}) => (
  <div
    style={{
      width: 64,
      height: 64,
      borderRadius: 18,
      background: tint(pack.accent, 0.14),
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0,
    }}
  >
    {children}
  </div>
);

const Header: React.FC<{pack: Pack; sub: string; icon: React.ReactNode}> = ({pack, sub, icon}) => (
  <div
    style={{
      height: 196,
      borderRadius: 28,
      background: pack.primary,
      display: 'flex',
      alignItems: 'center',
      gap: 26,
      padding: '0 34px',
    }}
  >
    <div
      style={{
        width: 100,
        height: 100,
        borderRadius: 28,
        background: pack.accent,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}
    >
      {icon}
    </div>
    <div>
      <div style={{fontFamily: sans, fontWeight: 600, fontSize: 52, letterSpacing: '-0.03em', color: '#FFFFFF'}}>
        {pack.name}
      </div>
      <div style={{fontFamily: mono, fontSize: 22, color: 'rgba(255,255,255,0.75)', marginTop: 4}}>{sub}</div>
    </div>
  </div>
);

const money = (text: string, color: string, big = false) => (
  <div style={{fontFamily: mono, fontWeight: 600, fontSize: big ? 36 : 31, color, whiteSpace: 'nowrap'}}>{text}</div>
);

const LunchContent: React.FC<{frame: number}> = ({frame}) => {
  const p = lunchPack;
  return (
    <div style={{position: 'absolute', left: 32, right: 32, top: 152}}>
      <Header pack={p} sub="tandoor runs · shared dishes" icon={<RotiIcon size={58} color="#FFFFFF" stroke={2.4} />} />
      <div style={{padding: '14px 8px 0'}}>
        <Row
          frame={frame}
          at={T.packs.office[0]}
          icon={<IconTile pack={p}><RotiIcon size={38} color={p.accent} /></IconTile>}
          title="Tandoor run"
          sub="12 rotis × Rs 25"
          right={money('Rs 300', c.text)}
        />
        <Row
          frame={frame}
          at={T.packs.office[1]}
          icon={<IconTile pack={p}><BowlIcon size={38} color={p.accent} /></IconTile>}
          title="Extra salan"
          sub="Rs 480 ÷ 3 in"
          right={money('Rs 160 each', p.primary)}
        />
        <Row
          frame={frame}
          at={T.packs.office[2]}
          icon={<IconTile pack={p}><LedgerIcon size={36} color={p.accent} /></IconTile>}
          title="Month-end ledger"
          sub="net Rs 0"
          right={<CheckBadge size={46} bg={p.primary} pop={1} draw={1} style={{position: 'relative', boxShadow: 'none'}} />}
          last
        />
      </div>
    </div>
  );
};

const GroundContent: React.FC<{frame: number}> = ({frame}) => {
  const p = groundPack;
  const hours = ['4–5 pm', '5–6 pm', '6–7 pm'];
  return (
    <div style={{position: 'absolute', left: 32, right: 32, top: 152}}>
      <Header pack={p} sub="pitch bookings · by the hour" icon={<CricketBallIcon size={60} color="#FFFFFF" stroke={2.4} />} />
      <div style={{padding: '22px 8px 0'}}>
        <div style={{display: 'flex', gap: 14, ...lineIn(frame, T.packs.cricket[0] - 4)}}>
          {hours.map((h, i) => {
            const booked = i < 2;
            const fill = booked ? prog(frame, T.packs.cricket[i], 10, backOut) : 0;
            return (
              <div
                key={h}
                style={{
                  flex: 1,
                  height: 74,
                  borderRadius: 18,
                  border: booked ? `2px solid ${p.accent}` : `2px dashed ${c.border}`,
                  background: booked ? tint(p.accent, 0.16 * Math.min(1, fill)) : 'transparent',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 8,
                  fontFamily: mono,
                  fontWeight: booked ? 600 : 400,
                  fontSize: 23,
                  color: booked ? c.text : c.textTertiary,
                  transform: `scale(${booked ? 0.94 + 0.06 * fill : 1})`,
                }}
              >
                {h}
              </div>
            );
          })}
        </div>
        <div style={{height: 8}} />
        <Row
          frame={frame}
          at={T.packs.cricket[2]}
          icon={<IconTile pack={p}><ClockIcon size={38} color={p.accent} /></IconTile>}
          title="Pitch, 2 hrs"
          sub="Rs 3,000 per hour"
          right={money('Rs 6,000', c.text)}
        />
        <Row
          frame={frame}
          at={T.packs.cricket[3]}
          icon={<IconTile pack={p}><StumpsIcon size={38} color={p.accent} /></IconTile>}
          title="12 players in"
          sub="Rs 6,000 ÷ 12"
          right={money('Rs 500 each', p.primary, true)}
          last
        />
      </div>
    </div>
  );
};

export const PacksScene: React.FC = () => {
  const frame = useCurrentFrame();
  const sw = prog(frame, T.packs.toggle, 10, inOut);
  const knobX = lerp(KNOB_X0, KNOB_X1, sw);
  const wipe = prog(frame, T.packs.toggle + 2, T.packs.wipeEnd - T.packs.toggle - 2, inOut);
  const wipeR = wipe * 1150;
  const accent = mix(lunchPack.accent, groundPack.accent, sw);
  const primary = mix(lunchPack.primary, groundPack.primary, wipe);

  const panelIn = prog(frame, T.packs.card, 20, expoOut);
  const knobPunch = punch(frame, T.packs.toggle, 12, 0.06);
  const ring = prog(frame, T.packs.toggle + 2, 16, expoOut);

  return (
    <AbsoluteFill style={{background: c.darkBg}}>
      {/* Pack-coloured glow behind the panel */}
      <div
        style={{
          position: 'absolute',
          left: PANEL.x + PANEL.w / 2 - 800,
          top: PANEL.y + PANEL.h / 2 - 800,
          width: 1600,
          height: 1600,
          borderRadius: '50%',
          background: `radial-gradient(circle, ${withAlpha(primary, 0.85)} 0%, ${withAlpha(primary, 0.3)} 32%, rgba(0,0,0,0) 62%)`,
          opacity: panelIn,
        }}
      />

      <div style={{position: 'absolute', left: 150, top: 352}}>
        <MonoLabel at={T.packs.label + 2} text="// activity packs" color={c.darkTextSecondary} size={26} />
        <div
          style={{
            marginTop: 26,
            fontFamily: sans,
            fontWeight: 600,
            fontSize: 112,
            lineHeight: 1.06,
            letterSpacing: '-0.035em',
            color: c.darkText,
          }}
        >
          <div>
            <Words text="Same app." at={T.packs.headline[0]} />
          </div>
          <div style={{whiteSpace: 'nowrap'}}>
            <Words text="New" at={T.packs.headline[1]} />{' '}
            <Accent at={T.packs.headline[2]} color={accent}>
              pack.
            </Accent>
          </div>
        </div>
      </div>

      {/* The app panel */}
      <div
        style={{
          position: 'absolute',
          left: PANEL.x,
          top: PANEL.y,
          width: PANEL.w,
          height: PANEL.h,
          borderRadius: 42,
          background: c.surface,
          overflow: 'hidden',
          opacity: prog(frame, T.packs.card, 6),
          transform: `translateX(${(1 - panelIn) * 160}px) rotate(${(1 - panelIn) * 4}deg)`,
          boxShadow: `0 50px 120px -40px rgba(0,0,0,0.6)`,
        }}
      >
        <LunchContent frame={frame} />
        {frame >= T.packs.toggle ? (
          <div
            style={{
              position: 'absolute',
              inset: 0,
              background: c.surface,
              clipPath: `circle(${wipeR}px at ${WIPE_ORIGIN.x}px ${WIPE_ORIGIN.y}px)`,
            }}
          >
            <GroundContent frame={frame} />
          </div>
        ) : null}

        {/* Pack switcher */}
        <div
          style={{
            position: 'absolute',
            left: TRACK.x,
            top: TRACK.y,
            width: TRACK.w,
            height: TRACK.h,
            borderRadius: TRACK.h / 2,
            background: c.surfaceAlt,
          }}
        />
        {ring > 0 && ring < 1 ? (
          <div
            style={{
              position: 'absolute',
              left: WIPE_ORIGIN.x - 60 - ring * 200,
              top: WIPE_ORIGIN.y - 60 - ring * 200,
              width: 120 + ring * 400,
              height: 120 + ring * 400,
              borderRadius: '50%',
              border: `4px solid ${groundPack.accent}`,
              opacity: 1 - ring,
            }}
          />
        ) : null}
        <div
          style={{
            position: 'absolute',
            left: knobX,
            top: TRACK.y + 6,
            width: KNOB_W,
            height: TRACK.h - 12,
            borderRadius: (TRACK.h - 12) / 2,
            background: c.surface,
            boxShadow: `0 6px 18px -6px ${withAlpha(palette.shadowLight, 0.3)}`,
            transform: `scale(${1 + knobPunch})`,
          }}
        />
        {[
          {pack: lunchPack, icon: RotiIcon, active: 1 - sw},
          {pack: groundPack, icon: CricketBallIcon, active: sw},
        ].map(({pack, icon: Icon, active}, i) => (
          <div
            key={pack.id}
            style={{
              position: 'absolute',
              left: i === 0 ? KNOB_X0 : KNOB_X1,
              top: TRACK.y + 6,
              width: KNOB_W,
              height: TRACK.h - 12,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 12,
              fontFamily: sans,
              fontWeight: 600,
              fontSize: 27,
              color: mix(c.textTertiary, c.text, active),
            }}
          >
            <Icon size={30} color={mix(c.textTertiary, pack.accent, active)} stroke={2.6} />
            {pack.name}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};
