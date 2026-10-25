"""Balatro-style pixel art for the special 3-player jokers (BalatroMultiplayer3P, original fork art).
Every card is drawn pixel by pixel at 1x (71x95) and upscaled nearest-neighbour to 2x (142x190)."""
import math, os, sys
from PIL import Image

W, H, CX = 71, 95, 35
T = (0, 0, 0, 0)
OUT = (79, 99, 103, 255); EDGE = (191, 199, 213, 255); WHITE = (255, 255, 255, 255)
GRAY = (220, 220, 220, 255); GRAY2 = (192, 192, 192, 255); GRAY3 = (150, 160, 170, 255)
RED = (253, 95, 85, 255); RED2 = (214, 66, 60, 255); RED3 = (170, 46, 46, 255)
ORANGE = (253, 162, 0, 255); ORANGE2 = (222, 128, 0, 255)
BLUE = (0, 156, 253, 255); BLUE_L = (129, 206, 253, 255); BLUE_D = (0, 116, 200, 255)
GREEN = (75, 194, 146, 255); GREEN_L = (140, 226, 190, 255); GREEN_D = (44, 150, 108, 255)
PURPLE = (133, 103, 207, 255); PURPLE_L = (180, 158, 236, 255); PURPLE_D = (98, 72, 168, 255)
PAPER = (240, 222, 178, 255); PAPER2 = (214, 186, 132, 255); PAPER3 = (186, 152, 98, 255)
GOLD = (255, 204, 64, 255); GOLD_L = (255, 236, 150, 255); GOLD_D = (214, 150, 20, 255)
SILVER = (205, 214, 224, 255); SILVER_L = (238, 242, 247, 255); SILVER_D = (160, 172, 186, 255)
BRONZE = (214, 140, 90, 255); BRONZE_L = (240, 180, 130, 255); BRONZE_D = (170, 100, 60, 255)
BROWN = (120, 86, 70, 255); BROWN_L = (160, 120, 96, 255); BROWN_D = (86, 60, 50, 255)
PINK = (250, 160, 160, 255); PINK_D = (220, 120, 120, 255)

PALETTES = {  # jester outfits: (hat left, hat left shade, hat right, hat right shade, collar, collar light, collar dark)
    "classic": (RED, RED2, ORANGE, ORANGE2, BLUE, BLUE_L, BLUE_D),
    "blue": (BLUE, BLUE_D, BLUE_L, BLUE, RED, PINK, RED2),
    "green": (GREEN, GREEN_D, GOLD, GOLD_D, PURPLE, PURPLE_L, PURPLE_D),
    "purple": (PURPLE, PURPLE_D, RED, RED2, GREEN, GREEN_L, GREEN_D),
    "red": (RED, RED2, RED, RED2, ORANGE, GOLD_L, ORANGE2),
}


class Card:
    def __init__(self):
        self.px = [[T] * W for _ in range(H)]
        self._frame(); self._joker_text()

    def put(self, x, y, c):
        x, y = int(x), int(y)
        if 2 <= x <= 68 and 2 <= y <= 92: self.px[y][x] = c

    def _frame(self):
        for y in range(1, 94):
            for x in range(1, 70):
                dx, dy = min(x - 1, 69 - x), min(y - 1, 93 - y)
                if dx <= 2 and dy <= 2 and dx + dy < 2: continue
                self.px[y][x] = WHITE
        for y in range(H):
            for x in range(W):
                if self.px[y][x] == WHITE and any(self.px[y + b][x + a] == T for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    self.px[y][x] = EDGE

    def _joker_text(self):
        y = 7
        for ch in "JOKER":
            for r, row in enumerate(GLYPHS[ch]):
                for c, v in enumerate(row):
                    if v == "#":
                        self.px[y + r][4 + c] = OUT
                        self.px[94 - (y + r)][66 - c] = OUT
            y += 9

    def shape(self, cells, fill, outline=True):
        cells = set(cells)
        if outline:
            ring = {(x + a, y + b) for x, y in cells for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))} - cells
            for x, y in ring: self.put(x, y, OUT)
        for x, y in cells: self.put(x, y, fill(x, y) if callable(fill) else fill)

    def save(self, key, outdir):
        im = Image.new("RGBA", (W, H)); im.putdata([c for row in self.px for c in row])
        os.makedirs(os.path.join(outdir, "1x"), exist_ok=True); os.makedirs(os.path.join(outdir, "2x"), exist_ok=True)
        im.save(os.path.join(outdir, "1x", f"j_{key}.png"))
        im.resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(outdir, "2x", f"j_{key}.png"))
        return im


