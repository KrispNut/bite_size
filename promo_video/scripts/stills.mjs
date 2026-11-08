// Renders a handful of stills from one bundle, for reviewing frames fast.
// usage: node scripts/stills.mjs <compositionId> <outDir> <frame> [frame...]
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import {mkdirSync} from 'node:fs';
import {join, resolve} from 'node:path';

const [id, outDir, ...frames] = process.argv.slice(2);
const browserExecutable = process.env.REMOTION_BROWSER || 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';

mkdirSync(outDir, {recursive: true});
const serveUrl = await bundle({entryPoint: resolve('src/index.ts')});
const composition = await selectComposition({serveUrl, id, browserExecutable, chromeMode: 'chrome-for-testing'});
for (const f of frames.map(Number)) {
  const output = join(outDir, `${id}_${String(f).padStart(3, '0')}.png`);
  await renderStill({composition, serveUrl, frame: f, output, browserExecutable, chromeMode: 'chrome-for-testing'});
  console.log('rendered', output);
}
