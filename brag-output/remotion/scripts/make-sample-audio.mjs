// Synthesizes the sample soundtrack into public/audio, with no samples or downloads:
//   music-loop.wav  four bars in A minor at --bpm (default 120). Loops seamlessly, first downbeat at 0s.
//   whoosh.wav      0.9s transition sweep that peaks at 0.32s (WHOOSH_PEAK_SECONDS in src/config/audio.ts)
//   hit.wav         2.4s impact with a chord and a long tail
//
//   npm run audio                 or   node scripts/make-sample-audio.mjs --bpm 128
//
// Keep BPM in src/config/audio.ts in sync with the value used here.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const SR = 48000;
const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? Number(process.argv[i + 1]) : fallback;
};
const BPM = arg('bpm', 120);
const BEAT = 60 / BPM;
const BAR = BEAT * 4;
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'public', 'audio');

// ---------- primitives ----------
let seed = 0x2f6b9a1;
const rand = () => {
  // mulberry32: same noise on every run, so the files are reproducible.
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const noise = () => rand() * 2 - 1;
const mtof = (m) => 440 * 2 ** ((m - 69) / 12);
const samples = (s) => Math.max(1, Math.round(s * SR));

const biquad = (type, freq, q = 0.707) => {
  let b0, b1, b2, a1, a2;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  const set = (f) => {
    const w = (2 * Math.PI * Math.min(f, SR * 0.45)) / SR;
    const c = Math.cos(w);
    const al = Math.sin(w) / (2 * q);
    const a0 = 1 + al;
    const [B0, B1, B2] =
      type === 'lp' ? [(1 - c) / 2, 1 - c, (1 - c) / 2] : type === 'hp' ? [(1 + c) / 2, -(1 + c), (1 + c) / 2] : [al, 0, -al];
    b0 = B0 / a0; b1 = B1 / a0; b2 = B2 / a0; a1 = (-2 * c) / a0; a2 = (1 - al) / a0;
  };
  set(freq);
  const run = (x) => {
    const y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1; x1 = x; y2 = y1; y1 = y;
    return y;
  };
  run.set = set;
  return run;
};

// Naive saw is fine at these pitches once it goes through a low-pass.
const saw = (phase) => 2 * (phase - Math.floor(phase + 0.5));

// ---------- instruments (mono Float32Arrays) ----------
const kick = () => {
  const out = new Float32Array(samples(0.5));
  let ph = 0;
  for (let i = 0; i < out.length; i++) {
    const t = i / SR;
    ph += (44 + 120 * Math.exp(-t * 38)) / SR;
    out[i] = Math.sin(2 * Math.PI * ph) * Math.exp(-t * 6.5) + (t < 0.004 ? noise() * 0.35 * (1 - t / 0.004) : 0);
  }
  return out;
};

const clap = () => {
  const out = new Float32Array(samples(0.4));
  const bp = biquad('bp', 1500, 0.9);
  for (let i = 0; i < out.length; i++) {
    const t = i / SR;
    const burst = [0, 0.011, 0.022].reduce((a, s) => a + (t >= s ? Math.exp(-(t - s) * 140) : 0), 0);
    const env = 0.6 * burst + Math.exp(-t * 16);
    out[i] = bp(noise()) * env * 1.6 + Math.sin(2 * Math.PI * 190 * t) * Math.exp(-t * 35) * 0.25;
  }
  return out;
};

const hat = (open = false) => {
  const out = new Float32Array(samples(open ? 0.35 : 0.08));
  const hp = biquad('hp', 7800, 0.8);
  for (let i = 0; i < out.length; i++) out[i] = hp(noise()) * Math.exp(-(i / SR) * (open ? 11 : 55));
  return out;
};

const bass = (midi, dur) => {
  const out = new Float32Array(samples(dur + 0.05));
  const lp = biquad('lp', 520, 0.9);
  const f = mtof(midi);
  for (let i = 0; i < out.length; i++) {
    const t = i / SR;
    const env = Math.min(1, t / 0.004) * (t < dur ? 1 : Math.exp(-(t - dur) * 60)) * (0.75 + 0.25 * Math.exp(-t * 9));
    out[i] = (lp(saw(f * t) * 0.7) + Math.sin(2 * Math.PI * f * t) * 0.6) * env;
  }
  return out;
};

const pluck = (midi) => {
  const out = new Float32Array(samples(0.6));
  const lp = biquad('lp', 4000, 1.1);
  const f = mtof(midi);
  for (let i = 0; i < out.length; i++) {
    const t = i / SR;
    lp.set(500 + 4200 * Math.exp(-t * 14));
    out[i] = lp(saw(f * t) + saw(f * 1.006 * t) * 0.6) * Math.exp(-t * 7) * Math.min(1, t / 0.002);
  }
  return out;
};

const pad = (midis, dur) => {
  const out = new Float32Array(samples(dur + 0.6));
  const lp = biquad('lp', 1500, 0.6);
  for (let i = 0; i < out.length; i++) {
    const t = i / SR;
    let v = 0;
    for (const m of midis) for (const d of [-0.11, 0, 0.12]) v += saw(mtof(m + d) * t + d);
    const env = Math.min(1, t / 0.35) * (t < dur ? 1 : Math.exp(-(t - dur) * 7));
    out[i] = lp(v / (midis.length * 3)) * env;
  }
  return out;
};

// ---------- mixing ----------
const makeBus = (seconds) => ({L: new Float32Array(samples(seconds)), R: new Float32Array(samples(seconds)), send: new Float32Array(samples(seconds))});
const add = (bus, t, sig, {gain = 1, pan = 0, send = 0} = {}) => {
  const start = Math.round(t * SR);
  const gl = gain * Math.cos(((pan + 1) * Math.PI) / 4) * Math.SQRT2;
  const gr = gain * Math.sin(((pan + 1) * Math.PI) / 4) * Math.SQRT2;
  for (let i = 0; i < sig.length; i++) {
    const j = start + i;
    if (j < 0 || j >= bus.L.length) continue;
    bus.L[j] += sig[i] * gl;
    bus.R[j] += sig[i] * gr;
    bus.send[j] += sig[i] * gain * send;
  }
};

// Freeverb-style room: parallel damped combs into series all-passes, offset per channel.
const reverb = (input, {room = 0.84, damp = 0.35} = {}) => {
  const scale = SR / 44100;
  const run = (spread) => {
    const out = new Float32Array(input.length);
    for (const n of [1557, 1617, 1491, 1422, 1277, 1356, 1188, 1116]) {
      const size = Math.round((n + spread) * scale);
      const buf = new Float32Array(size);
      let idx = 0, filt = 0;
      for (let i = 0; i < input.length; i++) {
        const y = buf[idx];
        filt = y * (1 - damp) + filt * damp;
        buf[idx] = input[i] * 0.015 + filt * room;
        out[i] += y;
        idx = (idx + 1) % size;
      }
    }
    for (const n of [556, 441, 341, 225]) {
      const size = Math.round((n + spread) * scale);
      const buf = new Float32Array(size);
      let idx = 0;
      for (let i = 0; i < out.length; i++) {
        const b = buf[idx];
        const y = -out[i] + b;
        buf[idx] = out[i] + b * 0.5;
        out[i] = y;
        idx = (idx + 1) % size;
      }
    }
    return out;
  };
  return {L: run(0), R: run(23)};
};

const master = (bus, {wet = 0.3, drive = 1.15, peak = 0.89} = {}) => {
  const rv = reverb(bus.send);
  const L = bus.L.map((v, i) => v + rv.L[i] * wet);
  const R = bus.R.map((v, i) => v + rv.R[i] * wet);
  const sat = (v) => Math.tanh(v * drive);
  let max = 1e-9;
  for (let i = 0; i < L.length; i++) {
    L[i] = sat(L[i]);
    R[i] = sat(R[i]);
    max = Math.max(max, Math.abs(L[i]), Math.abs(R[i]));
  }
  for (let i = 0; i < L.length; i++) {
    L[i] *= peak / max;
    R[i] *= peak / max;
  }
  return {L, R};
};

const writeWav = (file, {L, R}) => {
  const n = L.length;
  const b = Buffer.alloc(44 + n * 4);
  b.write('RIFF', 0); b.writeUInt32LE(36 + n * 4, 4); b.write('WAVE', 8);
  b.write('fmt ', 12); b.writeUInt32LE(16, 16); b.writeUInt16LE(1, 20); b.writeUInt16LE(2, 22);
  b.writeUInt32LE(SR, 24); b.writeUInt32LE(SR * 4, 28); b.writeUInt16LE(4, 32); b.writeUInt16LE(16, 34);
  b.write('data', 36); b.writeUInt32LE(n * 4, 40);
  for (let i = 0; i < n; i++) {
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, L[i])) * 32767), 44 + i * 4);
    b.writeInt16LE(Math.round(Math.max(-1, Math.min(1, R[i])) * 32767), 46 + i * 4);
  }
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, b);
  console.log(`wrote ${path.relative(process.cwd(), file)}  (${(n / SR).toFixed(2)}s)`);
};

