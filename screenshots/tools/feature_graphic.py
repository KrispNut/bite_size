"""Google Play feature graphic (1024x500, 24-bit PNG, no alpha).

Left: the app's mascot icon, the "Bite Size" wordmark and the tagline.
Right: two of the finished store screenshots' phones, cut out of their green
background (flood-filled from the edges) and layered so they bleed off the
bottom like the screenshot set.
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROOT = os.path.dirname(HERE)
W, H = 1024, 500
BG = (26, 93, 70)  # the set's background, as rendered
BLACK = "C:/Windows/Fonts/seguibl.ttf"
SEMI = "C:/Windows/Fonts/seguisb.ttf"


def cut_phone(path, box, width):
    """Crop a phone from a final screenshot and key out the green around it."""
    im = Image.open(path).convert("RGB").crop(box)
    key = im.copy()
    w, h = key.size
    seeds = [(x, 0) for x in range(0, w, 40)] + [(0, y) for y in range(0, h, 40)] + [(w - 1, y) for y in range(0, h, 40)]
    for s in seeds:
        r, g, b = key.getpixel(s)
        if abs(r - BG[0]) + abs(g - BG[1]) + abs(b - BG[2]) < 40:
            ImageDraw.floodfill(key, s, (255, 0, 255), thresh=34)
    diff = ImageChops.difference(key, Image.new("RGB", key.size, (255, 0, 255))).convert("L")
    alpha = diff.point(lambda v: 255 if v > 8 else 0).filter(ImageFilter.GaussianBlur(1.2))
    im.putalpha(alpha)
    return im.resize((width, round(h * width / w)), Image.LANCZOS)


def main():
    canvas = Image.new("RGBA", (W, H), BG + (255,))

    # One phone: the ledger with its YOUR ROTIS / TOTAL ROTIS tiles popping out.
    front = cut_phone(os.path.join(HERE, "final", "01-know-what-you-owe.png"), (40, 380, 1040, 1920), 400)
    canvas.alpha_composite(front, (586, 40))

    d = ImageDraw.Draw(canvas)
    logo = Image.open(os.path.join(ROOT, "assets", "icon", "logo.png")).convert("RGBA").resize((132, 132), Image.LANCZOS)
    x, y = 64, 78
    canvas.alpha_composite(logo, (x - 8, y))
    y += 142
    word = ImageFont.truetype(BLACK, 84)
    d.text((x, y), "Bite Size", font=word, fill="white", anchor="lt")
    y += 104
    tag = ImageFont.truetype(BLACK, 34)
    d.text((x, y), "Office lunch, sorted.", font=tag, fill=(255, 255, 255, 235), anchor="lt")
    y += 52
    sub = ImageFont.truetype(SEMI, 22)
    d.text((x, y), "Rotis  ·  shared meals  ·  one monthly bill", font=sub, fill=(255, 255, 255, 180), anchor="lt")

    out = os.path.join(HERE, "final", "feature-graphic.png")
    canvas.convert("RGB").save(out, optimize=True)
    print(out, Image.open(out).size, Image.open(out).mode, os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
