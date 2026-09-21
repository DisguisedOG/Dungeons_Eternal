from PIL import Image, ImageDraw, ImageFilter
import math
import os
import urllib.request

OUT = os.path.join(os.path.dirname(__file__), "..", "UI", "Theme")
os.makedirs(OUT, exist_ok=True)

FONT_URL = "https://github.com/google/fonts/raw/main/ofl/cinzel/static/Cinzel-Regular.ttf"
FONT_PATH = os.path.join(OUT, "Cinzel-Regular.ttf")

GOLD = (232, 196, 86)
GOLD_MID = (196, 148, 48)
GOLD_DK = (138, 92, 28)
GOLD_HI = (255, 236, 170)
INK = (28, 16, 10)
LEATHER_A = (118, 72, 40)
LEATHER_B = (86, 50, 28)
LEATHER_C = (142, 88, 50)


def lerp(a, b, t):
	return int(a + (b - a) * t)


def mix(c0, c1, t):
	return tuple(lerp(c0[i], c1[i], t) for i in range(3))


def fbm(x, y):
	n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
	frac = n - math.floor(n)
	s = math.sin(x * 0.31 + y * 0.19) * 0.25 + math.sin(x * 0.73 - y * 0.41) * 0.15
	return frac * 0.7 + (s + 0.4) * 0.3


def leather_color(x, y):
	n = fbm(x, y)
	return mix(LEATHER_B, mix(LEATHER_A, LEATHER_C, n), 0.35 + n * 0.65)


def fill_leather(img):
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			px[x, y] = leather_color(x, y) + (255,)
	return img.filter(ImageFilter.SMOOTH)


def gold_frame(img, thickness=20, radius=16):
	w, h = img.size
	overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	d = ImageDraw.Draw(overlay)
	rings = [
		(0, GOLD_HI),
		(1, GOLD),
		(3, GOLD_MID),
		(thickness - 4, GOLD_DK),
		(thickness - 2, INK),
		(thickness - 1, GOLD_MID),
	]
	for inset, color in rings:
		d.rounded_rectangle(
			[inset, inset, w - 1 - inset, h - 1 - inset],
			radius=max(2, radius - inset),
			outline=color,
			width=1 if inset > 0 else 2,
		)
	for cx, cy in ((thickness - 4, thickness - 4), (w - thickness + 3, thickness - 4), (thickness - 4, h - thickness + 3), (w - thickness + 3, h - thickness + 3)):
		d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=GOLD_HI, outline=GOLD_DK)
	img.alpha_composite(overlay)
	return img


def write_panel():
	s = 256
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	img = fill_leather(img)
	img = gold_frame(img, 20, 18)
	img.save(os.path.join(OUT, "leather_panel.png"))


def write_banner():
	w, h = 768, 96
	img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	img = fill_leather(img)
	img = gold_frame(img, 12, 22)
	img.save(os.path.join(OUT, "banner.png"))


def write_well():
	w, h = 96, 32
	img = Image.new("RGBA", (w, h), (18, 10, 8, 255))
	d = ImageDraw.Draw(img)
	d.rectangle([0, 0, w - 1, h - 1], outline=INK)
	d.rectangle([1, 1, w - 2, h - 2], outline=GOLD_DK)
	d.line([(2, 2), (w - 3, 2)], fill=(48, 28, 18))
	d.line([(2, h - 3), (w - 3, h - 3)], fill=GOLD_MID)
	img.save(os.path.join(OUT, "bar_well.png"))


def disc(draw, cx, cy, r, fill, outline=None):
	draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline)


def write_coin():
	s = 160
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	cx = cy = s // 2
	disc(d, cx + 2, cy + 3, 72, (40, 22, 8, 90))
	for r, col in ((72, GOLD_DK), (68, GOLD), (62, GOLD_MID), (56, GOLD)):
		disc(d, cx, cy, r, col)
	disc(d, cx - 18, cy - 22, 28, GOLD_HI)
	d.ellipse([cx - 56, cy - 56, cx + 56, cy + 56], outline=GOLD_DK, width=3)
	img = img.filter(ImageFilter.SMOOTH)
	img.save(os.path.join(OUT, "coin.png"))


