"""Generate BTC Field App artwork: Play Store icon, feature graphic and Android launcher icons.

Usage (from the repo root):  python3 docs/store/generate_art.py
Requires Pillow and the Noto Sans / Noto Sans Georgian fonts.
"""
import math, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "docs", "store")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
FONT_DIR = "/usr/share/fonts/truetype/noto/"
TOP, BOT = (31, 122, 82), (12, 66, 46)      # deep field-green gradient
ORANGE = (242, 140, 40)
WHITE = (255, 255, 255)

def gradient(w, h):
    g = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(g)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(TOP[i] + (BOT[i] - TOP[i]) * t) for i in range(3)))
    return g

def contours(d, cx, cy, s, n=6, alpha=70):
    """Irregular concentric 'topographic' rings."""
    for k in range(n):
        r = s * (0.18 + 0.13 * k)
        pts = []
        for a in range(0, 360, 3):
            th = math.radians(a)
            wob = 1 + 0.10 * math.sin(3 * th + k * 0.7) + 0.06 * math.sin(5 * th - k)
            pts.append((cx + r * 1.15 * wob * math.cos(th), cy + r * 0.85 * wob * math.sin(th)))
        d.line(pts + [pts[0]], fill=(255, 255, 255, alpha), width=max(2, int(s * 0.012)))

def pin(d, cx, cy, h):
    """Map pin: circle head + pointed tail, orange centre dot."""
    r = h * 0.36
    head_cy = cy - h * 0.5 + r
    tip = (cx, cy + h * 0.5)
    # tangent points from tip to head circle
    dy = tip[1] - head_cy
    ang = math.asin(r / dy)
    tl = (cx - r * math.cos(ang), head_cy + r * math.sin(ang))
    tr = (cx + r * math.cos(ang), head_cy + r * math.sin(ang))
    d.polygon([tl, tr, tip], fill=WHITE)
    d.ellipse([cx - r, head_cy - r, cx + r, head_cy + r], fill=WHITE)
    ir = r * 0.45
    d.ellipse([cx - ir, head_cy - ir, cx + ir, head_cy + ir], fill=ORANGE)

def icon(size):
    S = size * 4
    base = gradient(S, S).convert("RGBA")
    over = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    contours(d, S * 0.5, S * 0.60, S, n=6)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pin(ImageDraw.Draw(shadow), S * 0.5 + S * 0.012, S * 0.47 + S * 0.02, S * 0.56)
    shadow = Image.eval(shadow.split()[3], lambda a: a * 0.35)
    base.alpha_composite(over)
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sh.putalpha(shadow.filter(ImageFilter.GaussianBlur(S * 0.015)))
    base.alpha_composite(sh)
    p = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pin(ImageDraw.Draw(p), S * 0.5, S * 0.47, S * 0.56)
    base.alpha_composite(p)
    return base.resize((size, size), Image.LANCZOS)

def feature():
    W, H, k = 1024, 500, 3
    img = gradient(W * k, H * k).convert("RGBA")
    over = Image.new("RGBA", img.size, (0, 0, 0, 0))
    contours(ImageDraw.Draw(over), W * k * 0.80, H * k * 0.55, H * k * 1.25, n=8, alpha=45)
    img.alpha_composite(over)
    ic = icon(300).resize((300 * k, 300 * k), Image.LANCZOS)
    mask = Image.new("L", ic.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *ic.size], radius=int(ic.size[0] * 0.22), fill=255)
    img.paste(ic, (int(70 * k), int(100 * k)), mask)
    d = ImageDraw.Draw(img)
    title = ImageFont.truetype(FONT_DIR + "NotoSans-Bold.ttf", 76 * k)
    sub = ImageFont.truetype(FONT_DIR + "NotoSansGeorgian-Regular.ttf", 30 * k)
    small = ImageFont.truetype(FONT_DIR + "NotoSans-Regular.ttf", 24 * k)
    x = 420 * k
    d.text((x, 135 * k), "BTC Field App", font=title, fill=WHITE)
    d.text((x, 240 * k), "ლანდშაფტური საველე კვლევა", font=sub, fill=WHITE)
    d.text((x, 290 * k), "Records · GPS · Maps · Export", font=small, fill=(220, 240, 228))
    d.text((x, 335 * k), "Georgian Cartographers Association", font=small, fill=(255, 196, 140))
    return img.resize((W, H), Image.LANCZOS)

# Adaptive icon layers are 108dp; the launcher shows the inner 72dp (2/3).
VISIBLE = 72 / 108

def adaptive_background(size):
    S = size * 4
    base = gradient(S, S).convert("RGBA")
    over = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    contours(ImageDraw.Draw(over), S * 0.5, S * (0.5 + 0.10 * VISIBLE), S * VISIBLE, n=8)
    base.alpha_composite(over)
    return base.resize((size, size), Image.LANCZOS).convert("RGB")

def adaptive_foreground(size):
    S = size * 4
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    h, cy = S * 0.56 * VISIBLE, S * (0.5 - 0.03 * VISIBLE)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pin(ImageDraw.Draw(shadow), S * 0.5 + S * 0.008, cy + S * 0.013, h)
    a = Image.eval(shadow.split()[3], lambda v: v * 0.35).filter(ImageFilter.GaussianBlur(S * 0.01))
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sh.putalpha(a)
    fg.alpha_composite(sh)
    p = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    pin(ImageDraw.Draw(p), S * 0.5, cy, h)
    fg.alpha_composite(p)
    return fg.resize((size, size), Image.LANCZOS)

def legacy(size):
    """Pre-API-26 launcher icon: rounded square with transparent corners."""
    im = icon(size)
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size * 4 - 1, size * 4 - 1], radius=int(size * 4 * 0.18), fill=255)
    im.putalpha(mask.resize((size, size), Image.LANCZOS))
    return im

IOS_ICONS = {
    "20x20@1x": 20, "20x20@2x": 40, "20x20@3x": 60,
    "29x29@1x": 29, "29x29@2x": 58, "29x29@3x": 87,
    "40x40@1x": 40, "40x40@2x": 80, "40x40@3x": 120,
    "60x60@2x": 120, "60x60@3x": 180,
    "76x76@1x": 76, "76x76@2x": 152,
    "83.5x83.5@2x": 167, "1024x1024@1x": 1024,
}


def ios_icons():
    # iOS rounds the corners itself and rejects icons with an alpha channel.
    d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../ios/Runner/Assets.xcassets/AppIcon.appiconset")
    master = icon(1024).convert("RGB")
    for name, size in IOS_ICONS.items():
        master.resize((size, size), Image.LANCZOS).save(f"{d}/Icon-App-{name}.png", optimize=True)


DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

if __name__ == "__main__":
    icon(512).convert("RGB").save(f"{OUT}/play_icon_512.png", optimize=True)
    feature().convert("RGB").save(f"{OUT}/feature_graphic_1024x500.png", optimize=True)
    for name, k in DENSITIES.items():
        d = os.path.join(RES, f"mipmap-{name}")
        os.makedirs(d, exist_ok=True)
        legacy(int(48 * k)).save(f"{d}/ic_launcher.png", optimize=True)
        adaptive_background(int(108 * k)).save(f"{d}/ic_launcher_background.png", optimize=True)
        adaptive_foreground(int(108 * k)).save(f"{d}/ic_launcher_foreground.png", optimize=True)
    ios_icons()
    print("ok")
