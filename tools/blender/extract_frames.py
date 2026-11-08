"""
Cuts the hand + fabric out of the reference video as transparent PNG frames.

For every frame it rebuilds a clean "plate" of the page behind the hand (the app UI from a
frame where nothing covers it, shifted by the measured scroll of each row), then:
  - hand pixels  = pink that isn't in the plate  -> kept in full color (unmixed from the plate)
  - everything else that differs from the plate  -> black (darker) or white (lighter) overlay
                                                  with alpha = how much darker / lighter
so the folds and shadows work on any light background.

Run:  python extract_frames.py [video.mp4]     -> video/cutout/hand_###.png  (572 x 380, 30 fps)
      (default video: video/reference.mp4, the cropped reference)
"""
import os, subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageFilter

X0, Y0, CW, CH = 432, 127, 572, 380        # crop in video px (phone screen, from the island down)
BG = 242.0
PLATE_FRAME, PLATE_SHIFT = 70, 215         # clean UI frame and its scroll (video px, rows moved up)

# measured content scroll (video px) of the "Popular Food" row, by video frame
CONTENT_PX = {28: 0, 29: -1, 30: -4, 31: -10, 32: -17, 33: -27, 34: -39, 35: -53, 36: -69,
              37: -87, 38: -107, 39: -128, 40: -151, 41: -174, 42: -197, 43: -215, 44: -226,
              45: -232, 46: -234, 47: -234, 48: -232, 49: -229, 50: -226, 51: -223, 52: -220,
              53: -217, 54: -216, 55: -214, 57: -213, 92: -215, 93: -213, 94: -211, 95: -207,
              96: -203, 97: -197, 98: -191, 99: -183, 100: -175, 101: -165, 102: -155,
              103: -143, 104: -131, 105: -118, 106: -104, 107: -89, 108: -74, 109: -58,
              110: -42, 111: -26, 112: -12, 113: 0, 114: 7, 115: 11, 116: 13, 117: 13, 118: 11,
              119: 9, 120: 7, 121: 5, 122: 3, 123: 1, 124: 0, 125: -1, 128: -1, 133: 0, 148: 0}
# rows lower on the page follow later (fabric ripple): (rest y in video px, delay in frames)
ROW_DELAY = [(300, -1.5), (345, -1), (482, 0), (545, 2), (650, 4), (790, 4), (950, 6)]
PTS = sorted(CONTENT_PX.items())

def interp(x, pts):
    xs, ys = zip(*pts)
    return float(np.interp(x, xs, ys))

def content_offset(f, yc):
    return interp(f - interp(yc, ROW_DELAY), [(0, 0)] + PTS)

def load(d, f):
    return np.asarray(Image.open(os.path.join(d, f"f{f + 1:03d}.png")).convert("RGB")).astype(np.float32)

def blur(a, r):
    """separable gaussian blur of a float image (sigma = r px)"""
    k = np.arange(-int(3 * r + 1), int(3 * r + 1) + 1, dtype=np.float32)
    k = np.exp(-k * k / (2 * r * r)); k /= k.sum()
    a = a.astype(np.float32)
    p = len(k) // 2
    a = np.pad(a, ((p, p), (0, 0)), mode="edge")
    a = sum(k[i] * a[i:i + a.shape[0] - 2 * p] for i in range(len(k)))
    a = np.pad(a, ((0, 0), (p, p)), mode="edge")
    return sum(k[i] * a[:, i:i + a.shape[1] - 2 * p] for i in range(len(k)))

def blur_y(a, length):
    """box blur along y over `length` px (scroll motion blur)"""
    r = max(1, int(round(length / 2)))
    c = np.pad(a, ((r + 1, r), (0, 0)), mode="edge").cumsum(0)
    return (c[2 * r + 1:] - c[:-2 * r - 1]) / (2 * r + 1)

def reconstruct(mask, seed):
    """connected part of mask reachable from seed"""
    cur = seed & mask
    while True:
        nxt = cur.copy()
        nxt[1:] |= cur[:-1]; nxt[:-1] |= cur[1:]; nxt[:, 1:] |= cur[:, :-1]; nxt[:, :-1] |= cur[:, 1:]
        nxt &= mask
        if (nxt == cur).all(): return cur
        cur = nxt

