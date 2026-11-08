import React from 'react';
import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {backOut, expoOut, prog, T} from '../anim';
import {Accent, MonoLabel, Words} from '../components/Type';
import {c, groundPack, lunchPack, Pack, sans} from '../theme';
import {Wordmark} from './SolutionScene';

const PackChip: React.FC<{pack: Pack; at: number}> = ({pack, at}) => {
  const frame = useCurrentFrame();
  const p = prog(frame, at, 14, backOut);
  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 16,
        padding: '16px 30px 16px 20px',
        borderRadius: 999,
        background: c.surface,
        border: `1.5px solid ${c.border}`,
        fontFamily: sans,
        fontWeight: 600,
        fontSize: 30,
        color: c.text,
        opacity: prog(frame, at, 5),
        transform: `translateY(${(1 - p) * 26}px) scale(${0.9 + 0.1 * p})`,
      }}
    >
      {/* The pack's two seeds, side by side */}
      <span style={{display: 'inline-flex'}}>
        <span style={{width: 30, height: 30, borderRadius: 30, background: pack.primary}} />
        <span style={{width: 30, height: 30, borderRadius: 30, background: pack.accent, marginLeft: -10, boxShadow: `0 0 0 3px ${c.surface}`}} />
      </span>
      {pack.name}
    </div>
  );
};

export const EndScene: React.FC = () => {
  const frame = useCurrentFrame();
  const settle = prog(frame, T.end.letters, 40, expoOut);
  return (
    <AbsoluteFill style={{background: c.bg, alignItems: 'center', justifyContent: 'center'}}>
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          transform: `translateY(${(1 - settle) * 20}px)`,
        }}
      >
        <Wordmark at={T.end.letters} color={c.text} size={200} />
        <div
          style={{
            marginTop: 34,
            fontFamily: sans,
            fontWeight: 500,
            fontSize: 56,
            letterSpacing: '-0.025em',
            color: c.textSecondary,
            whiteSpace: 'nowrap',
          }}
        >
          <Words text="Fair splits." at={T.end.tagline} stagger={3} />{' '}
          <Accent at={T.end.tagline + 6} color={lunchPack.primary} sizeEm={1.2}>
            no arguments.
          </Accent>
        </div>
        <div style={{display: 'flex', gap: 22, marginTop: 64}}>
          <PackChip pack={lunchPack} at={T.end.chips[0]} />
          <PackChip pack={groundPack} at={T.end.chips[1]} />
        </div>
        <MonoLabel
          at={T.end.mono}
          text="// who's in · who's fetching · what's owed"
          color={c.textTertiary}
          size={24}
          style={{marginTop: 46}}
        />
      </div>
    </AbsoluteFill>
  );
};