// ---------- music loop: Am – F – C – G, one chord per bar ----------
const CHORDS = [
  {root: 45, notes: [57, 60, 64]},
  {root: 41, notes: [57, 60, 65]},
  {root: 36, notes: [55, 60, 64]},
  {root: 43, notes: [55, 59, 62]},
];
const LOOP = BAR * CHORDS.length;

const renderMusic = () => {
  // Render the loop twice and keep the second pass: the reverb and pad tails from the
  // first pass spill into it, exactly as they will when the player wraps around.
  const drums = makeBus(LOOP * 2);
  const music = makeBus(LOOP * 2);
  const K = kick(), C = clap(), H = hat(), HO = hat(true);
  for (let pass = 0; pass < 2; pass++) {
    CHORDS.forEach((chord, bar) => {
      const t0 = pass * LOOP + bar * BAR;
      for (let s = 0; s < 16; s++) {
        const t = t0 + (s * BEAT) / 4;
        if (s % 4 === 0) add(drums, t, K, {gain: 0.95});
        if (s === 4 || s === 12) add(drums, t, C, {gain: 0.42, send: 0.25});
        if (s % 4 === 2) add(drums, t, s === 14 && bar === 3 ? HO : H, {gain: 0.2, pan: 0.25});
        else if (s % 2 === 1) add(drums, t, H, {gain: 0.07, pan: -0.2});
        if (s % 2 === 0) {
          const step = s / 2;
          const off = [0, 0, 12, 0, 0, 12, 7, 0][step];
          add(music, t, bass(chord.root + off - 12, BEAT / 2 - 0.02), {gain: 0.32});
        }
        const arp = [0, 1, 2, 1, 2, 0, 1, 2, 0, 1, 2, 1, 2, 0, 2, 1][s];
        const octave = s >= 8 && bar % 2 === 1 ? 12 : 0;
        add(music, t, pluck(chord.notes[arp] + 12 + octave), {gain: 0.075, pan: s % 2 ? 0.45 : -0.45, send: 0.35});
      }
      add(music, t0, pad(chord.notes.map((m) => m - 12), BAR - 0.05), {gain: 0.3, send: 0.4});
    });
  }
  // Side-chain: duck the music under every kick so the beat punches through.
  for (let i = 0; i < music.L.length; i++) {
    const sinceKick = (i / SR) % BEAT;
    const duck = 1 - 0.55 * Math.exp(-sinceKick * 9);
    music.L[i] *= duck;
    music.R[i] *= duck;
  }
  const bus = makeBus(LOOP * 2);
  for (const k of ['L', 'R', 'send']) for (let i = 0; i < bus[k].length; i++) bus[k][i] = drums[k][i] + music[k][i];
  const mixed = master(bus, {wet: 0.32});
  const start = samples(LOOP);
  return {L: mixed.L.slice(start, start * 2), R: mixed.R.slice(start, start * 2)};
};

