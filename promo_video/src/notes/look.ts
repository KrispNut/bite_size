// Fonts and colours for the notes cut. Colours are the app's own: the lunch
// pack's derived roles from activity_packs.dart and AppColors' zinc night.
import {loadFont as loadAnton} from '@remotion/google-fonts/Anton';
import {loadFont as loadArchivoBlack} from '@remotion/google-fonts/ArchivoBlack';
import {loadFont as loadJakarta} from '@remotion/google-fonts/PlusJakartaSans';
import {loadFont as loadNewsreader} from '@remotion/google-fonts/Newsreader';

export {mono, sans, serif} from '../theme';

/** Condensed heavy grotesk — reference B's voice. */
export const anton = loadAnton('normal', {weights: ['400'], subsets: ['latin']}).fontFamily;
/** Wide heavy grotesk — reference A's toolkit words. */
export const archivo = loadArchivoBlack('normal', {weights: ['400'], subsets: ['latin']}).fontFamily;
/** Reference A's headline sans. */
export const jakarta = loadJakarta('normal', {weights: ['700', '800'], subsets: ['latin']}).fontFamily;
/** Reference B's quote serif. */
export const newsreader = loadNewsreader('italic', {weights: ['400'], subsets: ['latin']}).fontFamily;

// Part 1 (paper): the lunch pack's accentSoft, zinc ink, the copper seed.
export const PAPER = '#F7ECE3';
export const INK = '#18181B'; // AppColors navy900
export const NIGHT = '#18181B';
export const CREAM = '#F7ECE3';
export const GREY_INK = '#8C857D';
export const COPPER = '#B5652B'; // biteSizeAccent seed

// Part 2 (console): the app's dark-mode roles.
export const CONSOLE = '#0B0F0D';
export const ACCENT = '#2DA87F'; // lunch primaryDark — the brand on dark
export const COPPER_DARK = '#D69262'; // lunch accentDark
export const TEXT = '#ECE7DC';
export const DIM = 'rgba(236, 231, 220, 0.45)';
export const CARD_BG = '#121614';
export const LINE = 'rgba(236, 231, 220, 0.10)';

// Both packs' derived palettes (PackPalette.seeded), for the roster cards.
export const LUNCH = {primary: '#156047', deep: '#0F4533', soft: '#E9F3F0', fixed: '#4FC69F', accent: '#885027', fill: '#D0834A', accentSoft: '#F7ECE3'};
export const GROUND = {primary: '#2850A4', deep: '#1C3A75', soft: '#EFF1F6', fixed: '#9FB4DE', accent: '#775823', fill: '#BF8C34', accentSoft: '#F5ECDE'};
export const INFO = '#0E7490'; // AppColors info
