# Motion Studio

Programmatic motion graphics with [Remotion](https://www.remotion.dev/docs) **4.0.536**, React 19 and TypeScript.
Videos are React components, so you preview them live in the Studio and export them to MP4 from the command line.

The sample composition, **Showcase**, comes in 1920×1080 and 1080×1920 at 30fps and runs 16 seconds.
It has animated type, morphing shapes, an RGB/HSL color demo, an audio-reactive spectrum
locked to a 120 BPM soundtrack, and five transitions that each land on a beat.

## Quick start

```bash
npm install          # once, if node_modules is missing
npm run dev          # opens Remotion Studio at http://localhost:3000
```

## Commands

```bash
npm run dev                                   # Studio: preview, scrub, edit props live
npm run new -- MyVideo                        # new 1920×1080 composition, registered in src/Root.tsx
npm run new -- MyStory --portrait --seconds 15 --fps 60
npm run render -- MyVideo out/MyVideo.mp4     # export any composition to MP4
npm run render:landscape                      # out/showcase-landscape.mp4
npm run render:portrait                       # out/showcase-portrait.mp4
npm run stills -- Showcase-Landscape 0 120 240   # PNG frames in out/stills/
npm run lint                                  # ESLint and TypeScript
npm run audio                                 # regenerate the sample WAVs in public/audio
```

Change resolution, fps or duration for one render:

```bash
npm run render -- Showcase-Landscape out/showcase-60fps.mp4 --props='{"fps":60,"durationInSeconds":20}'
```

Inline JSON works in Git Bash, macOS and Linux shells. In PowerShell or cmd, put the JSON in a file and pass the path instead: `--props=props.json`.

## Where things live

- **Resolution, fps and duration:** each composition's `defaultProps` in `src/Root.tsx`. Or edit
  them live in the Studio's props panel and click Save. Add new resolutions in `src/config/video.ts`.
- **Colors (RGB and HSL):** `src/theme/colors.ts` holds the helpers and `src/theme/schemes.ts` the schemes.
- **Fonts and type scale:** `src/theme/typography.ts`. The fonts are in `public/fonts`.
- **Tempo and audio files:** `src/config/audio.ts`. The audio is in `public/audio`.
- **Sample composition:** `src/compositions/Showcase/`.
- **Conventions for writing new videos:** [CLAUDE.md](CLAUDE.md).

## Requirements

- Node.js 20.19+, 22.13+ or 24+ (installed: 24.19.0).
- Rendering uses Chrome Headless Shell, already downloaded to `node_modules/.remotion`. Run
  `npx remotion browser ensure` if it's ever missing. Remotion bundles its own FFmpeg.

Remotion is free for individuals and companies of up to 3 people. Larger companies need a
[company license](https://www.remotion.dev/license). The bundled fonts, Inter and JetBrains Mono, are OFL.