const renderWhoosh = () => {
  const len = 0.9, peak = 0.32;
  const bus = makeBus(len + 0.6);
  const bp = biquad('bp', 400, 1.3);
  const sig = new Float32Array(samples(len));
  for (let i = 0; i < sig.length; i++) {
    const t = i / SR;
    const rise = t < peak ? (t / peak) ** 2 : Math.exp(-(t - peak) * 6);
    bp.set(t < peak ? 300 * (3500 / 300) ** (t / peak) : 3500 * Math.exp(-(t - peak) * 3.2));
    sig[i] = bp(noise()) * rise * 2.4;
  }
  // Pan the sweep from left to right across the cut.
  const half = Math.floor(sig.length / 2);
  add(bus, 0, sig.slice(0, half), {gain: 1, pan: -0.5, send: 0.3});
  add(bus, half / SR, sig.slice(half), {gain: 1, pan: 0.5, send: 0.3});
  return master(bus, {wet: 0.35, drive: 1});
};

const renderHit = () => {
  const len = 2.4;
  const bus = makeBus(len);
  const boom = new Float32Array(samples(1.6));
  const lp = biquad('lp', 2200, 0.7);
  let ph = 0;
  for (let i = 0; i < boom.length; i++) {
    const t = i / SR;
    ph += (40 + 90 * Math.exp(-t * 16)) / SR;
    boom[i] = Math.sin(2 * Math.PI * ph) * Math.exp(-t * 2.4) + lp(noise()) * Math.exp(-t * 22) * 0.5;
  }
  add(bus, 0, boom, {gain: 0.9, send: 0.25});
  for (const [k, m] of [57, 64, 69, 72, 76].entries()) {
    add(bus, 0.004 * k, pluck(m), {gain: 0.16, pan: (k - 2) * 0.25, send: 0.7});
  }
  return master(bus, {wet: 0.55, drive: 1.1});
};

writeWav(path.join(OUT, 'music-loop.wav'), renderMusic());
writeWav(path.join(OUT, 'whoosh.wav'), renderWhoosh());
writeWav(path.join(OUT, 'hit.wav'), renderHit());
console.log(`${BPM} BPM · loop ${(LOOP).toFixed(2)}s · beat ${(BEAT * 1000).toFixed(0)}ms`);
