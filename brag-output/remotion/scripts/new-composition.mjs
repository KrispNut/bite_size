// Scaffolds a new composition and registers it in src/Root.tsx.
//
//   npm run new -- <Name> [--portrait | --square] [--fps 60] [--seconds 10]
//
//   npm run new -- ProductTeaser
//   npm run new -- StoryAd --portrait --seconds 15
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const value = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] !== undefined ? Number(args[i + 1]) : fallback;
};
const valueFlags = new Set(['--fps', '--seconds']);
const name = args.find((a, i) => !a.startsWith('--') && !valueFlags.has(args[i - 1]));

const fail = (msg) => {
  console.error(`✗ ${msg}`);
  console.error('usage: npm run new -- <Name> [--portrait | --square] [--fps 60] [--seconds 10]');
  process.exit(1);
};

if (!name) fail('Give the composition a name.');
if (!/^[A-Z][A-Za-z0-9]*$/.test(name)) fail(`"${name}" must be PascalCase letters and digits, e.g. ProductTeaser.`);

const format = flag('portrait') ? 'portrait' : flag('square') ? 'square' : 'landscape';
const fps = value('fps', 30);
const seconds = value('seconds', 8);
if (!Number.isInteger(fps) || fps < 1 || fps > 120) fail('--fps must be a whole number from 1 to 120.');
if (!(seconds >= 5 && seconds <= 600)) fail('--seconds must be between 5 and 600.');

const rootFile = path.join(root, 'src', 'Root.tsx');
const dir = path.join(root, 'src', 'compositions', name);
const file = path.join(dir, `${name}.tsx`);
let rootSrc = fs.readFileSync(rootFile, 'utf8');

if (fs.existsSync(dir)) fail(`src/compositions/${name} already exists.`);
if (rootSrc.includes(`id="${name}"`)) fail(`A composition with id "${name}" is already registered.`);

const IMPORTS = '// @new-composition:imports';
const ENTRIES = '{/* @new-composition:entries';
if (!rootSrc.includes(IMPORTS) || !rootSrc.includes(ENTRIES)) {
  fail('Root.tsx is missing the @new-composition marker comments. Add the composition by hand.');
}

const title = `${name.replace(/([a-z0-9])([A-Z])/g, '$1 $2')}.`;
const template = fs.readFileSync(path.join(root, 'scripts', 'templates', 'Composition.tsx.txt'), 'utf8');
const source = template.replaceAll('__NAME__', name);

const insertBeforeLine = (src, marker, text) => {
  const at = src.lastIndexOf('\n', src.indexOf(marker)) + 1;
  return src.slice(0, at) + text + src.slice(at);
};
rootSrc = insertBeforeLine(
  rootSrc,
  IMPORTS,
  `import {${name}, ${name}Schema} from './compositions/${name}/${name}';\n`,
);
rootSrc = insertBeforeLine(
  rootSrc,
  ENTRIES,
  [
    '      <Composition',
    `        id="${name}"`,
    `        component={${name}}`,
    `        schema={${name}Schema}`,
    '        calculateMetadata={calculateVideoMetadata}',
    '        defaultProps={{',
    `          format: '${format}',`,
    `          fps: ${fps},`,
    `          durationInSeconds: ${seconds},`,
    `          title: '${title}',`,
    "          scheme: 'midnight',",
    "          accent: 'hsl(252, 95%, 68%)',",
    '        }}',
    '      />',
    '',
  ].join('\n'),
);

fs.mkdirSync(dir, {recursive: true});
fs.writeFileSync(file, source);
fs.writeFileSync(rootFile, rootSrc);

console.log(`✓ created src/compositions/${name}/${name}.tsx (${format}, ${fps} fps, ${seconds}s)`);
console.log('✓ registered it in src/Root.tsx');
console.log('');
console.log(`  preview:  npm run dev            (pick "${name}" in the sidebar)`);
console.log(`  render:   npm run render -- ${name} out/${name}.mp4`);
