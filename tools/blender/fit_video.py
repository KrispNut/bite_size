"""
Fits the Blender hand to the reference video, frame by frame.

Inputs:  video/cutout/hand_###.png      the hand cut out of the video (572x380, from extract_frames.py)
         tools/blender/fit/rest_###.png  Blender silhouettes at rest, curl 0/25/50/75/100 (video_anim.py --masks)
For each video frame: the curl, rotation about the shoulder pivot, scale and offset that make
the Blender silhouette overlap the video hand best (IoU), then lightly smoothed over time.
Output:  tools/blender/fit/fit.json   ->  video_anim.py --fit tools/blender/fit/fit.json
"""
import json
import math
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FIT = os.path.join(ROOT, "tools", "blender", "fit")
N = 149
W, H = 572, 380
PX = 143.0                                   # pixels per world unit
PIV = (286 + 0.035 * PX, 190 - 1.48 * PX)    # shoulder pivot in pixels (PIVOT in video_anim.py)
CURLS = (0.0, 0.25, 0.5, 0.75, 1.0)
D = 4                                        # work at 1/4 resolution for speed
HOVER = 0.44

def video_mask(f):
    a = np.asarray(Image.open(os.path.join(ROOT, "tools", "blender", "video", "cutout", f"hand_{f:03d}.png")).convert("RGBA")).astype(np.float32) / 255
    sat = a[..., :3].max(2) - a[..., :3].min(2)
    return ((sat > 0.08) & (a[..., 3] > 0.5)).astype(np.float32)

def rest_mask(c):
    m = np.asarray(Image.open(os.path.join(FIT, f"rest_{int(c * 100):03d}.png")).convert("L")).astype(np.float32) / 255
    return m

def transform(m, rot, s, dx, dy):
    """rotate (deg, + = hand swings left) and scale about the pivot, then shift (px, dx + = right, dy + = up)"""
    a = math.radians(rot)                    # + = hand swings left (matches video_anim.py)
    ca, sa = math.cos(a), math.sin(a)
    px, py = PIV[0] / D, PIV[1] / D
    # inverse map: output (x, y) -> input
    ix = lambda x, y: ((x - px - dx / D) * ca + (y - py + dy / D) * sa) / s + px
    iy = lambda x, y: (-(x - px - dx / D) * sa + (y - py + dy / D) * ca) / s + py
    a0 = ca / s; b0 = sa / s; c0 = ix(0, 0)
    d0 = -sa / s; e0 = ca / s; f0 = iy(0, 0)
    img = Image.fromarray((m * 255).astype(np.uint8))
    out = img.transform(img.size, Image.AFFINE, (a0, b0, c0, d0, e0, f0), resample=Image.BILINEAR)
    return np.asarray(out).astype(np.float32) / 255

