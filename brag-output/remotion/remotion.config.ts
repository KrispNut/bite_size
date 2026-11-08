// Studio and CLI settings. Every option is also a CLI flag: https://www.remotion.dev/docs/config
// The Node.js render APIs ignore this file. Pass options to them directly.
import {Config} from '@remotion/cli/config';

Config.setEntryPoint('./src/index.ts');
Config.setRspack(true);

// GPU rendering through ANGLE: about twice as fast as Chrome's default on this machine.
// If frames come out black or glitchy on another machine, delete this line.
Config.setChromiumOpenGlRenderer('angle');

// Output: H.264 MP4 in yuv420p, so it plays everywhere (QuickTime, browsers, socials).
Config.setCodec('h264');
Config.setPixelFormat('yuv420p');
Config.setCrf(18);
Config.setColorSpace('bt709'); // tags and converts to the HD standard, so players don't guess
Config.setVideoImageFormat('jpeg');
Config.setJpegQuality(95); // gradients band at the default quality of 80
Config.setOverwriteOutput(true);
