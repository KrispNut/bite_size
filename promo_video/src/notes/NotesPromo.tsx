// The notes cut: reference B's "client notes" typography for the problem
// (the group chat revising the lunch order, v1 → v8_final_FINAL), dropping
// into reference A's calm product console for the answer.
import React from 'react';
import {AbsoluteFill, Html5Audio, staticFile, useCurrentFrame} from 'remotion';
import {ChartScene, ConsoleBg, ConsoleHud, EndScene, FloodToCursor, GridScene, PromptScene, TileWipe, ToolkitScene} from './ConsolePart';
import {DIM} from './look';
import {NotesPart} from './NotesPart';
import T from './timeline_notes.json';

const hudColor = (f: number) => {
  const W = T.tools.words;
  // dark ink on the two light toolkit fields (SHARED MEALS, LIST LOCKS)
  if ((f >= W[0] && f < W[1]) || (f >= W[2] && f < W[3])) return 'rgba(24,24,27,0.55)';
  return DIM;
};

export const NotesPromo: React.FC = () => {
  const f = useCurrentFrame();
  const console_ = f >= T.prompt.morphStart;
  return (
    <AbsoluteFill style={{background: '#0B0F0D'}}>
      {f < T.prompt.morphStart ? <NotesPart /> : null}
      {console_ ? <ConsoleBg /> : null}
      {f >= T.prompt.morphStart && f < T.prompt.morphEnd + 2 ? <FloodToCursor /> : null}
      {f >= T.prompt.morphEnd && f < T.grid.start + 10 ? <PromptScene /> : null}
      {f >= T.grid.start && f < T.tools.words[0] ? <GridScene /> : null}
      {f >= T.tools.words[0] - 3 && f < T.tools.end + 4 ? <ToolkitScene /> : null}
      {f >= T.chart.start - 2 && f < T.tiles.full ? <ChartScene /> : null}
      {f >= T.end.start ? <EndScene /> : null}
      {f >= T.tiles.start && f < T.end.start + 26 ? <TileWipe /> : null}
      {console_ ? <ConsoleHud color={hudColor(f)} /> : null}
      <Html5Audio src={staticFile('audio/bite_size_notes_mix.wav')} />
    </AbsoluteFill>
  );
};
