#!/usr/bin/env python3
"""Generate launcher icons Torang Go:
- customer: favicon.png (logo Torang Go)
- driver  : logo + badge "DRIVER" (helmet) + nuansa leaf
Output ke android/app/src/<flavor>/res/ + preview PNG.
"""
from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, '..', '..', 'favicon.png')
ANDROID = os.path.join(ROOT, 'android', 'app', 'src')
PREVIEW = os.path.join(ROOT, 'preview-icons')

OCEAN = (20, 119, 230, 255)     # #1477E6
LEAF = (47, 174, 78, 255)       # #2FAE4E
INK = (14, 34, 51, 255)         # #0E2233
WHITE = (255, 255, 255, 255)

FONT_BOLD = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'

LEGACY = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
FG = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}


def rounded(img: Image.Image, radius_frac: float) -> Image.Image:
    """Potong sudut membulat (anti-alias via supersample)."""
    size = img.size
    mask = Image.new('L', size, 0)
    d = ImageDraw.Draw(mask)
    r = int(min(size) * radius_frac)
    d.rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=r, fill=255)
    out = img.copy()
    out.putalpha(mask)
    return out


def make_base() -> Image.Image:
    """Logo favicon 512px dengan sudut membulat."""
    im = Image.open(SRC).convert('RGBA')
    im = im.resize((1024, 1024), Image.LANCZOS)  # supersample
    return rounded(im, 0.225)


