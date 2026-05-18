"""Generates PocketLedger app icon — 1024x1024 PNG."""
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icon', 'app_icon.png')
os.makedirs(os.path.dirname(OUT), exist_ok=True)

# Colours
BG_TOP    = (30,  86, 230)
BG_BOTTOM = (13,  52, 160)
WHITE     = (255, 255, 255)
ACCENT    = (250, 204,  21)   # yellow

img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Gradient background ──────────────────────────────────────────────────────
for y in range(SIZE):
    t = y / SIZE
    r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
    g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
    b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# ── Wallet body ──────────────────────────────────────────────────────────────
WX1, WY1, WX2, WY2 = 140, 300, 884, 724
draw.rounded_rectangle([WX1, WY1, WX2, WY2], radius=64, fill=WHITE)

# Card-slot strip at top of wallet (light blue tint)
STRIP_COLOR = (210, 225, 250)
draw.rounded_rectangle([WX1, WY1, WX2, WY1 + 100], radius=64, fill=STRIP_COLOR)
# Fill bottom half of strip to merge with white body
draw.rectangle([WX1, WY1 + 64, WX2, WY1 + 100], fill=WHITE)

# ── Card lines (three stacked) ───────────────────────────────────────────────
LINE = (210, 220, 240)
for i, yy in enumerate([450, 520, 590]):
    w = [560, 500, 530][i]
    draw.rounded_rectangle([240, yy, w, yy + 32], radius=16, fill=LINE)

# ── Coin pocket circle on the right ─────────────────────────────────────────
CX, CY, CR = 730, 512, 100
# Pocket recess (dark blue)
draw.ellipse([CX - CR, CY - CR, CX + CR, CY + CR], fill=(20, 60, 170))
# Coin (yellow)
COIN_R = CR - 12
draw.ellipse([CX - COIN_R, CY - COIN_R, CX + COIN_R, CY + COIN_R], fill=ACCENT)

# ₹ symbol on the coin — drawn with lines
lw = 8
bd = (13, 52, 160)   # dark blue strokes
# Top horizontal
draw.line([(CX - 30, CY - 32), (CX + 30, CY - 32)], fill=bd, width=lw)
# Middle horizontal
draw.line([(CX - 30, CY - 8), (CX + 30, CY - 8)], fill=bd, width=lw)
# Left vertical stem
draw.line([(CX - 14, CY - 32), (CX - 14, CY + 36)], fill=bd, width=lw)
# Diagonal slash
draw.line([(CX + 24, CY - 8), (CX - 18, CY + 36)], fill=bd, width=lw)

# ── Subtle shine highlight (top-left arc) ────────────────────────────────────
shine = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(shine)
sd.ellipse([-80, -200, 700, 480], fill=(255, 255, 255, 18))
img = Image.alpha_composite(img, shine)

# ── Flatten to RGB ───────────────────────────────────────────────────────────
final = Image.new('RGB', (SIZE, SIZE), BG_BOTTOM)
final.paste(img, mask=img.split()[3])
final.save(OUT, 'PNG', optimize=True)
print(f'Saved: {os.path.abspath(OUT)}')
