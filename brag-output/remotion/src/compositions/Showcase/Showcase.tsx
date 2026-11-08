import {TransitionSeries, springTiming} from '@remotion/transitions';
import {iris} from '@remotion/transitions/iris';
import {pushCut} from '@remotion/transitions/push-cut';
import {slide} from '@remotion/transitions/slide';
import {wipe} from '@remotion/transitions/wipe';
import {useMemo} from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {Background} from '../../components/Background';
import {Hud} from '../../components/Hud';
import {AbsoluteFrameProvider} from '../../lib/absolute-frame';
import {type Palette, makePalette} from '../../theme/schemes';
import {fonts} from '../../theme/typography';
import type {ShowcaseProps} from './schema';
import {Colors} from './scenes/Colors';
import {Intro} from './scenes/Intro';
import {Outro} from './scenes/Outro';
import {Rhythm} from './scenes/Rhythm';
import {Shapes} from './scenes/Shapes';
import {Soundtrack} from './Soundtrack';
import {makeTimeline} from './timeline';

/** Each scene gets its own opaque background, so transitions read cleanly. */
const Scene: React.FC<{palette: Palette; tint: number; children: React.ReactNode}> = ({
  palette,
  tint,
  children,
}) => (
  <AbsoluteFill>
    <Background palette={palette} tint={tint} />
    {children}
  </AbsoluteFill>
);

export const Showcase: React.FC<ShowcaseProps> = ({title, scheme, accent, hud}) => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames, width, height} = useVideoConfig();
  const palette = useMemo(() => makePalette(scheme, accent), [scheme, accent]);
  const timeline = useMemo(() => makeTimeline(fps, durationInFrames), [fps, durationInFrames]);
  const {scenes} = timeline;

  const timing = springTiming({
    config: {damping: 200},
    durationInFrames: timeline.transitionFrames,
  });
  const fadeOut = interpolate(frame, [durationInFrames - fps * 0.6, durationInFrames - 1], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFrameProvider>
      <AbsoluteFill
        style={{backgroundColor: palette.background, color: palette.text, fontFamily: fonts.sans}}
      >
        <AbsoluteFill style={{opacity: fadeOut}}>
          <TransitionSeries>
            <TransitionSeries.Sequence
              name="Intro"
              durationInFrames={scenes.intro.durationInFrames}
            >
              <Scene palette={palette} tint={0}>
                <Intro palette={palette} title={title} totalFrames={durationInFrames} />
              </Scene>
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={slide({direction: 'from-right'})}
              timing={timing}
            />
            <TransitionSeries.Sequence
              name="Shapes"
              durationInFrames={scenes.shapes.durationInFrames}
              premountFor={fps}
            >
              <Scene palette={palette} tint={1}>
                <Shapes palette={palette} />
              </Scene>
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={wipe({direction: 'from-left'})}
              timing={timing}
            />
            <TransitionSeries.Sequence
              name="Colors"
              durationInFrames={scenes.colors.durationInFrames}
              premountFor={fps}
            >
              <Scene palette={palette} tint={2}>
                <Colors palette={palette} />
              </Scene>
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition presentation={iris({width, height})} timing={timing} />
            <TransitionSeries.Sequence
              name="Rhythm"
              durationInFrames={scenes.rhythm.durationInFrames}
              premountFor={fps}
            >
              <Scene palette={palette} tint={0}>
                <Rhythm palette={palette} />
              </Scene>
            </TransitionSeries.Sequence>
            <TransitionSeries.Transition
              presentation={pushCut({flashColor: palette.text, flashOpacity: 0.18})}
              timing={timing}
            />
            <TransitionSeries.Sequence
              name="Outro"
              durationInFrames={scenes.outro.durationInFrames}
              premountFor={fps}
            >
              <Scene palette={palette} tint={1}>
                <Outro palette={palette} />
              </Scene>
            </TransitionSeries.Sequence>
          </TransitionSeries>
          {hud ? <Hud palette={palette} /> : null}
        </AbsoluteFill>
        <Soundtrack timeline={timeline} />
      </AbsoluteFill>
    </AbsoluteFrameProvider>
  );
};