def dilate(m, r):
    """grow a boolean mask by ~r px (box-sum via integral image; O(1) per pixel)"""
    m = m.astype(np.float32)
    c = np.pad(m, ((r + 1, r), (r + 1, r))).cumsum(0).cumsum(1)
    h, w = m.shape
    box = c[2 * r + 1:2 * r + 1 + h, 2 * r + 1:2 * r + 1 + w] - c[:h, 2 * r + 1:2 * r + 1 + w]         - c[2 * r + 1:2 * r + 1 + h, :w] + c[:h, :w]
    return box > 0.5

def main(video, out_dir):
    tmp = tempfile.mkdtemp()
    subprocess.run(["ffmpeg", "-v", "error", "-i", video, os.path.join(tmp, "f%03d.png")], check=True)
    n = len([p for p in os.listdir(tmp) if p.endswith(".png")])
    os.makedirs(out_dir, exist_ok=True)

    # content plate in "rest" coordinates: content row yc lives at screen row yc - PLATE_SHIFT in the plate frame
    pf = load(tmp, PLATE_FRAME)
    H = pf.shape[0]
    plate = np.full((H + PLATE_SHIFT, pf.shape[1], 3), BG, np.float32)
    top = Y0                                               # rows above the island bottom are status bar, not content
    plate[top + PLATE_SHIFT:] = pf[top:]

    ys = np.arange(Y0, Y0 + CH, dtype=np.float32)
    BAND = 16
    prev_rows = None
    for f in range(n):
        Ffull = load(tmp, f)
        F = Ffull[Y0:Y0 + CH, X0:X0 + CW]
        chroma_f = F[..., 0] - F[..., 1]
        # ---- scroll of each band of rows: start from the model, then refine by matching the plate
        rows = np.array([content_offset(f, v) for v in ys], np.float32)      # approx offset per screen row
        for _ in range(3):
            rows = np.array([content_offset(f, y - o) for y, o in zip(ys, rows)], np.float32)
        moving = any(abs(content_offset(f, y) - content_offset(f - 1, y)) > 0.3 for y in ys[::40])
        if moving:
            gl = F.mean(2)
            keep = np.abs(chroma_f) < 25                                     # ignore the hand
            meas = []
            for b0 in range(0, CH - BAND + 1, BAND):
                pred = rows[b0 + BAND // 2]
                yb = ys[b0:b0 + BAND]
                best, cost0 = None, None
                for sft in np.arange(pred - 30, pred + 30.5, 1.0):
                    yc = np.clip((yb - sft).astype(int), 0, plate.shape[0] - 1)
                    pb = plate[yc, X0:X0 + CW:2].mean(2)
                    if pb.std() < 4: continue                                # nothing to match on
                    m = keep[b0:b0 + BAND, ::2]
                    c = np.abs(gl[b0:b0 + BAND, ::2] - pb)[m].mean() if m.any() else 1e9
                    if cost0 is None or c < cost0: best, cost0 = sft, c
                meas.append((b0 + BAND // 2, best))
            good = [(y, v) for y, v in meas if v is not None]
            if len(good) >= 2:
                gy, gv = zip(*good)
                gv = np.array(gv)
                # reject outliers against the model, then interpolate between measured bands
                pr = np.array([rows[y] for y in gy])
                ok = np.abs(gv - pr) < 28
                if ok.sum() >= 2:
                    rows = rows + np.interp(np.arange(CH), np.array(gy)[ok], (gv - pr)[ok])
        yc = ys - rows
        vel = 0.0 if prev_rows is None else float(np.median(np.abs(rows - prev_rows)))
        prev_rows = rows
        y0 = np.clip(np.floor(yc).astype(int), 0, plate.shape[0] - 2)
        t = (yc - y0)[:, None, None]
        P = (plate[y0] * (1 - t) + plate[y0 + 1] * t)[:, X0:X0 + CW]
        if vel > 1.5:                                                        # motion blur of the scroll
            P = np.dstack([blur_y(P[..., c], vel * 0.5) for c in range(3)])

        # ---- hand: chroma above the plate, connected to the top edge (where the hand comes in)
        chroma = chroma_f - (P[..., 0] - P[..., 1])
        ah = np.clip((chroma - 10) / 16, 0, 1)
        core = ah > 0.5
        seed = np.zeros_like(core); seed[:6] = core[:6]
        if seed.any():
            ah *= dilate(reconstruct(core, seed), 2)
        else:
            ah[:] = 0
        hand_near = dilate(ah > 0.1, 70)

        # ---- fabric / shadows: luminance against the plate
        Fl, Pl = F.mean(2), P.mean(2)
        dark = np.clip(1 - Fl / np.maximum(Pl, 1), 0, 1)
        light = np.clip((Fl - Pl) / np.maximum(255 - Pl, 1), 0, 1)
        dark = np.clip(dark - 0.012, 0, 1) / 0.988         # video compression noise floor
        light = np.clip(light - 0.04, 0, 1)
        # where the plate has UI (text, icons) the estimate is unreliable: blend in a fill from the surroundings
        uim = ((Pl < 232) | (Pl > 247)).astype(np.float32)        # dark text/icons and white chips/cards
        w_ui = np.clip(blur(uim, 2.5 + vel * 0.4) * 5, 0, 1)
        valid = 1 - np.clip(blur(uim, 1.5) * 4, 0, 1)
        fill = blur(dark * valid, 10) / np.maximum(blur(valid, 10), 1e-3)
        dark = dark * (1 - w_ui) + fill * w_ui
        light = light * (1 - np.clip(blur(uim, 6) * 6, 0, 1))
        dark, light = blur(dark, 0.8), blur(light, 0.8)
        # folds only exist while the fabric is grabbed; otherwise keep just the hand's own shadow
        if not (15 <= f <= 46):
            near = np.clip(blur((ah > 0.1).astype(np.float32), 22) * 10, 0, 1)
            dark, light = dark * near, light * near
        if 46 < f < 99:
            dark[:] = 0; light[:] = 0
        # soft fade at the bottom (the page's chips/cards scroll in there) and trim the screen edges
        yy = np.arange(CH, dtype=np.float32)[:, None]
        fade = np.clip((CH - 12 - yy) / 40, 0, 1)
        dark, light = dark * fade, light * fade
        edge = np.ones(CW, np.float32); edge[:5] = 0; edge[-5:] = 0
        dark, light = dark * edge, light * edge
        # the island's bottom edge sits in the top rows of the crop: never fabric
        topfade = np.clip((yy - 2) / 4, 0, 1)
        dark, light = dark * topfade, light * topfade
        # while the folds let go, keep only the crease lines: broad smudges left
        # where the page's icons and text were filled in would flash for a frame
        if 36 <= f <= 46:
            k = min(1.0, (f - 35) / 4)
            lines = np.clip((dark - blur(dark, 10)) * 1.6, 0, 1)
            dark = dark * (1 - k) + np.minimum(dark, lines) * k
            light = light * (1 - k)

        # ---- compose: hand over its shadow
        a_s = np.where(dark >= light, dark, light)
        S = np.where((dark >= light)[..., None], 0.0, 255.0) * np.ones(3, np.float32)
        Hc = np.clip((F - (1 - ah[..., None]) * P) / np.maximum(ah[..., None], 0.05), 0, 255)
        Hc = np.where(ah[..., None] > 0.9, F, Hc)
        ah = ah * edge
        a = ah + (1 - ah) * a_s
        C = (ah[..., None] * Hc + ((1 - ah) * a_s)[..., None] * S) / np.maximum(a[..., None], 1e-4)
        a = np.where(a < 0.01, 0, a)
        rgba = np.dstack([np.clip(C, 0, 255), a * 255]).astype(np.uint8)
        Image.fromarray(rgba, "RGBA").save(os.path.join(out_dir, f"hand_{f:03d}.png"))
    print("frames:", n)

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "video", "reference.mp4"), os.path.join(here, "video", "cutout"))
