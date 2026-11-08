import {createContext, useContext} from 'react';
import {useCurrentFrame, useVideoConfig} from 'remotion';
import {BEATS_PER_BAR} from '../config/audio';
import {beatPulse, frameToBeat} from './beat';

/**
 * Inside a <Sequence>, useCurrentFrame() counts from the start of that Sequence. Music
 * runs on the composition's clock, so anything that pulses with it reads the absolute
 * frame from here. Wrap the composition in <AbsoluteFrameProvider> once.
 */
const AbsoluteFrameContext = createContext<number | null>(null);

export const AbsoluteFrameProvider: React.FC<{children: React.ReactNode}> = ({children}) => {
  const frame = useCurrentFrame();
  return <AbsoluteFrameContext.Provider value={frame}>{children}</AbsoluteFrameContext.Provider>;
};

export const useAbsoluteFrame = () => {
  const local = useCurrentFrame();
  return useContext(AbsoluteFrameContext) ?? local;
};

/** Where the music is right now: beat count, position in the bar and a decaying pulse. */
export const useBeat = (decay = 5) => {
  const frame = useAbsoluteFrame();
  const {fps} = useVideoConfig();
  const beat = frameToBeat(frame, fps);
  return {
    frame,
    beat,
    beatInBar: Math.floor(beat) % BEATS_PER_BAR,
    pulse: beatPulse(frame, fps, decay),
  };
};
