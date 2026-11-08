"""
Packs the composed frames (compose_frames.py) into the app's Lottie image sequences.

Each frame is cropped to its visible pixels, compressed, embedded as base64 and shown as a
one-frame image layer at its original position. Empty frames get no layer.

Run:  python pack_lottie.py          composed/light -> assets/lottie/refresh.json
                                     composed/dark  -> assets/lottie/refresh_dark.json
      python pack_lottie.py --src DIR --out NAME   one folder -> assets/lottie/NAME.json
      --png                          lossless PNG frames instead of WebP (much larger)
"""
import base64, io, json, os, sys
import numpy as np
from PIL import Image

FPS = 30
HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(os.path.dirname(os.path.dirname(HERE)), "assets", "lottie")
MARKERS = [(0, "settle"), (9, "curl"), (17, "press"), (22, "pull"), (34, "release"),
           (46, "hidden"), (98, "return"), (113, "sway"), (149, "")]

def encode(im, fmt):
    buf = io.BytesIO()
    if fmt == "webp":
        # lossy colour, near-lossless alpha: keeps the soft shadow gradients smooth
        im.save(buf, "WEBP", quality=82, method=4, alpha_quality=85)
        return "data:image/webp;base64," + base64.b64encode(buf.getvalue()).decode()
    im.save(buf, "PNG", optimize=True)           # lossless RGBA fallback (larger, works everywhere)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

def pack(src, name, fmt="webp"):
    files = sorted(f for f in os.listdir(src) if f.startswith("hand_"))
    W, H = Image.open(os.path.join(src, files[0])).size   # comp = frame size
    assets, layers = [], []
    for fname in files:
        f = int(fname[5:8])
        im = Image.open(os.path.join(src, fname)).convert("RGBA")
        a = np.asarray(im)[..., 3]
        ys, xs = np.nonzero(a > 2)
        if len(xs) == 0: continue
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        crop = im.crop((x0, y0, x1, y1))
        aid = f"img_{f:03d}"
        assets.append({"id": aid, "w": int(x1 - x0), "h": int(y1 - y0), "u": "", "p": encode(crop, fmt), "e": 1})
        layers.append({"ddd": 0, "ind": len(layers) + 1, "ty": 2, "nm": f"frame {f}", "refId": aid, "sr": 1,
                       "ks": {"o": {"a": 0, "k": 100}, "r": {"a": 0, "k": 0},
                              "p": {"a": 0, "k": [int(x0), int(y0), 0]}, "a": {"a": 0, "k": [0, 0, 0]},
                              "s": {"a": 0, "k": [100, 100, 100]}},
                       "ao": 0, "ip": f, "op": f + 1, "st": 0, "bm": 0})
    n = len(files)
    markers = [{"tm": t, "cm": nm, "dr": MARKERS[i + 1][0] - t} for i, (t, nm) in enumerate(MARKERS[:-1])]
    data = {"v": "5.7.4", "fr": FPS, "ip": 0, "op": n, "w": W, "h": H, "nm": "Hand Fabric Grab",
            "ddd": 0, "assets": assets, "layers": layers, "markers": markers,
            "meta": {"g": "pack_lottie.py", "d": "Hand + fabric cut out of the reference video, 30fps image sequence."}}
    out = os.path.join(ASSETS, name + ".json")
    with open(out, "w") as fh:
        json.dump(data, fh, separators=(",", ":"))
    print(os.path.relpath(out), len(layers), "image layers,", round(os.path.getsize(out) / 1e6, 2), "MB")

if __name__ == "__main__":
    fmt = "png" if "--png" in sys.argv else "webp"
    if "--src" in sys.argv:
        pack(sys.argv[sys.argv.index("--src") + 1], sys.argv[sys.argv.index("--out") + 1], fmt)
    else:
        pack(os.path.join(HERE, "composed", "light"), "refresh", fmt)
        pack(os.path.join(HERE, "composed", "dark"), "refresh_dark", fmt)