def scallop(draw, cx, cy, r, lobes, amp, fill):
	pts = []
	steps = lobes * 12
	for i in range(steps):
		t = (i / steps) * math.tau
		rr = r + amp * math.cos(t * lobes)
		pts.append((cx + math.cos(t) * rr, cy + math.sin(t) * rr))
	draw.polygon(pts, fill=fill)


def write_seal(name, mid, dark, hi, icon_fn):
	s = 160
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	cx = cy = s // 2
	scallop(d, cx + 2, cy + 4, 68, 10, 7, (0, 0, 0, 70))
	scallop(d, cx, cy, 68, 10, 7, dark)
	scallop(d, cx, cy, 58, 10, 4, mid)
	disc(d, cx - 16, cy - 20, 26, hi)
	icon_fn(d, cx, cy)
	img = img.filter(ImageFilter.SMOOTH)
	img.save(os.path.join(OUT, name))


def icon_sword(d, cx, cy):
	blade = [(cx, cy - 32), (cx + 6, cy + 8), (cx, cy + 14), (cx - 6, cy + 8)]
	d.polygon(blade, fill=GOLD_HI, outline=INK)
	d.rectangle([cx - 16, cy + 10, cx + 16, cy + 16], fill=INK)
	d.rectangle([cx - 3, cy + 16, cx + 3, cy + 30], fill=INK)


def icon_bag(d, cx, cy):
	d.rounded_rectangle([cx - 18, cy - 6, cx + 18, cy + 26], radius=6, fill=INK)
	d.arc([cx - 12, cy - 24, cx + 12, cy - 2], 200, 340, fill=GOLD_HI, width=4)
	d.ellipse([cx - 4, cy + 6, cx + 4, cy + 14], outline=GOLD_HI, width=2)


def icon_char(d, cx, cy):
	disc(d, cx, cy - 16, 10, (230, 236, 255), INK)
	d.polygon([(cx - 18, cy + 26), (cx + 18, cy + 26), (cx + 12, cy - 2), (cx - 12, cy - 2)], fill=(20, 28, 48))


def icon_skull(d, cx, cy):
	disc(d, cx, cy - 6, 18, (236, 226, 200), INK)
	d.ellipse([cx - 12, cy - 10, cx - 4, cy - 2], fill=INK)
	d.ellipse([cx + 4, cy - 10, cx + 12, cy - 2], fill=INK)
	d.polygon([(cx, cy), (cx - 4, cy + 8), (cx + 4, cy + 8)], fill=INK)
	d.rectangle([cx - 10, cy + 10, cx + 10, cy + 18], fill=(236, 226, 200), outline=INK)


def write_flourish():
	w, h = 180, 28
	img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	pts = [(4, 16), (28, 6), (54, 8), (80, 18), (108, 20), (136, 8), (160, 10), (176, 16)]
	d.line(pts, fill=GOLD_DK, width=4)
	d.line(pts, fill=GOLD, width=2)
	img.save(os.path.join(OUT, "flourish.png"))


def download_font():
	if os.path.isfile(FONT_PATH) and os.path.getsize(FONT_PATH) > 10000:
		print("font exists")
		return
	try:
		urllib.request.urlretrieve(FONT_URL, FONT_PATH)
		print("downloaded Cinzel", os.path.getsize(FONT_PATH))
	except Exception as exc:
		print("font download failed", exc)


if __name__ == "__main__":
	write_panel()
	write_banner()
	write_well()
	write_coin()
	write_seal("seal_sword.png", (186, 134, 48), (110, 68, 18), (240, 208, 110), icon_sword)
	write_seal("seal_bag.png", (168, 48, 42), (92, 20, 16), (220, 86, 70), icon_bag)
	write_seal("seal_char.png", (52, 92, 168), (18, 36, 88), (110, 160, 230), icon_char)
	write_seal("seal_skull.png", (58, 48, 42), (22, 16, 14), (110, 96, 82), icon_skull)
	write_flourish()
	download_font()
	print("wrote painted theme", sorted(p for p in os.listdir(OUT) if p.endswith(".png")))
