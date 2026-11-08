"""Play Store scaffold: brand background, headline, Pixel-style device with the
app capture on its screen. 1080x1920 (9:16). Also strips the status bar from
raw captures. Run with: uv run --python 3.15 --with pillow python scaffold_play.py
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1080, 1920
FONT = "C:/Windows/Fonts/seguibl.ttf"  # Segoe UI Black, stand-in for SF Pro Display Black
STATUS_BAR = 150  # px of status bar on the Pixel 9 captures (1080 wide)


def strip_status_bar(src, dst):
    """Replace the status-bar rows with the first clean row below them."""
    im = Image.open(src).convert("RGB")
    row = im.crop((0, STATUS_BAR + 4, im.width, STATUS_BAR + 5))
    for y in range(STATUS_BAR + 4):
        im.paste(row, (0, y))
    im.save(dst)
    return im


def fit(text, max_w, size_max, size_min):
    d = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    for size in range(size_max, size_min - 1, -2):
        f = ImageFont.truetype(FONT, size)
        if d.textbbox((0, 0), text, font=f)[2] <= max_w:
            return f
    return ImageFont.truetype(FONT, size_min)


def wrap(text, font, max_w):
    d = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textbbox((0, 0), t, font=font)[2] <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def desc_lines(text):
    """One line if it fits at a readable size, else two balanced lines."""
    d = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    for size in range(72, 57, -2):
        f = ImageFont.truetype(FONT, size)
        if d.textbbox((0, 0), text, font=f)[2] <= 900:
            return f, [text]
    f = ImageFont.truetype(FONT, 72)
    words = text.split()
    best = min(range(1, len(words)), key=lambda i: abs(
        d.textbbox((0, 0), " ".join(words[:i]), font=f)[2] - d.textbbox((0, 0), " ".join(words[i:]), font=f)[2]))
    return f, [" ".join(words[:best]), " ".join(words[best:])]


def device(screen):
    """A Pixel 10 Pro-like handset: flat sides, even slim bezels, centred punch hole."""
    sw = 690
    sh = round(sw * screen.height / screen.width)
    bez, rim = 20, 6
    dw, dh = sw + 2 * (bez + rim), sh + 2 * (bez + rim)
    out = Image.new("RGBA", (dw + 16, dh), (0, 0, 0, 0))
    d = ImageDraw.Draw(out)
    # side buttons (power + volume rocker) on the right edge
    d.rounded_rectangle((dw - 4, 330, dw + 9, 430), 5, fill=(150, 154, 160, 255))
    d.rounded_rectangle((dw - 4, 480, dw + 9, 660), 5, fill=(150, 154, 160, 255))
    # aluminium rim, then black glass
    d.rounded_rectangle((0, 0, dw - 1, dh - 1), 92, fill=(176, 180, 186, 255))
    d.rounded_rectangle((rim, rim, dw - 1 - rim, dh - 1 - rim), 86, fill=(12, 13, 15, 255))
    # screen
    scr = screen.resize((sw, sh), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw - 1, sh - 1), 66, fill=255)
    out.paste(scr, (rim + bez, rim + bez), mask)
    # punch-hole camera
    cx, cy, r = dw // 2, rim + bez + 34, 15
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(5, 5, 6, 255))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bg", required=True)
    ap.add_argument("--verb", required=True)
    ap.add_argument("--desc", required=True)
    ap.add_argument("--screenshot", required=True)
    ap.add_argument("--output", required=True)
    a = ap.parse_args()

    os.makedirs(os.path.dirname(a.output), exist_ok=True)
    clean = os.path.splitext(a.output)[0] + "-screen.png"
    screen = strip_status_bar(a.screenshot, clean)

    canvas = Image.new("RGBA", (W, H), a.bg)
    d = ImageDraw.Draw(canvas)
    vf = fit(a.verb.upper(), 860, 210, 120)
    y = 100
    vb = d.textbbox((0, 0), a.verb.upper(), font=vf)
    d.text(((W - (vb[2] - vb[0])) / 2 - vb[0], y - vb[1]), a.verb.upper(), font=vf, fill="white")
    y += vb[3] - vb[1] + 34
    df, lines = desc_lines(a.desc.upper())
    for line in lines:
        lb = d.textbbox((0, 0), line, font=df)
        d.text(((W - (lb[2] - lb[0])) / 2 - lb[0], y - lb[1]), line, font=df, fill="white")
        y += lb[3] - lb[1] + 18

    dev = device(screen)
    top = y + 60
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sx = (W - dev.width) // 2
    ImageDraw.Draw(shadow).rounded_rectangle((sx + 10, top + 30, sx + dev.width - 6, top + dev.height + 30), 92, fill=(0, 0, 0, 110))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(40)))
    canvas.alpha_composite(dev, (sx, top))
    canvas.convert("RGB").save(a.output)
    print(a.output)


if __name__ == "__main__":
    main()
