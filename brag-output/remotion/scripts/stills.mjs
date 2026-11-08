// Renders a few frames as PNGs for a quick visual check, bundling only once.
//   npm run stills -- <composition-id> <frame> [frame …] [--props '{"scheme":"paper"}']
//   e.g. npm run stills -- Showcase-Portrait 60 150 240
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const propsAt = args.indexOf('--props');
const inputProps = propsAt >= 0 ? JSON.parse(args.splice(propsAt, 2)[1]) : {};
const [id, ...frames] = args;
if (!id || frames.length === 0) {
  console.error('usage: npm run stills -- <composition-id> <frame> [frame …] [--props <json>]');
  process.exit(1);
}

const serveUrl = await bundle({entryPoint: path.join(root, 'src', 'index.ts'), rspack: true});
const composition = await selectComposition({serveUrl, id, inputProps});
const outDir = path.join(root, 'out', 'stills');
fs.mkdirSync(outDir, {recursive: true});
for (const f of frames.map(Number)) {
  const output = path.join(outDir, `${id}-${String(f).padStart(4, '0')}.png`);
  await renderStill({serveUrl, composition, frame: f, output, inputProps, overwrite: true, chromiumOptions: {gl: 'angle'}});
  console.log(path.relative(root, output));
}
