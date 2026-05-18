"""Generates adaptive icon foreground — wallet on transparent background."""
from PIL import Image, ImageDraw
import os

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'icons', 'app_icon_foreground.png')
os.makedirs(os.path.dirname(OUT), exist_ok=True)

WHITE  = (255, 255, 255, 255)
STRIP  = (210, 225, 250, 255)
LINE   = (210, 220, 240, 255)
DARK   = (13,  52, 160, 255)
ACCENT = (250, 204, 21,  255)
BG_TOP = (30,  86, 230, 255)

img  = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Safe zone for adaptive icons: content should be in the centre 66%
# so we scale the wallet to fit within ~680x680 centred in 1024x1024
PAD = 172
WX1, WY1, WX2, WY2 = PAD + 20, PAD + 60, SIZE - PAD - 20, SIZE - PAD - 60

# Wallet body (white)
draw.rounded_rectangle([WX1, WY1, WX2, WY2], radius=54, fill=WHITE)

# Card-slot strip
draw.rounded_rectangle([WX1, WY1, WX2, WY1 + 80], radius=54, fill=STRIP)
draw.rectangle([WX1, WY1 + 54, WX2, WY1 + 80], fill=WHITE)

# Card lines
mid_y = (WY1 + WY2) // 2
for i, dy in enumerate([-60, 0, 60]):
    yy = mid_y + dy - 14
    w = [WX1 + 80 + 260, WX1 + 80 + 200, WX1 + 80 + 230][i]
    draw.rounded_rectangle([WX1 + 60, yy, w, yy + 28], radius=14, fill=LINE)

# Coin pocket
CX = WX2 - 100
CY = (WY1 + WY2) // 2
CR = 88
draw.ellipse([CX - CR, CY - CR, CX + CR, CY + CR], fill=DARK)
COIN_R = CR - 10
draw.ellipse([CX - COIN_R, CY - COIN_R, CX + COIN_R, CY + COIN_R], fill=ACCENT)

# ₹ symbol
lw, bd = 7, (13, 52, 160, 255)
draw.line([(CX - 28, CY - 30), (CX + 28, CY - 30)], fill=bd, width=lw)
draw.line([(CX - 28, CY - 8),  (CX + 28, CY - 8)],  fill=bd, width=lw)
draw.line([(CX - 12, CY - 30), (CX - 12, CY + 34)], fill=bd, width=lw)
draw.line([(CX + 22, CY - 8),  (CX - 18, CY + 34)], fill=bd, width=lw)

img.save(OUT, 'PNG')
print(f'Saved: {os.path.abspath(OUT)}')
