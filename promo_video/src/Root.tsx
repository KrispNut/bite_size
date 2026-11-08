import React from 'react';
import {Composition} from 'remotion';
import {BiteSizePromo} from './BiteSizePromo';
import {AppPromo} from './app/AppPromo';
import {RefPromo} from './ref/RefPromo';
import {NotesPromo} from './notes/NotesPromo';
import T from './timeline.json';
import TA from './app/timeline_app.json';
import TR from './ref/timeline_ref.json';
import TN from './notes/timeline_notes.json';

export const Root: React.FC = () => (
  <>
    <Composition
      id="BiteSizePromo"
      component={BiteSizePromo}
      durationInFrames={T.durationInFrames}
      fps={T.fps}
      width={T.width}
      height={T.height}
    />
    {/* Same story, every phone frame rebuilt from the Flutter app's own widgets. */}
    <Composition
      id="BiteSizeApp"
      component={AppPromo}
      durationInFrames={TA.durationInFrames}
      fps={TA.fps}
      width={TA.width}
      height={TA.height}
    />
    {/* The reference film, shot for shot, in its 1-bit dithered art style. */}
    <Composition
      id="BiteSizeRef"
      component={RefPromo}
      durationInFrames={TR.durationInFrames}
      fps={TR.fps}
      width={TR.width}
      height={TR.height}
    />
    {/* Both new references: B's client-notes typography, A's product console. */}
    <Composition
      id="BiteSizeNotes"
      component={NotesPromo}
      durationInFrames={TN.durationInFrames}
      fps={TN.fps}
      width={TN.width}
      height={TN.height}
    />
  </>
);
