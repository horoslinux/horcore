#!/usr/bin/env python3
"""Generate the HorOS icon and Plymouth splash mark from the logo source.

Run from the repository root with Python + Pillow installed:

    python3 tools/generate-branding.py

The generated PNGs are committed; Pillow is only needed to regenerate them.
Wallpapers are curated JPEGs and are no longer generated here.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "airootfs/usr/share/plymouth/themes/horos/logo.png"
ICON = ROOT / "airootfs/usr/share/horos/branding/horos-icon.png"
MARK = ROOT / "airootfs/usr/share/plymouth/themes/horos/horos-mark.png"

AMBER = (253, 196, 29)


def mark() -> Image.Image:
    """Extract just the amber mark from the translucent Plymouth logo."""
    src = Image.open(LOGO).convert("RGBA")
    px = src.load()
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    opx = out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            if r > 120 and g > 100 and b < 110 and a > 0:
                opx[x, y] = (r, g, b, a)
    return out.crop(out.getbbox())


def make_plymouth_mark(m: Image.Image) -> None:
    """Tight, transparent mark for the Plymouth theme (no 500x500 dark canvas)."""
    pad = 18
    canvas = Image.new("RGBA", (m.width + 2 * pad, m.height + 2 * pad), (0, 0, 0, 0))
    canvas.alpha_composite(m, (pad, pad))
    scale = 1.25
    canvas = canvas.resize((round(canvas.width * scale), round(canvas.height * scale)),
                           Image.Resampling.LANCZOS)
    MARK.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(MARK, optimize=True)


def fit(img: Image.Image, width: int) -> Image.Image:
    height = round(img.height * width / img.width)
    return img.resize((width, height), Image.Resampling.LANCZOS)


def rounded_badge(size: int, radius: int) -> Image.Image:
    badge = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(badge)
    for y in range(size):
        t = y / (size - 1)
        color = (round(20 - 14 * t), round(23 - 16 * t), round(31 - 21 * t), 255)
        d.line((0, y, size, y), fill=color)
    d.rounded_rectangle((2, 2, size - 3, size - 3), radius=radius,
                        outline=AMBER + (150,), width=3)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1),
                                           radius=radius, fill=255)
    badge.putalpha(mask)
    return badge


def make_icon(m: Image.Image) -> None:
    size = 512
    badge = rounded_badge(size, 104)
    logo = fit(m, 340)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow.alpha_composite(logo, ((size - logo.width) // 2,
                                (size - logo.height) // 2 - 10))
    glow = glow.filter(ImageFilter.GaussianBlur(24))
    glow.putalpha(glow.getchannel("A").point(lambda a: int(a * 0.55)))
    badge.alpha_composite(glow)

    badge.alpha_composite(logo, ((size - logo.width) // 2,
                                 (size - logo.height) // 2 - 10))
    ICON.parent.mkdir(parents=True, exist_ok=True)
    badge.save(ICON, optimize=True)


if __name__ == "__main__":
    logo_mark = mark()
    make_plymouth_mark(logo_mark)
    make_icon(logo_mark)
    print(f"Wrote {MARK.relative_to(ROOT)} and {ICON.relative_to(ROOT)}")
