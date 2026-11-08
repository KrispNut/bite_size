"""
Turns the Blender renders into transparent Lottie frames.

  tools/blender/render/ref.png        empty flat sheet, same lights
  tools/blender/render/main_###.png   hand on the sheet (Cycles)
  tools/blender/render/mask_###.png   hand coverage (Workbench, antialiased)
  video/folds/hand_###.png            fabric folds (from polish_frames.py) - optional

For each frame:
  hand   = the Blender hand, cut out with its mask, edge colours bled from the solid hand
  shadow = how much darker the render is than the empty sheet (the hand's real shadow)
  folds  = the fabric layer of video/folds (its old hand removed), multiplied in
Output: composed/light/ and composed/dark/ hand_###.png (RGBA, same size as the renders), then
  python pack_lottie.py
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
RENDER = os.path.join(HERE, "render")
FOLDS = os.path.join(HERE, "video", "folds")
OUT = os.path.join(HERE, "composed", "light")
# dark mode: on a dark screen the folds read as light creases (cloth catching the light);
# the hand's shadow stays dark
OUT_DARK = os.path.join(HERE, "composed", "dark")
DARK_FOLDS = 0.75          # how bright the creases get on a dark screen
N = 149
FOLD_SHIFT = 0           # the hand follows the video's own timeline

def load(path):
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255

def blur(a, r):
    k = np.arange(-int(3 * r + 1), int(3 * r + 1) + 1, dtype=np.float32)
    k = np.exp(-k * k / (2 * r * r)); k /= k.sum()
    p = len(k) // 2
    a = np.pad(a.astype(np.float32), ((p, p), (0, 0)), mode="edge")
    a = sum(k[i] * a[i:i + a.shape[0] - 2 * p] for i in range(len(k)))
    a = np.pad(a, ((0, 0), (p, p)), mode="edge")
    return sum(k[i] * a[:, i:i + a.shape[1] - 2 * p] for i in range(len(k)))

def lum(rgb):
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722

FOLD_FRAMES = range(16, 47)      # press, pull, release (video frames): the only frames with folds

def fold_layer(f, shape):
    """the fabric folds from the polished frames, with their old hand (and the hole it
    leaves) filled in from the surrounding fabric. Outside the fold frames that layer is
    just the old hand's shadow, which the Blender render replaces, so it isn't used."""
    v = f - FOLD_SHIFT
    path = os.path.join(FOLDS, f"hand_{v:03d}.png")
    if v not in FOLD_FRAMES or not os.path.exists(path):
        z = np.zeros(shape, np.float32)
        return z, z
    fr = load(path)
    if fr.shape[:2] != shape:
        fr = np.asarray(Image.fromarray((fr * 255).astype(np.uint8)).resize(
            (shape[1], shape[0]), Image.BILINEAR)).astype(np.float32) / 255
    rgb, a = fr[..., :3], fr[..., 3]
    hand = ((rgb.max(2) - rgb.min(2)) > 0.06) & (a > 0.02)
    old_hand = blur(hand.astype(np.float32), 4) > 0.02           # its outline, with a margin
    folds = np.where((rgb.mean(2) < 0.5) & ~old_hand, a, 0.0)
    keep = (~old_hand).astype(np.float32)
    fill = blur(folds * keep, 10) / np.maximum(blur(keep, 10), 1e-3)
    folds = np.where(old_hand, fill, folds)
    # Rebuild the fabric from the video's folds: crisp crease lines (high-pass, sharpened)
    # over one wide, soft haze. The video's own faint haze stops at a hard blobby edge
    # (its noise floor); a wide blur of the folds has no edge at all.
    crease = np.clip(folds - blur(folds, 12), 0, 1)
    crease = np.clip(crease + 1.3 * (crease - blur(crease, 1.5)), 0, 1) * 1.5
    haze = blur(folds, 28) * 1.1
    # (light mode: creases + haze, dark mode: mostly the creases; a haze turns into a glow on dark)
    return np.clip(1 - (1 - crease) * (1 - haze), 0, 1), np.clip(crease * 3.2 + haze * 0.1, 0, 1)

def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(OUT_DARK, exist_ok=True)
    ref = load(os.path.join(RENDER, "ref.png"))[..., :3]
    H, W = ref.shape[:2]
    R = lum(ref)
    for f in range(N):
        main_p = os.path.join(RENDER, f"main_{f:03d}.png")
        folds, folds_dark = fold_layer(f, (H, W))
        if not os.path.exists(main_p):
            # hidden stretch: nothing drawn (folds are already gone there too)
            out = np.zeros((H, W, 4), np.float32)
            out[..., 3] = folds
            Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, f"hand_{f:03d}.png"))
            dark = np.zeros((H, W, 4), np.float32)
            dark[..., :3] = 1.0
            dark[..., 3] = folds_dark * DARK_FOLDS
            Image.fromarray((dark * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT_DARK, f"hand_{f:03d}.png"))
            continue
        F = load(main_p)[..., :3]
        mask_p = os.path.join(RENDER, f"mask_{f:03d}.png")
        rough = load(mask_p)[..., 0] if os.path.exists(mask_p) else None
        # The quick mask render outlines the hand a few px differently from the real
        # render, so take the actual edge from the render itself: how pink each pixel
        # is compared with the empty sheet. The mask only says roughly where to look.
        pink = (F[..., 0] - F[..., 1]) - (ref[..., 0] - ref[..., 1])
        M = np.clip((pink - 0.03) / 0.17, 0, 1)
        if rough is None:
            # no mask render: fill holes in the hand (bright highlights aren't pink) by flooding
            # the background in from the frame edge; whatever it can't reach is hand
            from PIL import ImageDraw
            solid = Image.fromarray(((M > 0.5) * 255).astype(np.uint8)).convert("L")
            bg = solid.copy()
            for seed in ((0, H - 1), (W - 1, H - 1), (W // 2, H - 1), (0, H // 2), (W - 1, H // 2)):
                if bg.getpixel(seed) == 0:
                    ImageDraw.floodfill(bg, seed, 128)
            inside = np.asarray(bg) != 128
            rough = blur(inside.astype(np.float32), 1.0)
        else:
            M = M * (blur(rough, 3) > 0.02)
        # highlights on the clay aren't pink: inside the mask (away from its edge) it's all hand
        if rough is not None:
            inner = np.clip((blur(rough, 2) - 0.9) / 0.08, 0, 1)
            M = np.maximum(M, inner)

        # -- hand colour: solid inside; the soft edge takes the colour of the solid hand next to it
        core = (M > 0.98).astype(np.float32)
        w = blur(core, 2.5)
        bled = np.dstack([blur(F[..., c] * core, 2.5) for c in range(3)]) / np.maximum(w[..., None], 1e-4)
        hand_rgb = np.where((core > 0)[..., None], F, np.where((w > 0.02)[..., None], bled, F))

        # -- the hand's shadow on the sheet: how much darker than the empty sheet
        shade = np.clip(1 - lum(F) / np.maximum(R, 1e-3), 0, 1)
        # the mask and the render outline the hand a hair differently, and the
        # clay's lit rim reads as "no shadow": treat a thin band around the hand
        # as unknown too, and carry the surrounding shadow in under it
        near = blur(M, 2.5) > 0.01
        outside = (~near).astype(np.float32)
        filled = blur(shade * outside, 5) / np.maximum(blur(outside, 5), 1e-3)
        # in that band keep whichever is darker: the real contact shadow between the
        # fingers stays dark instead of showing up as light slivers
        shade = np.where(near, np.maximum(filled, shade), shade) * 0.8      # a touch lighter: airy
        # render noise floor; keep the soft shadow smooth
        shade = np.clip(shade - 0.012, 0, 1)
        lo = np.minimum(shade, 0.06)
        shade = (shade - lo) + blur(lo, 6)

        # -- fabric = shadow and folds, both darkening
        fab = 1 - (1 - shade) * (1 - folds)
        A = M + (1 - M) * fab
        rgb = (M[..., None] * hand_rgb) / np.maximum(A[..., None], 1e-4)    # fabric colour is black
        out = np.dstack([np.clip(rgb, 0, 1), A])
        out[A < 0.004] = 0
        Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT, f"hand_{f:03d}.png"))

        # dark mode: shadow (black) under light creases (white), hand on top
        lf = folds_dark * DARK_FOLDS
        Ad = 1 - (1 - shade) * (1 - lf)                       # fabric coverage
        fab_rgb = (lf / np.maximum(Ad, 1e-4))[..., None] * np.ones(3)   # white share of it
        A2 = M + (1 - M) * Ad
        rgb2 = (M[..., None] * hand_rgb + ((1 - M) * Ad)[..., None] * fab_rgb) / np.maximum(A2[..., None], 1e-4)
        out2 = np.dstack([np.clip(rgb2, 0, 1), A2])
        out2[A2 < 0.004] = 0
        Image.fromarray((out2 * 255 + 0.5).astype(np.uint8), "RGBA").save(os.path.join(OUT_DARK, f"hand_{f:03d}.png"))
    print("composed", N, "frames ->", OUT)

if __name__ == "__main__":
    main()
