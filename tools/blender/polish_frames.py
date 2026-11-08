"""
Cleans up and sharpens the cut-out frames from extract_frames.py.

  1. De-flickers the fabric: a 3-frame temporal median of the folds/shadows (never the hand).
     A median of three leaves steady motion exactly as it is and only removes one-frame pops,
     which is what the video's compression noise looks like in the soft shading.
  2. Renders at 2x: hand and fabric scaled as separate layers, then combined, so the outline
     never rings into a halo.
  3. Sharpens the hand only (unsharp mask); the fabric stays soft, as cloth shading should.
  4. Smooths the faint haze around the folds (no hard-edged islands), drops white residue.

Run:  python polish_frames.py      video/cutout/hand_###.png -> video/folds/hand_###.png
"""
import os
import numpy as np
from PIL import Image, ImageFilter

SCALE = 2

def fblur(a, r):
    """separable gaussian blur of a float image (sigma = r px), no 8-bit banding"""
    k = np.arange(-int(3 * r + 1), int(3 * r + 1) + 1, dtype=np.float32)
    k = np.exp(-k * k / (2 * r * r)); k /= k.sum()
    p = len(k) // 2
    a = np.pad(a.astype(np.float32), ((p, p), (0, 0)), mode="edge")
    a = sum(k[i] * a[i:i + a.shape[0] - 2 * p] for i in range(len(k)))
    a = np.pad(a, ((0, 0), (p, p)), mode="edge")
    return sum(k[i] * a[:, i:i + a.shape[1] - 2 * p] for i in range(len(k)))

def load(path):
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255