def small(m):
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize((W // D, H // D), Image.BILINEAR)).astype(np.float32) / 255

def iou(a, b):
    inter = np.minimum(a, b).sum()
    union = np.maximum(a, b).sum()
    return inter / union if union > 0 else 0.0

def search(target, rests, start, steps):
    """coordinate descent over (curl index, rot, s, dx, dy) from `start`"""
    best = dict(start)
    score = iou(transform(rests[best["ci"]], best["rot"], best["s"], best["dx"], best["dy"]), target)
    for step in steps:
        improved = True
        while improved:
            improved = False
            for key, delta in (("rot", step["rot"]), ("dy", step["dy"]), ("dx", step["dx"]),
                               ("s", step["s"]), ("ci", 1)):
                for sign in (-1, 1):
                    cand = dict(best)
                    cand[key] = cand[key] + sign * delta
                    if key == "ci" and not 0 <= cand["ci"] < len(CURLS):
                        continue
                    if key == "s" and not 0.75 <= cand["s"] <= 1.35:
                        continue
                    sc = iou(transform(rests[cand["ci"]], cand["rot"], cand["s"], cand["dx"], cand["dy"]), target)
                    if sc > score + 1e-4:
                        best, score, improved = cand, sc, True
    return best, score

def main():
    rests = [small(rest_mask(c)) for c in CURLS]
    targets = {f: small(video_mask(f)) for f in range(N)}
    area0 = rests[0].sum()
    visible = [f for f in range(N) if targets[f].sum() > 0.04 * area0]
    print("hand visible in", len(visible), "video frames")

    # global scale + first pose: broad search on frame 0
    best0, s0 = None, -1
    for ci in (0, 1):
        for s in np.arange(0.8, 1.31, 0.05):
            for rot in range(-30, 31, 3):
                for dy in range(-200, 101, 8):
                    sc = iou(transform(rests[ci], rot, s, 0, dy), targets[0])
                    if sc > s0:
                        best0, s0 = dict(ci=ci, rot=float(rot), s=float(s), dx=0.0, dy=float(dy)), sc
    fine = [dict(rot=2, dy=4, dx=4, s=0.02), dict(rot=0.5, dy=1, dx=1, s=0.005)]
    best0, s0 = search(targets[0], rests, best0, fine)
    print("frame 0:", best0, "IoU %.3f" % s0)

    res, prev = {}, best0
    order = [f for f in visible if f <= 46] + [f for f in visible if f > 46]
    for f in order:
        start = prev if (f - 1) in res else dict(best0)
        if f > 46 and (f - 1) not in res:
            # coming back in from the top: search the drop height broadly
            cands = [search(targets[f], rests, dict(prev, ci=0, dy=float(dy)), fine) for dy in range(0, 321, 40)]
            best, sc = max(cands, key=lambda t: t[1])
        else:
            best, sc = search(targets[f], rests, start, fine)
        res[f] = dict(best, iou=sc)
        prev = best
        print(f"v{f:3d} curl {CURLS[best['ci']]:.2f} rot {best['rot']:6.1f} s {best['s']:.3f} "
              f"dx {best['dx']:6.1f} dy {best['dy']:7.1f}  IoU {sc:.3f}", flush=True)

    # smooth over time (the motion in the video is smooth; the fit has a little jitter)
    frames = sorted(res)
    def smooth_key(k, sigma=1.0):
        out = {}
        for f in frames:
            w = [(math.exp(-((g - f) ** 2) / (2 * sigma ** 2)), res[g][k]) for g in frames if abs(g - f) <= 3]
            out[f] = sum(a * v for a, v in w) / sum(a for a, _ in w)
        return out
    rot, dx, dy = smooth_key("rot"), smooth_key("dx"), smooth_key("dy")
    s_all = float(np.median([res[f]["s"] for f in frames]))      # one hand size for the whole clip
    # curl from the video's timing (a silhouette can't tell an open hand from a fist):
    # open, curls over frames 9-17, fist through the grab and pull, open when it comes back
    def ease(t): t = min(1.0, max(0.0, t)); return t * t * (3 - 2 * t)
    curl = {f: round(ease((f - 9) / 8), 3) if f <= 46 else 0.0 for f in frames}
    out = {}
    for f in frames:
        press = 0.0
        if 16 <= f <= 25:
            press = min(1.0, (f - 16) / 5) * (1 - max(0.0, (f - 22) / 3))
        out[f] = {"rot": round(rot[f], 3), "dx": round(dx[f] / PX, 4), "dy": round(dy[f] / PX, 4),
                  "s": round(s_all, 4), "curl": curl[f], "z": round(HOVER - 0.14 * press, 4),
                  "iou": round(float(res[f]["iou"]), 3)}
    json.dump({"pivot_px": PIV, "frames": out}, open(os.path.join(FIT, "fit.json"), "w"), indent=1)
    print("mean IoU %.3f, scale %.3f -> fit.json" % (np.mean([res[f]["iou"] for f in frames]), s_all))

if __name__ == "__main__":
    main()
