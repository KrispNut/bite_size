import {Composition, Folder} from 'remotion';
import {Showcase} from './compositions/Showcase/Showcase';
import {showcaseSchema} from './compositions/Showcase/schema';
import {calculateVideoMetadata} from './config/video';
// @new-composition:imports (keep this line: `npm run new` adds imports above it)

/**
 * Every video is a <Composition>. Its size, frame rate and length come from the
 * `format`, `fps` and `durationInSeconds` props through calculateVideoMetadata, so you
 * change them right here, in the Studio's props panel, or with --props on the CLI.
 * Keep defaultProps as inline object literals: the Studio can only save edits back to
 * this file when they are.
 */
export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Folder name="Showcase">
        <Composition
          id="Showcase-Landscape"
          component={Showcase}
          schema={showcaseSchema}
          calculateMetadata={calculateVideoMetadata}
          defaultProps={{
            format: 'landscape',
            fps: 30,
            durationInSeconds: 16,
            title: 'Motion, written in code.',
            scheme: 'midnight',
            accent: 'hsl(252, 95%, 68%)',
            hud: true,
          }}
        />
        <Composition
          id="Showcase-Portrait"
          component={Showcase}
          schema={showcaseSchema}
          calculateMetadata={calculateVideoMetadata}
          defaultProps={{
            format: 'portrait',
            fps: 30,
            durationInSeconds: 16,
            title: 'Motion, written in code.',
            scheme: 'midnight',
            accent: 'hsl(252, 95%, 68%)',
            hud: true,
          }}
        />
      </Folder>
      {/* @new-composition:entries (keep this line: `npm run new` adds compositions above it) */}
    </>
  );
};