GLYPHS = {
    "J": ["...####.", "..#####.", "....##..", "....##..", "##..##..", "###.##..", ".####...", "........"],
    "O": ["..###...", ".##.##..", "##...##.", "##...##.", "##...##.", "##...##.", ".##.##..", "..###..."],
    "K": ["####.###", ".##..##.", ".##.##..", ".####...", ".#####..", ".##..##.", ".##..##.", "####.###"],
    "E": ["#######.", ".##..##.", ".##.....", ".#####..", ".##.....", ".##.....", ".##..##.", "#######."],
    "R": ["######..", ".##..##.", ".##...#.", ".##..##.", ".#####..", ".##.##..", ".##..##.", "###..##."],
}


def ellipse(cx, cy, rx, ry):
    return {(x, y) for x in range(int(cx - rx) - 1, int(cx + rx) + 2) for y in range(int(cy - ry) - 1, int(cy + ry) + 2)
            if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1}


def rect(x0, y0, x1, y1): return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}
def mirror(cells, cx=CX): return set(cells) | {(2 * cx - x, y) for x, y in cells}
def flip(cells, cx=CX): return {(2 * cx - x, y) for x, y in cells}


def poly(points):
    xs = [p[0] for p in points]; ys = [p[1] for p in points]; out = set()
    for y in range(int(min(ys)), int(max(ys)) + 1):
        for x in range(int(min(xs)), int(max(xs)) + 1):
            px, py, inside, j = x + 0.5, y + 0.5, False, len(points) - 1
            for i in range(len(points)):
                xi, yi = points[i]; xj, yj = points[j]
                if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi: inside = not inside
                j = i
            if inside: out.add((x, y))
    return out


def crown(c, cx, top, w=5, h=7):
    """gold crown, centred on cx, `w` = half width, `top` = y of the points"""
    base = top + h - 3
    cells = rect(cx - w, base, cx + w, top + h - 1) | rect(cx - w, top + 2, cx - w + 1, base) | rect(cx - 1, top, cx + 1, base) | rect(cx + w - 1, top + 2, cx + w, base)
    c.shape(cells, lambda x, y: GOLD_L if y == base else (GOLD_D if y == top + h - 1 else GOLD))
    c.put(cx, base + 1, RED)
    if w >= 4: c.put(cx - w + 2, base + 1, BLUE); c.put(cx + w - 2, base + 1, BLUE)


def P(cx, cy, u, pts): return poly([(cx + x * u, cy + y * u) for x, y in pts])


