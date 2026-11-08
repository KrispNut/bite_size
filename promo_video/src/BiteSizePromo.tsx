import React from 'react';
import {AbsoluteFill, Html5Audio, staticFile, useCurrentFrame} from 'remotion';
import {inOut, prog, T} from './anim';
import {Hud} from './components/Hud';
import {HalftoneIris} from './components/Transitions';
import {ChatScene} from './scenes/ChatScene';
import {EndScene} from './scenes/EndScene';
import {PacksScene} from './scenes/PacksScene';
import {SolutionScene} from './scenes/SolutionScene';
import {SplitScene} from './scenes/SplitScene';
import {c} from './theme';

const DARK_IRIS = {x: 960, y: 600, end: 1460};
const LIGHT_IRIS = {x: 1390, y: 540, end: 1840};

export const BiteSizePromo: React.FC = () => {
  const frame = useCurrentFrame();
  const dark = prog(frame, T.packs.irisStart, T.packs.irisFull - T.packs.irisStart, inOut);
  const light = prog(frame, T.end.irisStart, T.end.irisFull - T.end.irisStart, inOut);

  return (
    <AbsoluteFill style={{background: c.bg}}>
      {/* Beat 1: the problem and the fix */}
      {frame < T.chat.wipeFull ? <ChatScene /> : null}
      {frame >= T.chat.wipeFull && frame < T.split.pullStart ? <SolutionScene /> : null}
      {/* Beat 2: the split */}
      {frame >= T.split.pullStart && frame < T.packs.irisFull ? <SplitScene /> : null}
      {/* Beat 3: activity packs, then the sign-off */}
      {frame >= T.packs.irisFull && frame < T.end.irisFull ? <PacksScene /> : null}
      {frame >= T.end.irisFull ? <EndScene /> : null}

      {frame >= T.packs.irisStart && frame < T.packs.irisFull ? (
        <HalftoneIris x={DARK_IRIS.x} y={DARK_IRIS.y} radius={dark * DARK_IRIS.end} color={c.darkBg} />
      ) : null}
      {frame >= T.end.irisStart && frame < T.end.irisFull ? (
        <HalftoneIris x={LIGHT_IRIS.x} y={LIGHT_IRIS.y} radius={light * LIGHT_IRIS.end} color={c.bg} feather={330} />
      ) : null}

      <Hud />
      <Html5Audio src={staticFile('audio/bite_size_mix.wav')} />
    </AbsoluteFill>
  );
};
