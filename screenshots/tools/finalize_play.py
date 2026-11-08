"""Patch Nano Banana's mistakes, then export the Play Store set.

Fixes, all done locally with Pillow:
  03: Nano Banana copied shot 1's headline; repaint "SPLIT / SHARED DISHES
      FAIRLY" from this shot's own scaffold (Nano keeps headlines within ~6 px).
  06: garbled small print ("a the split evrjone"); paste the real line from
      the phone capture, scaled using the correct "417 rotis" line above it.
  07: an invented "PING FAISAL" button (Ground Booking has no ping); paint
      it out with the app-bar background.
Then every v1.png is cropped to 9:16 (bottom trimmed; the phone bleeds off
there anyway) and resized to 1080x1920 in final/.
"""
import os

from PIL import Image

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = [
    "01-know-what-you-owe",
    "02-add-your-order",
    "03-split-shared-dishes",
    "04-stop-last-minute-add-ons",
    "05-food-arrives",
    "06-settle-the-month",
    "07-book-the-ground",
]


def lum(p):
    return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]


def dark_box(im, x0, y0, x1, y1, thresh=170):
    px = im.load()
    xs, ys = [], []
    for y in range(y0, y1):
        for x in range(x0, x1):
            if lum(px[x, y]) < thresh:
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def fix_headline(v, scaffold):
    """Repaint the headline band from the scaffold's white text."""
    w = v.width
    s = scaffold.resize((w, round(scaffold.height * w / scaffold.width)), Image.LANCZOS)
    px, sp = v.load(), s.load()
    y0, y1, x0, x1 = 110, 520, 90, w - 90
    for y in range(y0, y1):
        left, right = px[40, y], px[w - 41, y]
        for x in range(x0, x1):
            t = (x - x0) / (x1 - x0)
            bg = tuple(round(left[i] + (right[i] - left[i]) * t) for i in range(3))
            a = max(0.0, min(1.0, (lum(sp[x, y]) - 120) / 120))
            px[x, y] = tuple(round(bg[i] + (255 - bg[i]) * a) for i in range(3))


def fix_small_print(v, raw):
    """Replace v's garbled second line with the capture's real one."""
    rA = dark_box(raw, 20, 2100, 1060, 2150)  # "417 rotis across 12 days"
    rB = dark_box(raw, 20, 2165, 1060, 2210)  # "Shared meals are billed too, ..."
    vA = dark_box(v, 300, 2205, 1150, 2250)
    vB = dark_box(v, 300, 2262, 1150, 2310)
    k = (vA[3] - vA[1]) / (rA[3] - rA[1])
    pad = 6
    # erase v's line with the sheet background
    bg = v.getpixel((vB[0] - 20, vB[1] - 10))
    v.paste(bg, (vB[0] - pad, vB[1] - pad, vB[2] + pad, vB[3] + pad))
    crop = raw.crop((rB[0] - pad, rB[1] - pad, rB[2] + pad, rB[3] + pad))
    crop = crop.resize((round(crop.width * k), round(crop.height * k)), Image.LANCZOS)
    x = round(vA[0] + (rB[0] - rA[0]) * k - pad * k)
    y = round(vA[1] + (rB[1] - rA[1]) * k - pad * k)
    v.paste(crop, (x, y))
    return k


def remove_button(v, x0, y0, x1, y1):
    """Fill a box by interpolating each row between the pixels just outside it."""
    px = v.load()
    for y in range(y0, y1):
        left, right = px[x0 - 4, y], px[x1 + 2, y]
        for x in range(x0, x1):
            t = (x - x0) / (x1 - x0)
            px[x, y] = tuple(round(left[i] + (right[i] - left[i]) * t) for i in range(3))


def main():
    raw06 = Image.open(os.path.join(HERE, "raw", "06-settle-the-month.png")).convert("RGB")
    os.makedirs(os.path.join(HERE, "final"), exist_ok=True)
    for slug in SHOTS:
        v = Image.open(os.path.join(HERE, slug, "v1.png")).convert("RGB")
        if slug.startswith("03"):
            fix_headline(v, Image.open(os.path.join(HERE, slug, "scaffold.png")).convert("RGB"))
        if slug.startswith("06"):
            print("06 small-print scale", round(fix_small_print(v, raw06), 3))
        if slug.startswith("07"):
            remove_button(v, 960, 805, 1244, 930)
        v.save(os.path.join(HERE, slug, "v1-fixed.png"))
        h = round(v.width * 16 / 9)
        out = v.crop((0, 0, v.width, h)).resize((1080, 1920), Image.LANCZOS)
        dst = os.path.join(HERE, "final", f"{slug}.png")
        out.save(dst, optimize=True)
        print(dst, out.size, os.path.getsize(dst) // 1024, "KB")


if __name__ == "__main__":
    main()
