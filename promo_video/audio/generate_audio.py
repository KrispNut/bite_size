#!/usr/bin/env python3
"""Bite Size promo: original score and sound design, synthesised from scratch.

Standard library only (math, random, wave, array, json): no samples, no
packages. Every cue is read from ../src/timeline.json, the same file the
Remotion scenes animate from, so a sound lands on the exact frame its visual
does. Writes public/audio/bite_size_mix.wav (48 kHz, 16-bit stereo, exactly
20.000 s) and audio/cue_sheet.json for review.

Run:  uv run --no-project python audio/generate_audio.py
"""
import array
import json
import math
import os
import random
import sys
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
# Optional: <timeline.json> <out.wav> <cue_sheet.json>, relative to the project.
ARGS = sys.argv[1:]
TIMELINE = ARGS[0] if len(ARGS) > 0 else os.path.join("src", "timeline.json")
OUT_WAV = ARGS[1] if len(ARGS) > 1 else os.path.join("public", "audio", "bite_size_mix.wav")
OUT_CUES = ARGS[2] if len(ARGS) > 2 else os.path.join("audio", "cue_sheet.json")
with open(os.path.join(ROOT, TIMELINE), encoding="utf-8") as fh:
    T = json.load(fh)

SR = 48000
FPS = T["fps"]
N = T["durationInFrames"] * SR // FPS  # 960000 samples = 20.000 s
DUR = N / SR
BEAT = 60.0 / T["bpm"]  # 0.5 s
TAU = 2 * math.pi
sin = math.sin
exp = math.exp
rng = random.Random(7)


def sec(frame):
    return frame / FPS


def note(name):
    """'D4' / 'F#5' / 'Bb3' -> Hz (A4 = 440)."""
    names = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    pc = names[name[0]]
    rest = name[1:]
    if rest[0] == "#":
        pc += 1
        rest = rest[1:]
    elif rest[0] == "b":
        pc -= 1
        rest = rest[1:]
    midi = 12 * (int(rest) + 1) + pc
    return 440.0 * 2 ** ((midi - 69) / 12)


def buf():
    return array.array("d", bytes(8 * N))


MUS = (buf(), buf())
SFX = (buf(), buf())
SEND = buf()  # mono reverb send
CUES = []


def mix(bus, t0, mono, gain=1.0, pan=0.0, send=0.0, label=None):
    """Place a mono clip on a stereo bus with constant-power pan."""
    i0 = int(round(t0 * SR))
    a = (pan + 1) * math.pi / 4
    gl, gr = gain * math.cos(a), gain * math.sin(a)
    L, R = bus
    lo, hi = max(0, i0), min(N, i0 + len(mono))
    for k in range(lo, hi):
        v = mono[k - i0]
        L[k] += v * gl
        R[k] += v * gr
    if send:
        g = gain * send
        for k in range(lo, hi):
            SEND[k] += mono[k - i0] * g
    if label:
        CUES.append({"t": round(t0, 3), "frame": round(t0 * FPS, 1), "sfx": label})


# --- primitives ----------------------------------------------------------------

def noise(n):
    r = rng.random
    return [r() * 2 - 1 for _ in range(n)]


def onepole_lp(x, fc):
    a = exp(-TAU * fc / SR)
    y, out = 0.0, [0.0] * len(x)
    for i, v in enumerate(x):
        y = (1 - a) * v + a * y
        out[i] = y
    return out


def onepole_hp(x, fc):
    lp = onepole_lp(x, fc)
    return [v - l for v, l in zip(x, lp)]


def svf(x, fc_fn, q=0.8, mode="bp"):
    """Chamberlin state-variable filter with a time-varying cutoff."""
    low = band = 0.0
    damp = 1.0 / q
    out = [0.0] * len(x)
    for i, v in enumerate(x):
        f = 2 * sin(math.pi * min(fc_fn(i / SR), SR / 7) / SR)
        low += f * band
        high = v - low - damp * band
        band += f * high
        out[i] = band if mode == "bp" else (low if mode == "lp" else high)
    return out


def mallet(freq, dur=0.6, tau=0.28, partials=((1, 1.0, 1.0), (2.0, 0.22, 0.45), (3.98, 0.12, 0.22)), attack=0.002):
    """Soft marimba/kalimba-like tone: a few decaying partials."""
    n = int(dur * SR)
    out = [0.0] * n
    for ratio, amp, ts in partials:
        w = TAU * freq * ratio / SR
        td = tau * ts
        for i in range(n):
            t = i / SR
            out[i] += amp * min(1.0, t / attack) * exp(-t / td) * sin(w * i)
    return out


def bell(freq, dur=2.0, tau=1.0):
    """Inharmonic bell for tonal accents."""
    return mallet(
        freq,
        dur,
        tau,
        partials=((1, 1.0, 1.0), (2.0, 0.45, 0.6), (2.76, 0.3, 0.42), (5.4, 0.12, 0.2), (8.93, 0.05, 0.1)),
        attack=0.003,
    )


def blip(f0, f1, dur=0.09, tau=0.045):
    """Pitch-dropping sine: chat bubbles, pops."""
    n = int(dur * SR)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f0 - f1) * exp(-t / 0.018)
        ph += TAU * f / SR
        out[i] = min(1.0, t / 0.0015) * exp(-t / tau) * (sin(ph) + 0.18 * sin(2 * ph))
    return out


def click(bright=1.0):
    n = int(0.03 * SR)
    nz = onepole_hp(noise(n), 2500)
    out = [0.0] * n
    w = TAU * 2300 * bright / SR
    for i in range(n):
        t = i / SR
        out[i] = 0.55 * nz[i] * exp(-t / 0.0025) + 0.6 * sin(w * i) * exp(-t / 0.006)
    return out


def tick(freq=1900, gain=1.0):
    """Woody tick for rows and counters."""
    n = int(0.05 * SR)
    w = TAU * freq / SR
    return [gain * exp(-(i / SR) / 0.011) * (sin(w * i) + 0.3 * sin(2.7 * w * i)) for i in range(n)]


def thump(f0=130, f1=55, tau=0.11, dur=0.35):
    n = int(dur * SR)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f0 - f1) * exp(-t / 0.03)
        ph += TAU * f / SR
        out[i] = min(1.0, t / 0.002) * exp(-t / tau) * sin(ph)
    return out


def impact(weight=1.0):
    """Low boom + transient + air, for wipes, the push and the stamp."""
    dur = 1.4
    n = int(dur * SR)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = 40 + 70 * exp(-t / 0.06)
        ph += TAU * f / SR
        out[i] = min(1.0, t / 0.003) * exp(-t / (0.42 * weight)) * sin(ph)
    nz = onepole_lp(noise(int(0.25 * SR)), 1400)
    for i, v in enumerate(nz):
        out[i] += 0.5 * v * exp(-(i / SR) / 0.035)
    return out


def whoosh(dur, f_start, f_end, peak=0.75, q=1.4):
    """Band-passed noise swept between two cutoffs, swelling to `peak`."""
    n = int(dur * SR)
    x = noise(n)
    ratio = f_end / f_start
    y = svf(x, lambda t: f_start * ratio ** min(1.0, t / dur), q=q)
    out = [0.0] * n
    for i in range(n):
        u = i / n
        env = (u / peak) ** 2 if u < peak else max(0.0, 1 - (u - peak) / (1 - peak)) ** 1.6
        out[i] = y[i] * env
    m = max(1e-9, max(abs(v) for v in out))
    return [v / m for v in out]


def swish(dur=0.16):
    return whoosh(dur, 1200, 5200, peak=0.55, q=1.1)


def panned_whoosh(t0, dur, f0, f1, gain, pan0, pan1, label):
    w = whoosh(dur, f0, f1)
    i0 = int(round(t0 * SR))
    L, R = SFX
    for k, v in enumerate(w):
        idx = i0 + k
        if 0 <= idx < N:
            p = pan0 + (pan1 - pan0) * k / len(w)
            a = (p + 1) * math.pi / 4
            L[idx] += v * gain * math.cos(a)
            R[idx] += v * gain * math.sin(a)
            SEND[idx] += v * gain * 0.25
    CUES.append({"t": round(t0, 3), "frame": round(t0 * FPS, 1), "sfx": label})