def main():
    here = os.path.dirname(os.path.abspath(__file__))
    src, dst = os.path.join(here, "video", "cutout"), os.path.join(here, "video", "folds")
    os.makedirs(dst, exist_ok=True)
    names = sorted(n for n in os.listdir(src) if n.startswith("hand_"))
    frames = [load(os.path.join(src, n)) for n in names]

    def mask_img(m):
        return Image.fromarray((m * 255).astype(np.uint8))

    def split(fr):
        rgb, a = fr[..., :3], fr[..., 3]
        # the hand is coloured; the fabric layer is pure black (shadow) or white (highlight)
        sat = rgb.max(2) - rgb.min(2)
        core = (sat > 0.06) & (a > 0.9)
        # the hand's soft edge has unreliable colour: count 2px around the solid hand as hand
        near = np.asarray(mask_img(core).filter(ImageFilter.MaxFilter(5))) > 127
        hand = ((sat > 0.06) | near) & (a > 0.02)
        signed = np.where(rgb.mean(2) < 0.5, a, -a) * ~hand
        return hand, signed, core

    def bleed(rgb, core, radius=2):
        """edge pixels take the colour of the solid hand next to them (no fringe)"""
        w = np.asarray(mask_img(core).filter(ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255
        out = rgb.copy()
        for c in range(3):
            ch = np.asarray(Image.fromarray((rgb[..., c] * core * 255).astype(np.uint8)).filter(
                ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255
            out[..., c] = np.where(w > 0.03, ch / np.maximum(w, 1e-3), rgb[..., c])
        return np.clip(out, 0, 1)

    parts = [split(fr) for fr in frames]
    for i, (name, fr) in enumerate(zip(names, frames)):
        hand, signed, core = parts[i]
        if 0 < i < len(frames) - 1:
            near_hand = hand | parts[i - 1][0] | parts[i + 1][0]
            med = np.median(np.stack([parts[i - 1][1], signed, parts[i + 1][1]]), axis=0)
            signed = np.where(near_hand, signed, med)
        # no white highlight hugging the hand: that's separation residue, it reads as a rim
        rim = np.asarray(mask_img(hand).filter(ImageFilter.MaxFilter(9))) > 127
        signed = np.where(rim & (signed < 0), 0.0, signed)
        # No white highlights: on a light screen they're invisible except where
        # they're residue (they showed as white dashes).
        signed = np.maximum(signed, 0.0)
        # The broad haze around the folds is only a few % dark; the cut-out's noise
        # floor chopped it into islands with hard edges. Keep the crease lines as
        # they are and replace the faint part with a wide, soft version of itself.
        lo = np.minimum(signed, 0.06)
        signed = (signed - lo) + fblur(lo, 9)
        # soft fade at the sides instead of a hard trim
        ramp = np.clip(np.arange(signed.shape[1], dtype=np.float32) / 24, 0, 1)
        signed = signed * np.minimum(ramp, ramp[::-1])[None, :]
        a_f = np.abs(signed)
        h, w = a_f.shape
        size = (w * SCALE, h * SCALE)

        def up(x, how):
            return np.asarray(Image.fromarray((np.clip(x, 0, 1) * 255 + 0.5).astype(np.uint8)).resize(
                size, how)).astype(np.float32) / 255

        # Hand and fabric are scaled as two separate layers, each with smooth
        # colour across the hand's outline, and only combined at 2x. Scaling them
        # together puts a hard pink-to-black jump at the outline, which rings
        # into a pale halo.
        # -- hand: solid colour bled a few px outward, transparency from coverage
        edge = hand & ~core
        hand_c = np.where(core[..., None], fr[..., :3], bleed(fr[..., :3], core, radius=4))
        seen = (fr[..., :3].max(2) - fr[..., :3].min(2)) * fr[..., 3]
        solid = hand_c.max(2) - hand_c.min(2)
        coverage = np.clip(seen / np.maximum(solid, 0.05), 0, 1)
        hand_a = np.where(hand, np.where(edge, np.minimum(fr[..., 3], coverage), fr[..., 3]), 0.0)
        # -- fabric: carries on under the hand's edge so there's no gap at the outline
        fab_c = np.where(signed >= 0, 0.0, 1.0)
        out_mask = (~hand).astype(np.float32)
        under = np.asarray(Image.fromarray((a_f * out_mask * 255).astype(np.uint8)).filter(
            ImageFilter.GaussianBlur(3))).astype(np.float32) / 255
        norm = np.asarray(mask_img(out_mask).filter(ImageFilter.GaussianBlur(3))).astype(np.float32) / 255
        fab_a = np.where(hand, under / np.maximum(norm, 0.05), a_f)
        fab_c = np.where(hand, 0.0, fab_c)

        Hc = np.dstack([up(hand_c[..., c], Image.LANCZOS) for c in range(3)])
        Ha = up(hand_a, Image.BILINEAR)
        Fa = up(fab_a, Image.BILINEAR)
        Fc = up(fab_c, Image.BILINEAR)[..., None] * np.ones(3)
        # sharpen only the inside of the hand, never its outline
        inner = np.asarray(mask_img(core).filter(ImageFilter.MinFilter(5)))
        hand_big = np.asarray(Image.fromarray(inner).resize(size, Image.BILINEAR).filter(
            ImageFilter.GaussianBlur(2))).astype(np.float32)[..., None] / 255
        sharp = np.asarray(Image.fromarray((np.clip(Hc, 0, 1) * 255).astype(np.uint8)).filter(
            ImageFilter.UnsharpMask(radius=1.6, percent=90, threshold=1))).astype(np.float32) / 255
        Hc = np.clip(sharp * hand_big + Hc * (1 - hand_big), 0, 1)
        # hand over fabric
        A = Ha + (1 - Ha) * Fa
        out_rgb = (Ha[..., None] * Hc + ((1 - Ha) * Fa)[..., None] * Fc) / np.maximum(A[..., None], 1e-4)
        out = np.dstack([np.clip(out_rgb, 0, 1), A])
        out[A < 0.004] = 0
        Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(dst, name))
    print("polished", len(names), "frames at", SCALE, "x")

if __name__ == "__main__":
    main()
