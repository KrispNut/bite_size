import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {VERSION} from 'remotion/version';
import {AnimatedText} from '../../../components/AnimatedText';
import {Chip, Kicker} from '../../../components/Chip';
import {useBeat} from '../../../lib/absolute-frame';
import {framesPerBeat} from '../../../lib/beat';
import {useLayout} from '../../../lib/layout';
import {EASE, enter, tween} from '../../../lib/motion';
import type {Palette} from '../../../theme/schemes';
import {gradientText, textStyle} from '../../../theme/typography';

type Props = {palette: Palette; title: string; totalFrames: number};

export const Intro: React.FC<Props> = ({palette, title, totalFrames}) => {
  const frame = useCurrentFrame();
  const {fps, width, height} = useVideoConfig();
  const {unit, safe, isPortrait} = useLayout();
  const {pulse} = useBeat();
  const beat = framesPerBeat(fps);

  const kicker = enter(frame, fps, {durationInFrames: Math.round(beat * 2)});
  const rule = tween(frame, [beat * 1.5, beat * 3], [0, 1], EASE.inOut);
  const words = title.trim().split(/\s+/);
  const seconds = totalFrames / fps;
  const specs = [
    `${width} × ${height}`,
    `${fps} fps`,
    `${Number.isInteger(seconds) ? seconds : seconds.toFixed(1)} s`,
    'H.264 · MP4',
  ];

  return (
    <AbsoluteFill style={{padding: safe, justifyContent: 'center'}}>
      <div style={{display: 'flex', flexDirection: 'column', gap: 48 * unit}}>
        <Kicker palette={palette} progress={kicker} pulse={pulse}>
          Remotion {VERSION}
        </Kicker>
        <AnimatedText
          text={title}
          delay={Math.round(beat * 0.5)}
          stagger={Math.round(beat / 3)}
          highlight={[words[words.length - 1]]}
          highlightStyle={gradientText(palette.accent, palette.accent2)}
          style={{
            ...textStyle('display', unit, isPortrait ? {fontSize: 136 * unit} : {}),
            color: palette.text,
            maxWidth: isPortrait ? undefined : 1500 * unit,
          }}
        />
        <div
          style={{
            width: 380 * unit * rule,
            height: 6 * unit,
            borderRadius: 99,
            background: `linear-gradient(to right, ${palette.accent}, ${palette.accent2})`,
          }}
        />
        <div style={{display: 'flex', flexWrap: 'wrap', gap: 14 * unit}}>
          {specs.map((label, i) => {
            const p = enter(frame, fps, {delay: Math.round(beat * (2 + i * 0.5))});
            return (
              <div
                key={label}
                style={{opacity: p, transform: `translateY(${(1 - p) * 20 * unit}px)`}}
              >
                <Chip palette={palette}>{label}</Chip>
              </div>
            );
          })}
        </div>
      </div>
    </AbsoluteFill>
  );
};