def lock_sound():
    n = int(0.4 * SR)
    out = [0.0] * n
    for off, f in ((0.0, 3400), (0.065, 2600)):
        i0 = int(off * SR)
        nz = svf(noise(int(0.03 * SR)), lambda t, f=f: f, q=3)
        for i, v in enumerate(nz):
            out[i0 + i] += 1.4 * v * exp(-(i / SR) / 0.006)
        w = TAU * 1380 / SR
        for i in range(int(0.12 * SR)):
            out[i0 + i] += 0.25 * sin(w * i) * exp(-(i / SR) / 0.03)
    th = thump(150, 60, 0.09)
    for i, v in enumerate(th):
        if i + int(0.065 * SR) < n:
            out[i + int(0.065 * SR)] += 0.9 * v
    return out


def stamp_sound():
    out = impact(1.2)
    slap = svf(noise(int(0.12 * SR)), lambda t: 950, q=1.2)
    for i, v in enumerate(slap):
        out[i] += 1.2 * v * exp(-(i / SR) / 0.04)
    return out


# --- score -----------------------------------------------------------------------
# 120 BPM in D major. The problem sits on a muted B minor; the fix opens to
# D major on the wipe impact (3.0 s); the cricket pack turns through E minor
# and A before resolving to D on the end card.

CHORDS = [  # (start s, end s, bass, voicing)
    (0.0, 3.0, "B1", ["B3", "D4", "F#4", "A4", "C#5"]),
    (3.0, 5.0, "D2", ["D4", "F#4", "A4", "C#5", "E5"]),
    (5.0, 7.0, "B1", ["B3", "D4", "F#4", "A4", "C#5"]),
    (7.0, 9.0, "G1", ["G3", "B3", "D4", "F#4", "A4"]),
    (9.0, 11.0, "A1", ["A3", "C#4", "E4", "F#4", "B4"]),
    (11.0, 13.0, "D2", ["D4", "F#4", "A4", "C#5", "E5"]),
    (13.0, 15.0, "B1", ["B3", "D4", "F#4", "A4", "C#5"]),
    (15.0, 16.0, "E2", ["E3", "G3", "B3", "D4", "F#4"]),
    (16.0, 17.5, "A1", ["A3", "D4", "E4", "G4", "C#5"]),
    (17.5, 20.0, "D2", ["D3", "A3", "D4", "F#4", "A4", "E5"]),
]
if "music" in T:
    CHORDS = [tuple(ch) for ch in T["music"]["chords"]]

DROP = (T["music"]["drop"] if "drop" in T.get("music", {})
        else sec((T.get("chat") or T["hook"])["wipeFull"]))  # where the drums come in
END_HIT = sec(T["end"]["chime"])  # 17.5 s
# The plucks jump an octave when the packs section starts.
BRIGHT = (T["music"]["bright"] if "bright" in T.get("music", {})
          else sec(T["packs"].get("irisFull", T["packs"].get("drawer", 408))) if "packs" in T else DUR)


def pad_segment(t0, t1, notes, cutoff, gain):
    """Detuned soft-saw pad over one chord, low-passed, with crossfades."""
    att, rel = 0.18, 0.35
    dur = t1 - t0 + rel
    n = int(dur * SR)
    acc = [0.0] * n
    for nm in notes:
        f = note(nm)
        for det in (-0.0025, 0.0025):
            w = TAU * f * (1 + det) / SR
            ph0 = rng.random() * TAU
            for i in range(n):
                p = w * i + ph0
                acc[i] += sin(p) + 0.32 * sin(2 * p) + 0.12 * sin(3 * p)
    body = t1 - t0
    for i in range(n):
        t = i / SR
        env = min(1.0, t / att)
        if t > body:
            env *= max(0.0, 1 - (t - body) / rel)
        acc[i] *= env
    out = onepole_lp(onepole_lp(acc, cutoff), cutoff * 1.6)
    k = gain / (len(notes) * 2)
    return [v * k for v in out]


def build_music():
    for (t0, t1, bass, voicing) in CHORDS:
        intro = t1 <= DROP
        final = t0 >= END_HIT
        cutoff = 650 if intro else (1500 if final else 2300)
        g = 0.20 if intro else (0.30 if final else 0.22)
        seg = pad_segment(t0, min(t1, DUR), voicing, cutoff, g)
        mix(MUS, t0, seg, 1.0, 0.0, send=0.25)

        # Bass: root on each beat 1 and the "and" of 2.
        if not final:
            bt = t0
            while bt < t1 - 1e-6:
                for off, vel in ((0.0, 1.0), (BEAT * 1.5, 0.6)):
                    if bt + off < t1 and (not intro or off == 0.0):
                        b = mallet(note(bass), 0.9, 0.42, partials=((1, 1.0, 1.0), (2, 0.35, 0.5)), attack=0.012)
                        mix(MUS, bt + off, b, 0.30 * vel * (0.7 if intro else 1.0))
                bt += BEAT * 2
        else:
            b = mallet(note("D2"), 2.4, 1.1, partials=((1, 1.0, 1.0), (2, 0.3, 0.6)), attack=0.02)
            mix(MUS, t0, b, 0.36)

        # Pluck arpeggio in 8ths (muted in the intro, brighter for the packs).
        if not final:
            tones = voicing[1:] + [voicing[2][:-1] + str(int(voicing[2][-1]) + 1)]
            pattern = [0, 2, 4, 1, 3, 2, 4, 1]
            step, i = BEAT / 2, 0
            t = t0
            while t < t1 - 1e-6:
                nm = tones[pattern[i % len(pattern)] % len(tones)]
                f = note(nm) * (2 if t >= BRIGHT else 1)
                accent = 1.0 if i % 2 == 0 else 0.7
                if intro:
                    m = mallet(f, 0.35, 0.09)
                    mix(MUS, t, onepole_lp(m, 1600), 0.075 * accent, -0.3 if i % 2 else 0.3)
                else:
                    m = mallet(f, 0.6, 0.22)
                    mix(MUS, t, m, 0.085 * accent, -0.28 if i % 2 else 0.28, send=0.35)
                t += step
                i += 1

    # Drums: soft kick on every beat 1/3, snaps on 2/4, hats in 8ths.
    t = 0.0
    while t < END_HIT - 0.4:
        beat_idx = int(round(t / BEAT))
        if t >= DROP - 1e-6:
            if beat_idx % 2 == 0:
                mix(MUS, t, thump(115, 46, 0.16, 0.45), 0.40)
            else:
                snap = svf(noise(int(0.09 * SR)), lambda _t: 1900, q=1.5)
                snap = [v * exp(-(i / SR) / 0.028) for i, v in enumerate(snap)]
                mix(MUS, t, snap, 0.10, 0.12, send=0.3)
        for sub in (0.0, BEAT / 2):
            ht = t + sub
            hat = onepole_hp(noise(int(0.04 * SR)), 7000)
            hat = [v * exp(-(i / SR) / (0.012 if sub == 0 else 0.022)) for i, v in enumerate(hat)]
            g = (0.022 if sub == 0 else 0.042) if ht >= DROP else 0.018
            mix(MUS, ht, hat, g, 0.35)
        if t < DROP:  # nervous 16th ticks under the chat
            for q in (BEAT / 4, 3 * BEAT / 4):
                mix(MUS, t + q, tick(5200, 1.0), 0.012, -0.4)
        t += BEAT

    # Fill into the end card: rising 16th hats.
    t = END_HIT - 1.0
    k = 0
    while t < END_HIT - 0.12:
        hat = onepole_hp(noise(int(0.03 * SR)), 6000)
        hat = [v * exp(-(i / SR) / 0.015) for i, v in enumerate(hat)]
        mix(MUS, t, hat, 0.02 + 0.006 * k, 0.2 if k % 2 else -0.2)
        t += BEAT / 4
        k += 1


# --- sound design, cue by cue ------------------------------------------------------

D_MAJ_PENT = ["A5", "B5", "D6", "E6", "F#6", "A6", "B6", "D7"]


