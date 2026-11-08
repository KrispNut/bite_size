// Copies the Flutter app's own artwork into public/app so the app-accurate
// cut renders the exact same marks, Lottie animations and launcher art.
import {copyFileSync, mkdirSync} from 'node:fs';
import {dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const promo = join(here, '..');
const app = join(promo, '..');
const out = join(promo, 'public', 'app');

const files = [
  ['assets/svg/roti.svg', 'svg/roti.svg'],
  ['assets/svg/plate.svg', 'svg/plate.svg'],
  ['assets/svg/runner.svg', 'svg/runner.svg'],
  ['assets/svg/salan.svg', 'svg/salan.svg'],
  ['assets/svg/team.svg', 'svg/team.svg'],
  ['assets/svg/tandoor.svg', 'svg/tandoor.svg'],
  ['assets/svg/sparkle.svg', 'svg/sparkle.svg'],
  ['assets/svg/sun.svg', 'svg/sun.svg'],
  ['assets/svg/moon.svg', 'svg/moon.svg'],
  ['assets/svg/receipt.svg', 'svg/receipt.svg'],
  ['assets/svg/splash_image.svg', 'svg/splash_image.svg'],
  ['assets/lottie/runner.json', 'lottie/runner.json'],
  ['assets/lottie/idle.json', 'lottie/idle.json'],
  ['assets/icon/logo.png', 'icon/logo.png'],
];

for (const [from, to] of files) {
  const dest = join(out, to);
  mkdirSync(dirname(dest), {recursive: true});
  copyFileSync(join(app, from), dest);
}

// Flutter's Icons.*_rounded glyphs are the Material Icons Round font.
const font = join(out, 'fonts', 'material-icons-round.woff2');
mkdirSync(dirname(font), {recursive: true});
copyFileSync(
  join(promo, 'node_modules/@fontsource/material-icons-round/files/material-icons-round-latin-400-normal.woff2'),
  font,
);

console.log(`synced ${files.length + 1} app assets into public/app`);