def add_driver_badge(logo: Image.Image) -> Image.Image:
    """Logo + ribbon 'DRIVER' + badge helm di pojok (diferensiasi driver)."""
    im = logo.copy()
    s = im.size[0]  # 1024
    d = ImageDraw.Draw(im)

    # --- Badge helm (lingkaran leaf, pojok kanan-bawah) ---
    br = int(s * 0.17)          # radius badge
    cx, cy = s - int(s * 0.16), s - int(s * 0.16)
    # ring putih biar pop
    d.ellipse([cx - br, cy - br, cx + br, cy + br], fill=WHITE)
    br2 = int(br * 0.9)
    d.ellipse([cx - br2, cy - br2, cx + br2, cy + br2], fill=LEAF)

    # helm sederhana: kubah + visor
    hw = int(br2 * 0.62)        # setengah lebar helm
    hb = int(br2 * 0.10)        # tebal garis
    d.pieslice([cx - hw, cy - int(br2 * 0.72), cx + hw, cy + int(br2 * 0.78)],
               180, 360, fill=WHITE)
    # visor
    d.rounded_rectangle(
        [cx - int(hw * 1.05), cy - int(br2 * 0.12),
         cx + int(hw * 1.05), cy + int(br2 * 0.22)],
        radius=hb, fill=INK)
    # chin strap
    d.arc([cx - hw, cy - int(br2 * 0.5), cx + hw, cy + int(br2 * 0.95)],
          20, 160, fill=WHITE, width=hb)

    # --- Ribbon 'DRIVER' di bawah tengah ---
    try:
        font = ImageFont.truetype(FONT_BOLD, int(s * 0.085))
    except OSError:
        font = ImageFont.load_default()
    text = 'DRIVER'
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    pad_x = int(s * 0.045)
    pill_h = th + int(s * 0.05)
    pill_w = tw + pad_x * 2
    cx0 = (s - pill_w) // 2
    cy0 = s - int(s * 0.175) - pill_h // 2
    # pill ink dengan outline putih
    d.rounded_rectangle(
        [cx0, cy0, cx0 + pill_w, cy0 + pill_h],
        radius=pill_h // 2, fill=INK, outline=WHITE, width=int(s * 0.012))
    d.text((cx0 + pad_x - bbox[0], cy0 + (pill_h - th) // 2 - bbox[1]),
           text, font=font, fill=WHITE)
    return im


def adaptive_foreground(logo: Image.Image, fg_size: int,
                        ring: bool = True) -> Image.Image:
    """Foreground adaptive: logo ~58% di tengah kanvas transparan (+ring putih)."""
    canvas = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
    logo_frac = 0.56
    ring_pad = 0.025 if ring else 0.0
    outer = int(fg_size * (logo_frac + ring_pad * 2))
    inner = int(fg_size * logo_frac)

    if ring:
        ring_img = Image.new('RGBA', (outer, outer), (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring_img)
        rd.rounded_rectangle([0, 0, outer - 1, outer - 1],
                             radius=int(outer * 0.23), fill=(255, 255, 255, 235))
        small = logo.resize((inner, inner), Image.LANCZOS)
        ring_img.alpha_composite(small, ((outer - inner) // 2,) * 2)
        art = ring_img
    else:
        art = logo.resize((inner, inner), Image.LANCZOS)

    canvas.alpha_composite(art, ((fg_size - art.size[0]) // 2,) * 2)
    return canvas


def bg_xml(c1: str, c2: str) -> str:
    return f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="315"
        android:startColor="{c1}"
        android:endColor="{c2}"
        android:type="linear"/>
</shape>
'''


ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''


def emit(flavor: str, logo: Image.Image, grad: tuple[str, str]):
    res = os.path.join(ANDROID, flavor, 'res')
    # legacy
    for dpi, px in LEGACY.items():
        p = os.path.join(res, f'mipmap-{dpi}')
        os.makedirs(p, exist_ok=True)
        logo.resize((px, px), Image.LANCZOS).save(os.path.join(p, 'ic_launcher.png'))
    # adaptive
    for dpi, px in FG.items():
        p = os.path.join(res, f'mipmap-{dpi}')
        os.makedirs(p, exist_ok=True)
        adaptive_foreground(logo, px).save(os.path.join(p, 'ic_launcher_foreground.png'))
    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
        f.write(ADAPTIVE_XML)
    dr = os.path.join(res, 'drawable')
    os.makedirs(dr, exist_ok=True)
    with open(os.path.join(dr, 'ic_launcher_background.xml'), 'w') as f:
        f.write(bg_xml(*grad))


def preview(cust: Image.Image, drv: Image.Image):
    os.makedirs(PREVIEW, exist_ok=True)
    W = 640
    sheet = Image.new('RGBA', (W, 420), (251, 246, 236, 255))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(FONT_BOLD, 26)
    d.text((28, 24), 'CUSTOMER', font=font, fill=OCEAN)
    d.text((W // 2 + 24, 24), 'DRIVER', font=font, fill=LEAF)
    x = 36
    for px in (192, 96, 48):
        sheet.alpha_composite(cust.resize((px, px), Image.LANCZOS), (x, 100))
        sheet.alpha_composite(drv.resize((px, px), Image.LANCZOS), (W // 2 + x - 12, 100))
        x += px + 28
    # versi adaptive (logo di atas gradient)
    for i, (logo, g1, g2, label) in enumerate([
            (cust, (20, 119, 230), (29, 143, 224), 'bg ocean'),
            (drv, (47, 174, 78), (79, 195, 247), 'bg leaf')]):
        tile = Image.new('RGBA', (160, 160), g1 + (255,))
        tg = Image.new('RGBA', (160, 160), g2 + (255,))
        mask = Image.new('L', (160, 160), 0)
        ImageDraw.Draw(mask).pieslice([0, 0, 160, 160], 270, 360, fill=255)
        tile.paste(tg, (0, 0), mask)
        fg = adaptive_foreground(logo, 160)
        tile.alpha_composite(fg)
        sheet.alpha_composite(rounded(tile, 0.28), (40 + i * 300, 300))
    sheet.convert('RGB').save(os.path.join(PREVIEW, 'preview.png'))
    # file tunggal buat lihat sendiri
    cust.resize((512, 512), Image.LANCZOS).convert('RGB').save(os.path.join(PREVIEW, 'customer-512.png'))
    drv.resize((512, 512), Image.LANCZOS).convert('RGB').save(os.path.join(PREVIEW, 'driver-512.png'))


def main():
    base = make_base()
    cust = base
    drv = add_driver_badge(base)

    emit('customer', cust, ('#1477E6', '#1D8FE0'))
    emit('driver', drv, ('#2FAE4E', '#4FC3F7'))
    preview(cust, drv)
    print('OK — icons customer & driver digenerate.')
    print('Preview:', os.path.join(PREVIEW, 'preview.png'))


if __name__ == '__main__':
    main()