def chat_sfx(C):
    """Beat 1, shared by both cuts: bubbles pile up, the '?' dot wipes."""
    mix(SFX, sec(C["line1"]), swish(0.18), 0.10, -0.4, label="swish: headline")
    mix(SFX, sec(C["line2"]), swish(0.16), 0.08, -0.4)
    mix(SFX, sec(C["accent"]), mallet(note("F#5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'chat?'")
    who = ["S", "A", "B", "Y", "S", "B", "A", "Y"]
    pitches = ["A5", "D6", "B5", "E6", "D6", "F#6", "E6", "A6"]
    for i, f in enumerate(C["bubbles"]):
        mine = who[i] == "Y"
        mix(SFX, sec(f), blip(note(pitches[i]) * 1.25, note(pitches[i]), 0.1, 0.04), 0.17,
            0.4 if mine else -0.15, send=0.15, label=f"pop: bubble {i + 1}")
    # Tension swell under the pile-up.
    n = int((sec(C["wipeStart"]) - sec(C["shake"])) * SR)
    rumble = onepole_lp(noise(n), 260)
    rumble = [v * (i / n) ** 1.5 for i, v in enumerate(rumble)]
    mix(SFX, sec(C["shake"]), rumble, 0.5, 0.0, label="swell: chaos")
    mix(SFX, sec(C["qdot"]), mallet(note("E6"), 0.4, 0.12), 0.16, -0.2, label="plink: '?' dot")
    wd = sec(C["wipeFull"]) - sec(C["wipeStart"])
    panned_whoosh(sec(C["wipeStart"]), wd + 0.02, 380, 4200, 0.38, -0.5, 0.3, "whoosh: circle wipe")
    mix(SFX, sec(C["wipeFull"]), impact(1.0), 0.62, 0.0, send=0.35, label="IMPACT: emerald wipe")


LETTERS = [c for c in "Bite Size" if c != " "]


def signoff_sfx(E):
    """The end card, shared by both cuts."""
    ed = sec(E["irisFull"]) - sec(E["irisStart"])
    panned_whoosh(sec(E["irisStart"]) - 0.05, ed + 0.05, 600, 6000, 0.3, 0.45, -0.2, "whoosh: light iris")
    for i in range(len(LETTERS)):
        mix(SFX, sec(E["letters"] + i * 2), tick(2400 + 80 * i), 0.03, -0.25 + 0.06 * i)
    for nm, g, d in (("D5", 0.22, 0.0), ("A5", 0.16, 0.02), ("F#6", 0.12, 0.05), ("E6", 0.07, 0.08)):
        mix(SFX, END_HIT + d, bell(note(nm), 2.5, 1.0), g, 0.0, send=0.55)
    mix(SFX, END_HIT, impact(0.5), 0.22, 0.0, send=0.4)
    CUES.append({"t": round(END_HIT, 3), "frame": E["chime"], "sfx": "CHIME: end card"})
    mix(SFX, sec(E["tagline"]), swish(0.16), 0.07, 0.0, label="swish: tagline")
    for i, f in enumerate(E["chips"]):
        mix(SFX, sec(f), blip(note(["D6", "A6"][i]) * 1.2, note(["D6", "A6"][i]), 0.1, 0.04), 0.08, -0.2 + 0.4 * i,
            send=0.2, label=f"pop: pack chip {i + 1}")


def build_sfx():
    C, B, P, S, K, E = T["chat"], T["brand"], T["phone"], T["split"], T["packs"], T["end"]
    chat_sfx(C)

    # The fix.
    letters = LETTERS
    for i in range(len(letters)):
        mix(SFX, sec(B["letters"] + i * 2), tick(2600 + 90 * i), 0.035, -0.3 + 0.07 * i)
    for nm, g in (("D6", 0.2), ("A5", 0.14), ("F#6", 0.08)):
        mix(SFX, sec(B["chime"]), bell(note(nm), 2.2, 0.9), g, 0.0, send=0.5)
    CUES.append({"t": round(sec(B["chime"]), 3), "frame": B["chime"], "sfx": "chime: wordmark"})
    for i, f in enumerate(B["rowSnaps"]):
        mix(SFX, sec(f), click(1.0 + 0.08 * i), 0.22, 0.25, label=f"snap: row {i + 1}")
        mix(SFX, sec(f), thump(180, 90, 0.05, 0.2), 0.22, 0.2)
    md = sec(B["morphEnd"]) - sec(B["morphStart"])
    panned_whoosh(sec(B["morphStart"]) - 0.05, md + 0.05, 3800, 600, 0.3, -0.2, 0.45, "whoosh: field to phone")
    mix(SFX, sec(B["morphEnd"]), thump(140, 60, 0.09), 0.36, 0.3, label="land: phone")

    mix(SFX, sec(P["headline"][0]), swish(0.18), 0.10, -0.4, label="swish: 'One list.'")
    mix(SFX, sec(P["headline"][2]), mallet(note("A5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'arguments.'")
    for off, nm in ((0.0, "E6"), (0.07, "A6")):
        mix(SFX, sec(P["invite"]) + off, mallet(note(nm), 0.45, 0.16), 0.13, 0.35, send=0.3)
    CUES.append({"t": round(sec(P["invite"]), 3), "frame": P["invite"], "sfx": "ding: shared-cost invite"})
    mix(SFX, sec(P["click"]), click(1.1), 0.34, 0.35, label="CLICK: Join")
    zd = sec(S["pullStart"]) - sec(P["zoomStart"])
    panned_whoosh(sec(P["zoomStart"]) - 0.1, zd + 0.1, 500, 6500, 0.42, 0.4, -0.1, "whoosh: camera push")

    # Beat 2: the split.
    mix(SFX, sec(S["pullStart"]), impact(0.9), 0.55, 0.0, send=0.35, label="IMPACT: into the ledger")
    panned_whoosh(sec(S["pullStart"]), 0.55, 5000, 700, 0.18, 0.0, 0.0, "air: pull back")
    mix(SFX, sec(S["joined"]), click(1.0), 0.26, 0.0, label="CLICK: accept shared cost")
    for off, nm, g in ((0.0, "A5", 0.18), (0.075, "D6", 0.18), (0.15, "F#6", 0.12)):
        mix(SFX, sec(S["joined"]) + off, mallet(note(nm), 0.7, 0.3), g, 0.0, send=0.45)
    CUES.append({"t": round(sec(S["joined"]), 3), "frame": S["joined"], "sfx": "chime: joined"})
    for i, (f, nm) in enumerate(zip(S["avatars"], ["F#5", "A5", "D6"])):
        mix(SFX, sec(f), blip(note(nm) * 1.2, note(nm), 0.09, 0.035), 0.13, -0.1 + 0.1 * i, label=f"pop: avatar {i + 1}")
    mix(SFX, sec(S["each"]), tick(2400), 0.08, 0.0)
    for name, f, pan in (("card: run", S["card1"], -0.5), ("card: share", S["card3"], 0.0), ("card: ledger", S["card4"], 0.5)):
        mix(SFX, sec(f), swish(0.2), 0.10, pan, label=f"swish: {name}")
        mix(SFX, sec(f) + 0.2, thump(200, 110, 0.04, 0.15), 0.12, pan)
    mix(SFX, sec(S["runner"]), tick(1500), 0.08, -0.5)
    for i, f in enumerate(S["rows"]):
        mix(SFX, sec(f), tick(1700 + 140 * i), 0.09, -0.5, label=f"tick: row {i + 1}")
    for j in range(4):
        mix(SFX, sec(S["total"]) + j * 0.045, tick(3000 + 120 * j), 0.045, -0.45)
    mix(SFX, sec(S["total"]) + 0.2, mallet(note("D6"), 0.4, 0.14), 0.08, -0.45)
    mix(SFX, sec(S["lock"]), lock_sound(), 0.5, -0.45, send=0.2, label="LOCK: runner left")
    mix(SFX, sec(S["lock"]), impact(0.55), 0.3, -0.3, send=0.2)
    for i, f in enumerate(S["share"]):
        mix(SFX, sec(f), tick(2000 + 200 * i), 0.08, 0.0, label=f"tick: share {i + 1}")
    mix(SFX, sec(S["share"][2]) + 0.15, mallet(note("A5"), 0.4, 0.16), 0.09, 0.0)
    for i, f in enumerate(S["ledger"]):
        mix(SFX, sec(f), tick(1800 + 150 * i), 0.09, 0.5, label=f"tick: ledger {i + 1}")
        for j in range(3):
            mix(SFX, sec(f) + 0.06 + j * 0.05, tick(3400, 1.0), 0.02, 0.5)
    for off, nm, g in ((0.0, "D6", 0.16), (0.0, "F#6", 0.1), (0.09, "A6", 0.1)):
        mix(SFX, sec(S["net"]) + off, bell(note(nm), 1.4, 0.55), g, 0.45, send=0.4)
    CUES.append({"t": round(sec(S["net"]), 3), "frame": S["net"], "sfx": "chime: net Rs 0"})
    mix(SFX, sec(S["stamp"]) - 0.12, swish(0.14), 0.16, 0.0)
    mix(SFX, sec(S["stamp"]), stamp_sound(), 0.62, 0.0, send=0.4, label="STAMP: 'Adds up.'")
    panned_whoosh(sec(S["stampSettle"]), 0.45, 2600, 700, 0.14, 0.0, 0.0, "whoosh: stamp settles")
    for i, (f, nm) in enumerate(zip(S["badges"], ["D6", "E6", "F#6", "A6"])):
        mix(SFX, sec(f), blip(note(nm) * 1.2, note(nm), 0.12, 0.05), 0.12, -0.5 + 0.33 * i, send=0.25, label=f"pop: badge {i + 1}")

    # Beat 3: activity packs.
    ird = sec(K["irisFull"]) - sec(K["irisStart"])
    panned_whoosh(sec(K["irisStart"]) - 0.05, ird + 0.05, 3200, 300, 0.36, 0.3, -0.3, "whoosh: dark iris")
    mix(SFX, sec(K["irisFull"]), impact(0.6), 0.32, 0.0, send=0.3, label="boom: packs stage")
    mix(SFX, sec(K["card"]), swish(0.22), 0.11, 0.5, label="swish: pack panel")
    mix(SFX, sec(K["headline"][2]), mallet(note("B5"), 0.5, 0.2), 0.11, -0.3, send=0.4, label="tone: 'pack.'")
    for i, f in enumerate(K["office"]):
        mix(SFX, sec(f), tick(1800 + 160 * i), 0.08, 0.45, label=f"tick: lunch row {i + 1}")
    # Riser into the toggle, then the switch.
    rd = 0.42
    rn = int(rd * SR)
    riser = svf(noise(rn), lambda t: 500 * (3600 / 500) ** (t / rd), q=2.0)
    riser = [v * (i / rn) ** 2 for i, v in enumerate(riser)]
    mix(SFX, sec(K["toggle"]) - rd, riser, 0.22, 0.3, label="riser: pack switch")
    mix(SFX, sec(K["toggle"]), click(0.9), 0.32, 0.4, label="CLICK: Cricket Ground")
    mix(SFX, sec(K["toggle"]), thump(620, 380, 0.03, 0.12), 0.2, 0.4)
    wd2 = sec(K["wipeEnd"]) - sec(K["toggle"])
    panned_whoosh(sec(K["toggle"]) + 0.03, wd2, 900, 5200, 0.26, 0.4, 0.2, "whoosh: pack wipe")
    for nm, g in (("E5", 0.14), ("B5", 0.12), ("G5", 0.09)):
        mix(SFX, sec(K["wipeEnd"]), bell(note(nm), 1.6, 0.6), g, 0.3, send=0.5)
    CUES.append({"t": round(sec(K["wipeEnd"]), 3), "frame": K["wipeEnd"], "sfx": "chime: ground pack"})
    for i, f in enumerate(K["cricket"]):
        mix(SFX, sec(f), tick(1600 + 200 * i), 0.09, 0.45, label=f"tick: cricket row {i + 1}")
    mix(SFX, sec(K["cricket"][3]) + 0.12, mallet(note("E6"), 0.5, 0.18), 0.11, 0.45, send=0.4, label="tone: Rs 500 each")

    signoff_sfx(E)


def ui_click(t, label=None, pan=0.35):
    mix(SFX, t, click(1.05), 0.3, pan, label=label)
    mix(SFX, t, thump(260, 150, 0.025, 0.1), 0.12, pan)


def toast_ding(t, label=None, pan=0.35):
    for off, nm in ((0.0, "E6"), (0.06, "A6")):
        mix(SFX, t + off, mallet(note(nm), 0.4, 0.14), 0.09, pan, send=0.3)
    if label:
        CUES.append({"t": round(t, 3), "frame": round(t * FPS, 1), "sfx": label})


def build_sfx_app():
    """The app-accurate cut: taps, toasts and state changes from the real flow."""
    C, SPL, O, I, LK, LG, K, E = (T[k] for k in ("chat", "splash", "overview", "invite", "lock", "ledger", "packs", "end"))
    chat_sfx(C)

    # The splash, then it becomes the phone.
    for nm, g in (("D6", 0.2), ("A5", 0.14), ("F#6", 0.08)):
        mix(SFX, sec(SPL["chime"]), bell(note(nm), 2.2, 0.9), g, 0.0, send=0.5)
    CUES.append({"t": round(sec(SPL["chime"]), 3), "frame": SPL["chime"], "sfx": "chime: splash lockup"})
    md = sec(SPL["morphEnd"]) - sec(SPL["morphStart"])
    panned_whoosh(sec(SPL["morphStart"]) - 0.05, md + 0.05, 3800, 600, 0.3, -0.2, 0.45, "whoosh: splash into phone")
    mix(SFX, sec(SPL["morphEnd"]), thump(140, 60, 0.09), 0.34, 0.3, label="land: phone")
    mix(SFX, sec(SPL["launch"]), mallet(note("A5"), 0.4, 0.14), 0.08, 0.35, label="tone: app launches")

    # Overview, then the push into the invite.
    mix(SFX, sec(O["headline"][0]), swish(0.18), 0.10, -0.4, label="swish: 'One list.'")
    mix(SFX, sec(O["headline"][2]), mallet(note("A5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'arguments.'")
    pd = sec(O["pushEnd"]) - sec(O["pushStart"])
    panned_whoosh(sec(O["pushStart"]) - 0.08, pd + 0.08, 500, 6500, 0.4, 0.4, -0.1, "whoosh: camera push")
    mix(SFX, sec(O["pushEnd"]), impact(0.7), 0.42, 0.1, send=0.3, label="IMPACT: into the invite")

    # A cost is an invite.
    mix(SFX, sec(I["headline"][0]), swish(0.16), 0.09, -0.4, label="swish: 'A cost is an'")
    mix(SFX, sec(I["headline"][1]), mallet(note("B5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'invite.'")
    ui_click(sec(I["press"]), "CLICK: Count me in")
    toast_ding(sec(I["toast"]), "ding: you're in")
    mix(SFX, sec(I["collapse"]), swish(0.14), 0.06, 0.35, label="swish: invite answered")
    panned_whoosh(sec(I["scrollDown"]), 0.45, 1400, 500, 0.08, 0.35, 0.35, "scroll: to the shared meal")
    for off, nm, g in ((0.0, "A5", 0.18), (0.075, "D6", 0.18), (0.15, "F#6", 0.12)):
        mix(SFX, sec(I["saraAccepts"]) + off, mallet(note(nm), 0.7, 0.3), g, 0.35, send=0.45)
    CUES.append({"t": round(sec(I["saraAccepts"]), 3), "frame": I["saraAccepts"], "sfx": "chime: Sara accepts, Rs 160 each"})
    panned_whoosh(sec(I["scrollUp"]), 0.4, 500, 1400, 0.08, 0.35, 0.35, "scroll: back to the runner")

    # The runner leaves and the list locks.
    mix(SFX, sec(LK["headline"][0]), swish(0.16), 0.09, -0.4, label="swish: 'Runner leaves.'")
    mix(SFX, sec(LK["headline"][1]) + 0.2, mallet(note("D6"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'locks.'")
    ui_click(sec(LK["pressStart"]), "CLICK: Start the tandoor run")
    mix(SFX, sec(LK["dialog"]), blip(note("A5"), note("D6"), 0.12, 0.06), 0.1, 0.3, send=0.2, label="pop: Heading out?")
    ui_click(sec(LK["pressLock"]), "CLICK: Lock it & go")
    mix(SFX, sec(LK["locked"]), lock_sound(), 0.5, 0.3, send=0.2, label="LOCK: list locked")
    mix(SFX, sec(LK["locked"]), impact(0.55), 0.3, 0.2, send=0.2)
    toast_ding(sec(LK["toast"]) + 0.1, "ding: off on the tandoor run")
    panned_whoosh(sec(LK["pullBack"]), 0.5, 4500, 800, 0.14, 0.2, 0.2, "air: pull back")

    # Month-end: one price per roti.
    panned_whoosh(sec(LG["push"]) - 0.04, 0.32, 900, 3200, 0.16, 0.6, 0.1, "whoosh: ledger page")
    mix(SFX, sec(LG["headline"][0]), swish(0.16), 0.09, -0.4, label="swish: 'One price'")
    mix(SFX, sec(LG["headline"][1]) + 0.17, mallet(note("F#5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'roti.'")
    panned_whoosh(sec(LG["sheet"]) - 0.02, 0.3, 700, 2600, 0.14, 0.3, 0.3, "whoosh: settle sheet")
    mix(SFX, sec(LG["tapField"]), tick(2100), 0.1, 0.3, label="tick: price field")
    for i, f in enumerate(LG["type"]):
        mix(SFX, sec(f), click(0.8 + 0.1 * i), 0.16, 0.3, label=f"key: '{'25'[i]}'")
        for j in range(3):
            mix(SFX, sec(f) + 0.05 + j * 0.04, tick(3200 + 150 * j), 0.025, 0.3)
    ui_click(sec(LG["pressSettle"]), "CLICK: Settle October")
    for off, nm, g in ((0.0, "D6", 0.16), (0.0, "F#6", 0.1), (0.09, "A6", 0.1)):
        mix(SFX, sec(LG["settled"]) + off, bell(note(nm), 1.4, 0.55), g, 0.3, send=0.4)
    mix(SFX, sec(LG["settled"]), impact(0.45), 0.24, 0.1, send=0.3)
    CUES.append({"t": round(sec(LG["settled"]), 3), "frame": LG["settled"], "sfx": "CHIME: October settled"})
    toast_ding(sec(LG["toast"]) + 0.1, "ding: October settled")
    panned_whoosh(sec(LG["pop"]), 0.3, 3000, 900, 0.12, 0.1, 0.5, "whoosh: back to today")

    # Same app, new pack.
    panned_whoosh(sec(K["drawer"]) - 0.03, 0.3, 800, 3000, 0.16, -0.2, 0.4, "whoosh: drawer")
    mix(SFX, sec(K["headline"][0]), swish(0.16), 0.09, -0.4, label="swish: 'Same app.'")
    mix(SFX, sec(K["headline"][2]), mallet(note("B5"), 0.5, 0.2), 0.11, -0.3, send=0.4, label="tone: 'pack.'")
    ui_click(sec(K["tapTheme"]), "CLICK: Theme")
    panned_whoosh(sec(K["sheet"]) - 0.02, 0.3, 700, 2600, 0.14, 0.3, 0.3, "whoosh: Theme sheet")
    rd = 0.42
    rn = int(rd * SR)
    riser = svf(noise(rn), lambda t: 500 * (3600 / 500) ** (t / rd), q=2.0)
    riser = [v * (i / rn) ** 2 for i, v in enumerate(riser)]
    mix(SFX, sec(K["tapGround"]) - rd, riser, 0.2, 0.3, label="riser: pack switch")
    ui_click(sec(K["tapGround"]), "CLICK: Ground Booking")
    wd2 = sec(K["groundIn"]) - sec(K["reload"]) + 0.2
    panned_whoosh(sec(K["reload"]) - 0.03, wd2, 900, 5200, 0.26, 0.4, 0.2, "whoosh: app reloads")
    mix(SFX, sec(K["reload"]), impact(0.55), 0.3, 0.1, send=0.3)
    for nm, g in (("E5", 0.14), ("B5", 0.12), ("G5", 0.09)):
        mix(SFX, sec(K["groundIn"]), bell(note(nm), 1.6, 0.6), g, 0.3, send=0.5)
    CUES.append({"t": round(sec(K["groundIn"]), 3), "frame": K["groundIn"], "sfx": "chime: Ground Booking"})
    for i, f in enumerate(K["rows"]):
        mix(SFX, sec(f), tick(1600 + 220 * i), 0.09, 0.35, label=f"tick: ground row {i + 1}")

    signoff_sfx(E)


def psst():
    """A whispered 'psst': a soft plosive, a long hiss, a tiny tongue tap."""
    dur = 0.62
    n = int(dur * SR)
    hiss = svf(noise(n), lambda t: 5200 + 1400 * min(1.0, t / dur), q=1.6)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        if t < 0.05:  # the "p"
            env = (t / 0.05) * 0.5
        elif t < 0.09:
            env = 0.5 * (1 - (t - 0.05) / 0.04) + 0.15
        elif t < 0.5:  # the "sss"
            env = 0.15 + 0.85 * min(1.0, (t - 0.09) / 0.12) * (1 - max(0.0, t - 0.38) / 0.12)
        else:
            env = 0.0
        out[i] = hiss[i] * env
    pop = onepole_lp(noise(int(0.04 * SR)), 900)
    for i, v in enumerate(pop):
        out[i] += 0.8 * v * exp(-(i / SR) / 0.012)
    tap = click(1.6)  # the "t"
    i0 = int(0.53 * SR)
    for i, v in enumerate(tap):
        if i0 + i < n:
            out[i0 + i] += 0.35 * v
    m = max(1e-9, max(abs(v) for v in out))
    return [v / m for v in out]


def boing(f0=330, f1=660, dur=0.28):
    """A springy pop for the mascot hopping into frame."""
    n = int(dur * SR)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (1 - exp(-t / 0.05)) + 18 * sin(TAU * 11 * t) * exp(-t / 0.1)
        ph += TAU * f / SR
        out[i] = min(1.0, t / 0.003) * exp(-t / 0.09) * (sin(ph) + 0.25 * sin(2 * ph))
    return out


def build_sfx_ref():
    """The reference cut: same instrument, the reference film's beats."""
    H, A, R, S, P, E = (T[k] for k in ("hook", "anything", "roster", "sorted", "split", "end"))

    # 01 · hook: the mascot peeks in and whispers.
    panned_whoosh(0.0, 0.42, 3000, 700, 0.18, 0.9, 0.4, "whoosh: mascot peeks in")
    mix(SFX, sec(H["peek"]) + 0.42, boing(300, 520), 0.12, 0.45, label="boing: mascot lands")
    mix(SFX, sec(H["bubble"]), blip(note("E6") * 1.2, note("E6"), 0.1, 0.04), 0.12, 0.2, label="pop: speech bubble")
    mix(SFX, sec(H["bubble"]) + 0.07, psst(), 0.16, 0.25, send=0.25, label="psst")
    mix(SFX, sec(H["line1"][0]), swish(0.18), 0.10, -0.4, label="swish: 'Who's in'")
    mix(SFX, sec(H["line2"]), swish(0.16), 0.08, -0.4)
    mix(SFX, sec(H["accent"]), mallet(note("F#5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'lunch?'")
    mix(SFX, sec(H["accent"]) + 0.1, boing(420, 640, 0.2), 0.06, 0.45)
    mix(SFX, sec(H["qdot"]), mallet(note("E6"), 0.4, 0.12), 0.16, -0.2, label="plink: '?' dot")
    wd = sec(H["wipeFull"]) - sec(H["wipeStart"])
    panned_whoosh(sec(H["wipeStart"]) - 0.05, wd + 0.07, 380, 3600, 0.28, -0.5, 0.3, "whoosh: circle wipe")
    mix(SFX, sec(H["wipeFull"]), impact(0.9), 0.42, 0.0, send=0.4, label="IMPACT: brand field")

    # 02 · anything: the mascot rises, three cards land.
    panned_whoosh(sec(A["rise"]), 0.35, 600, 2400, 0.14, -0.6, -0.4, "whoosh: mascot rises")
    for i, f in enumerate(A["cards"]):
        panned_whoosh(sec(f) - 0.12, 0.3, 1200, 5200, 0.16, 0.8, 0.1 + 0.25 * i, f"whoosh: card {i + 1}")
        mix(SFX, sec(f) + 0.3, thump(190, 95, 0.05, 0.18), 0.22, 0.1 + 0.25 * i)
        mix(SFX, sec(f) + 0.3, tick(2000 + 300 * i), 0.07, 0.1 + 0.25 * i)
    mix(SFX, sec(A["cards"][2]) + 0.45, mallet(note("D6"), 0.6, 0.25), 0.1, 0.3, send=0.4)
    sd = sec(A["shrinkEnd"]) - sec(A["shrinkStart"])
    panned_whoosh(sec(A["shrinkStart"]) - 0.05, sd + 0.05, 3800, 600, 0.3, -0.2, 0.45, "whoosh: field into phone")
    mix(SFX, sec(A["shrinkEnd"]), thump(140, 60, 0.09), 0.32, 0.4, label="land: phone")

    # 03 · roster: the app opens, the cursor taps COUNT ME IN.
    mix(SFX, sec(R["launch"]), mallet(note("A5"), 0.4, 0.14), 0.08, 0.4, label="tone: app opens")
    mix(SFX, sec(R["line1"]), swish(0.18), 0.09, -0.4, label="swish: 'Bite Size turns it into'")
    mix(SFX, sec(R["line2"]), swish(0.18), 0.10, -0.4)
    mix(SFX, sec(R["line3"][1]), mallet(note("A5"), 0.5, 0.2), 0.12, -0.3, send=0.4, label="tone: 'runner.'")
    mix(SFX, sec(R["click"]), click(1.1), 0.34, 0.45, label="CLICK: Count me in")
    zd = sec(R["zoomEnd"]) - sec(R["zoomStart"])
    panned_whoosh(sec(R["zoomStart"]) - 0.08, zd + 0.08, 500, 5200, 0.3, 0.45, -0.1, "whoosh: camera push")

    # 04 · sorted: the streak, the pull back, the bento filling in.
    mix(SFX, sec(S["pullStart"]), impact(0.8), 0.34, 0.0, send=0.4, label="IMPACT: into the bento")
    panned_whoosh(sec(S["pullStart"]), sec(S["pullEnd"]) - sec(S["pullStart"]), 4200, 700, 0.16, -0.1, 0.1, "air: pull back")
    for j in range(16):
        mix(SFX, sec(S["type"]) + j * 0.034, tick(3000 + 90 * (j % 5)), 0.035, -0.4)
    CUES.append({"t": round(sec(S["type"]), 3), "frame": S["type"], "sfx": "typing: Bilal, Sara, Ali"})
    mix(SFX, sec(S["month"]), swish(0.18), 0.08, 0.5, label="swish: month-end card")
    for j in range(6):
        mix(SFX, sec(S["month"]) + 0.05 + j * 0.06, tick(3300 + 120 * j), 0.03, 0.5)
    for i, f in enumerate(S["dots"]):
        mix(SFX, sec(f), blip(note(["D6", "E6", "F#6", "A6", "B6"][i]) * 1.15, note(["D6", "E6", "F#6", "A6", "B6"][i]), 0.08, 0.03),
            0.07, 0.5, label=f"dot: {['MON', 'TUE', 'WED', 'THU', 'FRI'][i]}")
    mix(SFX, sec(S["roster"]), swish(0.18), 0.08, 0.0, label="swish: who's in card")
    for i, f in enumerate(S["checks"]):
        mix(SFX, sec(f), click(0.95 + 0.1 * i), 0.24, 0.0, label=f"check: row {i + 1}")
        mix(SFX, sec(f) + 0.02, mallet(note(["A5", "D6"][i]), 0.4, 0.14), 0.07, 0.0)
    mix(SFX, sec(S["lock"]), swish(0.18), 0.08, 0.5, label="swish: lock card")
    for i, f in enumerate(S["chips"]):
        mix(SFX, sec(f), lock_sound(), 0.16 + 0.05 * i, 0.5, label=f"lock: chip {i + 1}")
    mix(SFX, sec(S["share"]), mallet(note("F#5"), 0.4, 0.15), 0.08, -0.4, label="tone: split 3 ways")
    for off, nm, g in ((0.0, "A5", 0.16), (0.075, "D6", 0.16), (0.15, "F#6", 0.1)):
        mix(SFX, sec(S["total"]) + off, mallet(note(nm), 0.6, 0.26), g, -0.3, send=0.4)
    CUES.append({"t": round(sec(S["total"]), 3), "frame": S["total"], "sfx": "chime: everyone's in, Rs 160"})
    mix(SFX, sec(S["bill"]), swish(0.18), 0.08, 0.5, label="swish: october bill")
    for j in range(14):
        mix(SFX, sec(S["billCount"]) + j * 0.045, tick(2600 + 60 * j), 0.03, 0.5)
    CUES.append({"t": round(sec(S["billCount"]), 3), "frame": S["billCount"], "sfx": "count: Rs 3,300.00"})
    mix(SFX, sec(S["stamp"]) - 0.12, swish(0.14), 0.16, 0.0)
    mix(SFX, sec(S["stamp"]), stamp_sound(), 0.46, 0.0, send=0.4, label="STAMP: 'Sorted.'")
    panned_whoosh(sec(S["settle"]), 0.4, 2600, 700, 0.14, 0.0, 0.0, "whoosh: stamp settles")
    for off, nm, g in ((0.0, "D6", 0.14), (0.0, "F#6", 0.09), (0.09, "A6", 0.09)):
        mix(SFX, sec(S["joined"]) + off, bell(note(nm), 1.2, 0.5), g, -0.4, send=0.4)
    CUES.append({"t": round(sec(S["joined"]), 3), "frame": S["joined"], "sfx": "chime: billed at month-end"})
    for i, (f, nm) in enumerate(zip(S["badges"], ["D6", "E6", "F#6", "A6"])):
        mix(SFX, sec(f), blip(note(nm) * 1.2, note(nm), 0.12, 0.05), 0.11, -0.5 + 0.33 * i, send=0.25, label=f"pop: badge {i + 1}")

    # 05 · split: dark, then the line that names the app.
    ird = sec(P["irisFull"]) - sec(P["irisStart"])
    panned_whoosh(sec(P["irisStart"]) - 0.05, ird + 0.05, 3200, 300, 0.34, 0.3, -0.3, "whoosh: dark iris")
    mix(SFX, sec(P["irisFull"]), impact(0.6), 0.3, 0.0, send=0.3, label="boom: dark stage")
    mix(SFX, sec(P["you"]), swish(0.16), 0.08, -0.4, label="swish: 'You'")
    mix(SFX, sec(P["accent1"]), mallet(note("D6"), 0.5, 0.2), 0.12, -0.3, send=0.45, label="tone: 'bite.'")
    for f in P["we"]:
        mix(SFX, sec(f), swish(0.12), 0.05, -0.4)
    rn = int(0.5 * SR)
    shimmer = svf(noise(rn), lambda t: 3000 * (9000 / 3000) ** (t / 0.5), q=3.0)
    shimmer = [v * (1 - i / rn) ** 1.5 for i, v in enumerate(shimmer)]
    mix(SFX, sec(P["accent2"]), shimmer, 0.12, -0.2, send=0.5, label="shimmer: 'size.' glows")
    mix(SFX, sec(P["accent2"]), bell(note("A5"), 1.0, 0.45), 0.1, -0.2, send=0.5)
    wd2 = sec(P["whiteFull"]) - sec(P["whiteStart"])
    panned_whoosh(sec(P["whiteStart"]) - 0.05, wd2 + 0.05, 600, 6000, 0.3, -0.2, 0.2, "whoosh: light iris")

    # The wordmark, the mascot peeking from behind it.
    for i in range(4):
        mix(SFX, sec(E["letters"] + i * 2), tick(2400 + 90 * i), 0.04, -0.2 + 0.1 * i)
    for nm, g, d in (("D5", 0.22, 0.0), ("A5", 0.16, 0.02), ("F#6", 0.12, 0.05), ("E6", 0.07, 0.08)):
        mix(SFX, END_HIT + d, bell(note(nm), 2.5, 1.0), g, 0.0, send=0.55)
    mix(SFX, END_HIT, impact(0.5), 0.22, 0.0, send=0.4)
    CUES.append({"t": round(END_HIT, 3), "frame": E["chime"], "sfx": "CHIME: wordmark"})
    mix(SFX, sec(E["tagline"]), swish(0.16), 0.07, 0.0, label="swish: tagline")
    mix(SFX, sec(E["mascot"]), boing(280, 560, 0.3), 0.12, 0.0, label="boing: mascot peeks over")
    mix(SFX, sec(E["cta"]), blip(note("D6") * 1.2, note("D6"), 0.1, 0.04), 0.1, -0.1, send=0.2, label="pop: Count me in")


def chat_ding(t, pan=-0.45, label=None):
    """A soft two-note message notification."""
    for off, nm, g in ((0.0, "B5", 0.07), (0.06, "E6", 0.06)):
        mix(SFX, t + off, mallet(note(nm), 0.35, 0.1), g, pan, send=0.2)
    if label:
        CUES.append({"t": round(t, 3), "frame": round(t * FPS, 1), "sfx": label})


def typing(t0, chars, rate, gain=0.022, pan=-0.45, label=None):
    """Keystrokes: one soft tick per character, slightly humanised."""
    for j in range(chars):
        jitter = (rng.random() - 0.5) * 0.008
        mix(SFX, t0 + j / (rate * FPS) + jitter, tick(2700 + rng.random() * 900), gain * (0.8 + 0.4 * rng.random()), pan)
    if label:
        CUES.append({"t": round(t0, 3), "frame": round(t0 * FPS, 1), "sfx": label})


def build_sfx_notes():
    """The notes cut: the chat's revisions, then the console's answer."""
    N, P, G, K, C, TL, E = (T[k] for k in ("notes", "prompt", "grid", "tools", "chart", "tiles", "end"))
    V = N["versions"]
    quotes = [19, 11, 21, 25, 20, 26, 28, 30]  # characters typed per note

    # Part 1: every note lands like a message, then reshapes the word.
    for i, v in enumerate(V):
        chat_ding(sec(v) + 0.05, label=f"ding: note v{i + 1}")
        typing(sec(v) + 0.07, quotes[i], 2.2, gain=0.012)
    mix(SFX, sec(V[0]) + 0.08, mallet(note("D5"), 0.6, 0.25), 0.1, 0.0, send=0.4, label="tone: Lunch?")
    mix(SFX, sec(V[1]), boing(300, 560, 0.3), 0.14, 0.0, label="pop: copper disc")
    for j in range(7):
        mix(SFX, sec(V[1] + 3 + j * 1.5), tick(2200 + 140 * j), 0.05, -0.2 + 0.06 * j)
    panned_whoosh(sec(V[2]), 0.9, 900, 2600, 0.14, -0.8, 0.8, "whoosh: marquee")
    rd = sec(V[3] + 28) - sec(V[3] + 4)
    rn = int(rd * SR)
    riser = svf(noise(rn), lambda t: 400 * (4200 / 400) ** (t / rd), q=2.2)
    riser = [v * (i / rn) ** 1.6 for i, v in enumerate(riser)]
    mix(SFX, sec(V[3] + 4), riser, 0.18, 0.0, label="riser: bigger.")
    panned_whoosh(sec(V[4] + 6), 0.66, 2400, 500, 0.22, -0.8, 0.8, "whoosh: contrast wipe")
    mix(SFX, sec(V[4] + 22), thump(110, 50, 0.14, 0.4), 0.3, 0.0)
    an = int(0.9 * SR)
    air = svf(noise(an), lambda t: 6000, q=0.9)
    air = [v * sin(math.pi * i / an) ** 2 for i, v in enumerate(air)]
    mix(SFX, sec(V[5] + 2), air, 0.07, 0.0, send=0.4, label="air: let it breathe")
    for nm, g in (("D6", 0.14), ("A5", 0.1), ("F#6", 0.06)):
        mix(SFX, sec(V[6] + 2), bell(note(nm), 1.6, 0.7), g, 0.0, send=0.55)
    CUES.append({"t": round(sec(V[6] + 2), 3), "frame": V[6] + 2, "sfx": "bell: v7_final"})
    zd = sec(N["fill"]) - sec(N["zoomStart"])
    panned_whoosh(sec(N["zoomStart"]), zd + 0.05, 300, 5200, 0.34, 0.2, 0.0, "whoosh: dive into the dot")
    mix(SFX, sec(N["fill"]), impact(0.9), 0.48, 0.0, send=0.35, label="IMPACT: green flood")

    # Part 2: the console.
    md = sec(P["morphEnd"]) - sec(P["morphStart"])
    panned_whoosh(sec(P["morphStart"]), md, 4200, 600, 0.18, 0.0, 0.0, "whoosh: flood to cursor")
    typing(sec(P["head"]), 17, 1.1, gain=0.05, pan=0.0, label="typing: the headline")
    mix(SFX, sec(P["head"] + 11), mallet(note("A5"), 0.5, 0.2), 0.09, 0.0, send=0.4)
    mix(SFX, sec(P["field"]), swish(0.18), 0.08, 0.0, label="swish: input")
    typing(sec(P["type"]), 19, 2.0, gain=0.045, pan=0.1, label="typing: daal mash, 3 rotis")
    for j in range(4):
        mix(SFX, sec(P["chips"] + j * 2.5), tick(2000 + 250 * j), 0.05, -0.3 + 0.2 * j)
    mix(SFX, sec(P["pill"]), blip(note("E6") * 1.2, note("E6"), 0.09, 0.035), 0.09, 0.4, label="pop: ROSTER pill")
    mix(SFX, sec(P["enter"]), click(1.0), 0.34, 0.35, label="CLICK: enter")
    mix(SFX, sec(P["enter"]), thump(240, 120, 0.04, 0.14), 0.2, 0.35)

    panned_whoosh(sec(G["start"]) - 0.05, 0.5, 500, 3000, 0.2, -0.2, 0.2, "whoosh: grid tilts in")
    scale_notes = ["D5", "E5", "F#5", "A5", "B5", "D6", "E6", "F#6", "A6", "B6", "D7", "E7"]
    for i in range(12):
        t = sec(G["firstCard"] + i * G["cardStep"])
        mix(SFX, t, mallet(note(scale_notes[i]), 0.3, 0.09), 0.055, -0.6 + 0.11 * i, send=0.25)
        mix(SFX, t, tick(3000), 0.02, -0.6 + 0.11 * i)
    CUES.append({"t": round(sec(G["firstCard"]), 3), "frame": G["firstCard"], "sfx": "cards: 12 roster cards"})
    mix(SFX, sec(G["caption1"]), swish(0.16), 0.08, -0.5, label="swish: One list.")
    mix(SFX, sec(G["caption2"]), mallet(note("D6"), 0.5, 0.2), 0.11, -0.4, send=0.4, label="tone: Twelve lunches.")

    tool_notes = [("D6", "A5"), ("E6", "B5"), ("F#6", "D6"), ("A6", "E6"), ("B6", "F#6")]
    for i, f in enumerate(K["words"]):
        t = sec(f)
        mix(SFX, t, thump(170, 70, 0.08, 0.3), 0.3, 0.0)
        mix(SFX, t, click(1.2), 0.12, 0.0)
        for nm in tool_notes[i]:
            mix(SFX, t, mallet(note(nm), 0.45, 0.16), 0.07, 0.0, send=0.35)
        CUES.append({"t": round(t, 3), "frame": f, "sfx": f"HIT: toolkit {i + 1}"})
    mix(SFX, sec(K["words"][0] + 4), tick(2400), 0.06, 0.3)
    panned_whoosh(sec(K["words"][1]) - 0.06, 0.32, 1200, 5200, 0.16, -0.9, 0.2, "whoosh: RUNNER")
    mix(SFX, sec(K["words"][2] + 6), lock_sound(), 0.3, 0.0, send=0.2, label="lock: LIST LOCKS")
    mix(SFX, sec(K["words"][3] + 6), blip(note("A6"), note("A6") * 0.98, 0.14, 0.06), 0.07, 0.4, send=0.4, label="blip: radar")
    for d in (0, 5, 10):
        mix(SFX, sec(K["words"][4] + d), bell(note("B6"), 0.6, 0.18), 0.07 - 0.015 * (d // 5), 0.0, send=0.4)
    CUES.append({"t": round(sec(K["words"][4]), 3), "frame": K["words"][4], "sfx": "ping: PING"})

    for i, f in enumerate(C["lines"]):
        mix(SFX, sec(f), swish(0.16), 0.08, -0.5, label="swish: " + ["Order.", "Fetch.", "Settle."][i])
    mix(SFX, sec(C["lines"][2] + 4), mallet(note("F#6"), 0.5, 0.2), 0.11, -0.4, send=0.4)
    for j in range(20):
        mix(SFX, sec(C["countStart"]) + j * (sec(C["countEnd"]) - sec(C["countStart"])) / 20, tick(2600 + 50 * j), 0.025, 0.4)
    CUES.append({"t": round(sec(C["countStart"]), 3), "frame": C["countStart"], "sfx": "count: Rs 0 to Rs 3,300"})
    for f in C["tags"]:
        mix(SFX, sec(f), blip(note("D6") * 1.2, note("D6"), 0.09, 0.035), 0.08, 0.45)
    for off, nm, g in ((0.0, "D6", 0.13), (0.0, "F#6", 0.08), (0.09, "A6", 0.08)):
        mix(SFX, sec(C["countEnd"]) + off, bell(note(nm), 1.2, 0.5), g, 0.4, send=0.4)
    CUES.append({"t": round(sec(C["countEnd"]), 3), "frame": C["countEnd"], "sfx": "chime: SETTLED"})

    td = sec(TL["full"]) - sec(TL["start"])
    panned_whoosh(sec(TL["start"]), td + 0.1, 600, 4800, 0.26, -0.7, 0.5, "whoosh: tile wipe")
    for j in range(24):
        mix(SFX, sec(TL["start"]) + j * td / 24, tick(1800 + 90 * j), 0.03, -0.6 + 0.05 * j)

    sn = int(0.7 * SR)
    shimmer = svf(noise(sn), lambda t: 3000 * (9000 / 3000) ** (t / 0.7), q=3.0)
    shimmer = [v * (1 - i / sn) ** 1.5 for i, v in enumerate(shimmer)]
    mix(SFX, sec(E["logo"]), shimmer, 0.1, 0.0, send=0.5, label="shimmer: logo assembles")
    for nm, g, d in (("D5", 0.22, 0.0), ("A5", 0.16, 0.02), ("F#6", 0.12, 0.05), ("E6", 0.07, 0.08)):
        mix(SFX, END_HIT + d, bell(note(nm), 2.5, 1.0), g, 0.0, send=0.55)
    mix(SFX, END_HIT, impact(0.5), 0.22, 0.0, send=0.4)
    CUES.append({"t": round(END_HIT, 3), "frame": E["chime"], "sfx": "CHIME: logo"})
    typing(sec(E["word"]), 9, 1 / 1.4, gain=0.05, pan=0.1, label="typing: bite size")
    mix(SFX, sec(E["tagline"]), swish(0.16), 0.07, 0.0, label="swish: Any other orders?")
    chat_ding(sec(E["tagline"]) + 0.15, pan=0.0)
    mix(SFX, sec(E["url"]), blip(note("A6") * 1.2, note("A6"), 0.1, 0.04), 0.07, 0.0, send=0.2, label="pop: packs line")


# --- reverb, ducking, master ---------------------------------------------------------

def reverb(x, wet_l, wet_r):
    """Small Schroeder room: four damped combs into two allpasses per side."""
    scale = SR / 44100
    for side, out, spread in ((0, wet_l, 0), (1, wet_r, 23)):
        combs = [int((d + spread) * scale) for d in (1557, 1617, 1491, 1422)]
        acc = [0.0] * N
        for d in combs:
            line = [0.0] * d
            idx, filt = 0, 0.0
            for i in range(N):
                yv = line[idx]
                filt = yv * 0.72 + filt * 0.28
                line[idx] = x[i] + filt * 0.8
                idx += 1
                if idx == d:
                    idx = 0
                acc[i] += yv
        for d in (int((556 + spread) * scale), int((225 + spread) * scale)):
            line = [0.0] * d
            idx = 0
            for i in range(N):
                bv = line[idx]
                v = acc[i]
                yv = -v + bv
                line[idx] = v + bv * 0.5
                idx += 1
                if idx == d:
                    idx = 0
                acc[i] = yv
        for i in range(N):
            out[i] += acc[i] * 0.06


def duck_curve():
    """Music dips under the big hits so the effects lead."""
    if "duck" in T:
        hits = [sec(f) for f in T["duck"]]
    else:
        hits = [sec(T["chat"]["wipeFull"]), sec(T["split"]["pullStart"]), sec(T["split"]["lock"]),
                sec(T["split"]["stamp"]), sec(T["packs"]["irisFull"]), sec(T["packs"]["toggle"])]
    g = [1.0] * N
    for h in hits:
        i0 = int(h * SR)
        for k in range(int(0.5 * SR)):
            i = i0 + k
            if i >= N:
                break
            a = min(1.0, k / (0.004 * SR))
            g[i] = min(g[i], 1 - 0.42 * a * exp(-k / SR / 0.16))
    return g


def main():
    build_music()
    if T.get("variant") == "app":
        build_sfx_app()
    elif T.get("variant") == "ref":
        build_sfx_ref()
    elif T.get("variant") == "notes":
        build_sfx_notes()
    else:
        build_sfx()

    duck = duck_curve()
    ml, mr = MUS
    sl, sr_ = SFX
    wl, wr = buf(), buf()
    reverb(SEND, wl, wr)

    fade_start = sec(T["end"]["fadeStart"])
    out_l = [0.0] * N
    out_r = [0.0] * N
    for i in range(N):
        t = i / SR
        mg = 0.55 * duck[i]
        if t > fade_start:  # music bed bows out under the end chime
            mg *= max(0.0, 1 - (t - fade_start) / (DUR - 0.25 - fade_start)) ** 1.4
        out_l[i] = ml[i] * mg + sl[i] + wl[i]
        out_r[i] = mr[i] * mg + sr_[i] + wr[i]

    # Look-ahead peak limiter: gain ramps down over 2 ms *before* a peak and
    # recovers over 150 ms, so the impacts are tamed without clicks.
    thr = 0.62
    need = [min(1.0, thr / max(1e-9, abs(out_l[i]), abs(out_r[i]))) for i in range(N)]
    att = 1.0 / (0.002 * SR)
    rel = 1.0 / (0.15 * SR)
    g = 1.0
    for i in range(N - 1, -1, -1):
        g = min(need[i], g + att)
        need[i] = g
    g = 1.0
    for i in range(N):
        g = min(need[i], g + rel)
        out_l[i] *= g
        out_r[i] *= g

    # Clean edges: 8 ms fade-in, 0.7 s tail fade to true digital silence 50 ms before the end.
    for i in range(N):
        t = i / SR
        g = min(1.0, t / 0.008)
        if t > DUR - 0.75:
            g *= max(0.0, 1 - (t - (DUR - 0.75)) / 0.7) ** 2
        out_l[i] *= g
        out_r[i] *= g

    peak = max(max(abs(v) for v in out_l), max(abs(v) for v in out_r))
    target = 10 ** (-1.5 / 20)  # -1.5 dBFS sample peak
    k = target / peak

    frames = array.array("h", bytes(2 * 2 * N))
    r = rng.random
    for i in range(N):
        for ch, src in ((0, out_l), (1, out_r)):
            v = src[i] * k * 32767 + (r() - r())  # TPDF dither
            frames[2 * i + ch] = max(-32768, min(32767, int(round(v))))

    path = os.path.join(ROOT, OUT_WAV)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames.tobytes())

    rms = math.sqrt(sum((out_l[i] * k) ** 2 + (out_r[i] * k) ** 2 for i in range(0, N, 4)) / (N / 2))
    CUES.sort(key=lambda c: c["t"])
    with open(os.path.join(ROOT, OUT_CUES), "w", encoding="utf-8") as fh:
        json.dump({"sample_rate": SR, "samples": N, "seconds": N / SR, "cues": CUES}, fh, indent=1)
    print(f"wrote {path}")
    print(f"  {N} samples = {N / SR:.3f} s, peak -1.5 dBFS (pre-gain {20 * math.log10(peak):.2f} dB), "
          f"rms {20 * math.log10(rms):.1f} dBFS, {len(CUES)} cues")


if __name__ == "__main__":
    main()
