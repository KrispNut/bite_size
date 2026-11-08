import {Audio} from '@remotion/media';
import {Sequence, interpolate, useVideoConfig} from 'remotion';
import {AUDIO, SFX_SECONDS, WHOOSH_PEAK_SECONDS} from '../../config/audio';
import type {Timeline} from './timeline';

/**
 * Music plus sound effects, all cued from the same timeline as the visuals.
 * Each effect sits in its own <Sequence>, so its audio starts at that Sequence's frame.
 */
export const Soundtrack: React.FC<{timeline: Timeline}> = ({timeline}) => {
  const {fps, durationInFrames} = useVideoConfig();
  const whooshLead = Math.round(WHOOSH_PEAK_SECONDS * fps);

  // "extend" keeps this curve on the composition clock while the 8s loop repeats underneath.
  const musicVolume = (f: number) =>
    interpolate(
      f,
      [0, fps * 0.25, durationInFrames - fps * 1.4, durationInFrames - 1],
      [0, 0.6, 0.6, 0],
      {
        extrapolateLeft: 'clamp',
        extrapolateRight: 'clamp',
      },
    );

  const hits = [0, timeline.scenes.outro.from];

  return (
    <>
      <Audio src={AUDIO.music} loop loopVolumeCurveBehavior="extend" volume={musicVolume} />
      {timeline.cuts.map((cut) => (
        <Sequence
          key={`whoosh-${cut}`}
          name="Whoosh"
          from={Math.max(0, cut - whooshLead + Math.round(timeline.transitionFrames / 2))}
          durationInFrames={Math.ceil(SFX_SECONDS.whoosh * fps)}
          layout="none"
        >
          <Audio src={AUDIO.whoosh} volume={0.4} />
        </Sequence>
      ))}
      {hits.map((at) => (
        <Sequence
          key={`hit-${at}`}
          name="Hit"
          from={at}
          durationInFrames={Math.ceil(SFX_SECONDS.hit * fps)}
          layout="none"
        >
          <Audio src={AUDIO.hit} volume={0.45} />
        </Sequence>
      ))}
    </>
  );
};