def jester(c, cx, cy, s=8, pal="classic", mood="grin", crowned=False, collar=True, hat=True, cone=True, face=True):
    """Balatro-style jester bust. (cx, cy) = face centre, s = size (8 ~ the base Joker)."""
    hl, hl2, hr, hr2, cc, cl, cd = PALETTES[pal]
    u = s / 8
    if collar:
        pts = [(-6, 6), (-17, 10), (-16, 15), (-10, 13), (-9, 20), (-4, 15), (0, 22), (4, 15), (9, 20), (10, 13), (16, 15), (17, 10), (6, 6)]
        body = P(cx, cy, u, pts)
        tips = [(cx + x * u, cy + y * u) for x, y in ((-16, 15), (-9, 20), (0, 22), (9, 20), (16, 15))]
        def cfill(x, y):
            for tx, ty in tips:
                if abs(x - tx) <= 1.2 * u and abs(y - ty) <= 1.6 * u: return cd
            if y < cy + 8.5 * u: return cl
            ang = math.atan2(y - cy, x - cx)
            return cl if abs(math.sin(ang * 5)) < 0.12 and y < cy + 15 * u else cc
        c.shape(body, cfill)
    if face:
        face = ellipse(cx, cy, 7.5 * u, 8.5 * u)
        c.shape(face, lambda x, y: GRAY if x < cx - 4.5 * u and y > cy else WHITE)
        # eyes: orange masks + pupils
        for side in (-1, 1):
            ex = cx + side * 3.5 * u; ey = cy - 1 * u
            mask = ellipse(ex, ey, 2 * u, 1 * u) if s >= 6 else set()
            for x, y in mask: c.put(x, y, ORANGE)
            if mood == "laugh":
                c.put(ex - 1, ey + 1, OUT); c.put(ex, ey, OUT); c.put(ex + 1, ey + 1, OUT)
            elif mood == "angry":
                c.put(ex, ey, OUT); c.put(ex - side, ey, OUT) if s >= 6 else None
                c.put(ex - side * 2 * u, ey - 2 * u, OUT); c.put(ex - side * 1 * u, ey - 1.5 * u, OUT); c.put(ex, ey - 1.5 * u, OUT) if s >= 6 else None
            else:
                c.put(ex, ey, OUT)
                if s >= 6: c.put(ex - side, ey, OUT)
                if mood == "sad" and s >= 5: c.put(ex + side * 1.5 * u, ey - 1.5 * u, OUT)
        if s >= 6: c.put(cx, cy + 1 * u, GRAY2)
        my = cy + 3.5 * u
        if mood in ("grin", "laugh", "angry"):
            big = ellipse(cx, my, 5 * u, (3.2 if mood == "laugh" else 2.4) * u)
            cut = {(x, y) for x, y in ellipse(cx, my - 2.2 * u, 5.5 * u, 2.4 * u)} if mood != "laugh" else {(x, y) for x, y in big if y < my - 1.5 * u}
            mouth = big - cut
            for x, y in mouth: c.put(x, y, RED3 if (mood == "laugh" and y > my - 0.5 * u and abs(x - cx) < 3 * u) else RED)
            if s >= 6:
                top = min((y for _, y in mouth), default=my)
                for x, y in mouth:
                    if y == top and abs(x - cx) < 4 * u: c.put(x, y, WHITE)
            if mood == "laugh" and s >= 6:
                c.put(cx - 7 * u, cy + 1 * u, BLUE_L); c.put(cx + 7 * u, cy + 1 * u, BLUE_L)
        elif mood == "sad":
            for x in range(round(cx - 3 * u), round(cx + 3 * u) + 1): c.put(x, my, RED)
            c.put(cx - 3 * u - 1, my + 1, RED); c.put(cx + 3 * u + 1, my + 1, RED)
    if hat:
        flap = [(-2, -7), (-9, -10), (-15, -8), (-17, -3), (-16, 0), (-13, -4), (-8, -5), (-6, -3)]
        shade = lambda a, b: (lambda x, y: b if y > cy - 5 * u else a)
        c.shape(P(cx, cy, u, flap), shade(hr, hr2))
        c.shape(flip(P(cx, cy, u, flap), cx), shade(hr, hr2))
        pr = max(1, 1.6 * u)
        c.shape(ellipse(cx - 16 * u, cy + 1 * u, pr, pr), WHITE)
        c.shape(ellipse(cx + 16 * u, cy + 1 * u, pr, pr), WHITE)
        if crowned:
            band = P(cx, cy, u, [(-7, -5), (-6, -9), (6, -9), (7, -5), (0, -7)])
            c.shape(band, hl)
            crown(c, round(cx), round(cy - 9 * u - max(5, 7 * u)), w=max(3, round(5 * u)), h=max(5, round(7 * u)))
        elif cone:
            cone_pts = [(-7, -5), (-6, -12), (-1, -18), (5, -21), (10, -20), (8, -17), (5, -13), (7, -5), (0, -7)]
            c.shape(P(cx, cy, u, cone_pts), lambda x, y: hl2 if x > cx + 4 * u and y > cy - 12 * u else hl)
            c.shape(ellipse(cx + 10 * u, cy - 18 * u, pr, pr), WHITE)
    elif crowned:
        crown(c, round(cx), round(cy - 8.5 * u - max(5, 7 * u)), w=max(3, round(5 * u)), h=max(5, round(7 * u)))
    return True
