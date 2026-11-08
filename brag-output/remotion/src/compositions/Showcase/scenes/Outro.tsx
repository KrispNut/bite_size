import {Triangle} from '@remotion/shapes';
import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {AnimatedText} from '../../../components/AnimatedText';
import {Chip} from '../../../components/Chip';
import {useBeat} from '../../../lib/absolute-frame';
import {framesPerBeat} from '../../../lib/beat';
import {useLayout} from '../../../lib/layout';
import {SPRING, enter} from '../../../lib/motion';
import {withAlpha} from '../../../theme/colors';
import type {Palette} from '../../../theme/schemes';
import {gradientText, textStyle} from '../../../theme/typography';

const COMMANDS = ['npm run dev', 'npm run new -- MyVideo', 'npm run render:landscape'];

export const Outro: React.FC<{palette: Palette}> = ({palette}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const {unit, isPortrait} = useLayout();
  const {pulse} = useBeat(6);
  const beat = framesPerBeat(fps);

  const logo = enter(frame, fps, {config: SPRING.bouncy});
  const size = 180 * unit;
  const footer = enter(frame, fps, {delay: Math.round(beat * 3.5)});

  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', gap: 56 * unit}}>
      <div
        style={{
          width: size,
          height: size,
          borderRadius: size * 0.28,
          background: `linear-gradient(135deg, ${palette.accent}, ${palette.accent2})`,
          boxShadow: `0 ${24 * unit}px ${(70 + 40 * pulse) * unit}px ${withAlpha(palette.accent, 0.45)}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          transform: `scale(${logo}) rotate(${(1 - logo) * -45}deg)`,
        }}
      >
        <Triangle
          length={size * 0.42}
          direction="right"
          cornerRadius={size * 0.05}
          fill={palette.onAccent}
          style={{marginLeft: size * 0.06}}
        />
      </div>
      <AnimatedText
        text="Your turn."
        delay={Math.round(beat * 0.75)}
        stagger={Math.round(beat / 3)}
        highlight={['turn']}
        highlightStyle={gradientText(palette.accent, palette.accent2)}
        style={{...textStyle('display', unit), color: palette.text, textAlign: 'center'}}
      />
      <div
        style={{
          display: 'flex',
          flexDirection: isPortrait ? 'column' : 'row',
          alignItems: 'center',
          gap: 18 * unit,
        }}
      >
        {COMMANDS.map((cmd, i) => {
          const p = enter(frame, fps, {
            delay: Math.round(beat * (1.75 + i * 0.5)),
            config: SPRING.snappy,
          });
          return (
            <div key={cmd} style={{opacity: p, transform: `translateY(${(1 - p) * 30 * unit}px)`}}>
              <Chip palette={palette} prefix="$">
                {cmd}
              </Chip>
            </div>
          );
        })}
      </div>
      <div style={{...textStyle('label', unit), color: palette.muted, opacity: footer}}>
        remotion.dev/docs
      </div>
    </AbsoluteFill>
  );
};
