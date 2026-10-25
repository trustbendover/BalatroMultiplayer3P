"""Draws the 7 special 3-player jokers. Usage: python3 j3p_cards.py <assets dir (contains 1x/ and 2x/)>"""
import math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from j3p_art import *


def coins(c, cx, ys, rx=8):
    for cy in ys:
        c.shape(ellipse(cx, cy, rx, 3), lambda x, y, cy=cy: GOLD_L if y < cy - 1 else (GOLD_D if y > cy + 1 else GOLD))
        for x in range(cx - 2, cx + 3): c.put(x, cy, GOLD_D)


def heart(c, cx, cy, r=3):
    cells = ellipse(cx - r + 0.5, cy, r - 0.5, r - 0.5) | ellipse(cx + r - 0.5, cy, r - 0.5, r - 0.5) | poly([(cx - 2 * r + 0.5, cy + 0.5), (cx + 2 * r + 0.5, cy + 0.5), (cx + 0.5, cy + 2 * r + 1)])
    c.shape(cells, lambda x, y: PINK if (x, y) in ((cx - r, cy - 1), (cx - r + 1, cy - 1)) else RED)


def rot(points, ang, ox, oy):
    ca, sa = math.cos(ang), math.sin(ang)
    return [(ox + (x - ox) * ca - (y - oy) * sa, oy + (x - ox) * sa + (y - oy) * ca) for x, y in points]


def bounty_hunter():
    c = Card()
    poster = rect(15, 8, 55, 70) - {(15, 8), (55, 8), (15, 70), (16, 70), (55, 70), (55, 69), (54, 70)}
    c.shape(poster, lambda x, y: PAPER2 if x >= 54 or y >= 68 else PAPER)
    c.shape(rect(34, 10, 36, 12), lambda x, y: WHITE if (x, y) == (34, 10) else GRAY)  # nail
    jester(c, 35, 37, 7, pal="classic", crowned=True)
    for x in range(20, 51):
        if abs(x - CX) not in (5, 11): c.put(x, 61, PAPER3)
    for x in range(24, 47):
        if abs(x - CX) != 4: c.put(x, 64, PAPER3)
    coins(c, 35, (84, 80, 76, 72), rx=9)
    return c


def third_wheel():
    c = Card()
    jester(c, 25, 33, 5, pal="blue")
    jester(c, 45, 33, 5, pal="purple")
    heart(c, 35, 13, 3)
    jester(c, 35, 64, 6.5, pal="classic", mood="sad")
    return c


def vulture():
    c = Card()
    # branch
    c.shape(rect(14, 78, 56, 81), lambda x, y: BROWN_L if y == 78 else BROWN)
    c.shape(rect(46, 74, 48, 77), BROWN)
    # wings + body
    wing = [(35, 40), (22, 38), (15, 46), (14, 58), (17, 56), (17, 64), (21, 61), (22, 70), (27, 66), (30, 74), (35, 72)]
    wl = poly(wing); c.shape(mirror(wl), lambda x, y: BROWN_D if y > 64 or abs(x - CX) > 15 else (BROWN_L if (x + y) % 5 == 0 and abs(x - CX) > 6 else BROWN))
    c.shape(ellipse(35, 56, 8, 13), lambda x, y: BROWN_L if abs(x - CX) < 3 and y > 50 else BROWN)
    # ruff of feathers (white) and bald pink neck
    c.shape(ellipse(35, 42, 8, 4), lambda x, y: GRAY if y > 43 else WHITE)
    c.shape(rect(33, 33, 37, 40), lambda x, y: PINK_D if x == 33 else PINK)
    # claws on the branch, holding a coin
    for x0 in (29, 39):
        c.shape(rect(x0, 72, x0 + 2, 77), ORANGE2)
    c.shape(ellipse(35, 75, 3, 3), lambda x, y: GOLD_L if y < 74 else GOLD)
    # head
    c.shape(ellipse(35, 29, 6, 5), lambda x, y: PINK_D if x < 31 and y > 29 else PINK)
    beak = poly([(37, 29), (44, 29), (47, 32), (46, 37), (44, 34), (38, 34)])
    c.shape(beak, lambda x, y: GOLD_D if y > 33 else GOLD)
    for x in (32, 33, 37, 38): c.put(x, 29, OUT)
    c.put(32, 28, RED); c.put(38, 28, RED)
    jester(c, 35, 26, 6, pal="classic", collar=False, face=False)
    return c


def laughing_third():
    c = Card()
    jester(c, 24, 28, 4.6, pal="blue", mood="angry")
    jester(c, 46, 28, 4.6, pal="purple", mood="angry")
    star = poly([(35, 14), (37, 20), (43, 20), (38, 24), (40, 30), (35, 26), (30, 30), (32, 24), (27, 20), (33, 20)])
    c.shape(star, lambda x, y: GOLD_L if abs(x - CX) < 2 and y < 24 else GOLD)
    jester(c, 35, 63, 7, pal="classic", mood="laugh")
    return c


def kingslayer():
    c = Card()
    # sword held diagonally (behind the jester), hilt bottom left, tip top right
    blade = poly([(21, 66), (24, 69), (56, 13), (56, 9), (53, 11)])
    c.shape(blade, lambda x, y: SILVER_L if (x - 21) * 0.86 + (y - 66) * 0.5 < 0.6 else SILVER)
    guard = poly([(15, 63), (17, 61), (29, 70), (27, 72)])
    c.shape(guard, lambda x, y: GOLD_L if y < 66 else GOLD)
    c.shape(poly([(16, 71), (19, 69), (22, 73), (19, 76)]), BROWN)
    c.shape(ellipse(16, 76, 1.5, 1.5), GOLD)
    jester(c, 35, 38, 8, pal="red", mood="grin")
    # the fallen crown, tipped over in front
    pts = [(-8, 0), (8, 0), (8, -6), (5, -11), (3, -6), (0, -12), (-3, -6), (-5, -11), (-8, -6)]
    cr = poly(rot([(35 + x, 84 + y) for x, y in pts], 0.3, 35, 84))
    c.shape(cr, lambda x, y: GOLD_L if y < 77 else (GOLD_D if y > 82 else GOLD))
    c.put(35, 78, RED); c.put(36, 78, RED); c.put(30, 76, BLUE); c.put(40, 80, BLUE)
    return c


def middle_of_the_pack():
    c = Card()
    c.shape(rect(15, 58, 27, 85), lambda x, y: GOLD_L if y == 58 else (GOLD_D if x == 27 else GOLD))
    c.shape(rect(29, 66, 41, 85), lambda x, y: SILVER_L if y == 66 else (SILVER_D if x == 41 else SILVER))
    c.shape(rect(43, 74, 55, 85), lambda x, y: BRONZE_L if y == 74 else (BRONZE_D if x == 55 else BRONZE))
    c.put(21, 70, GOLD_D)  # pips: 1 / 2 / 3
    c.put(34, 76, SILVER_D); c.put(36, 76, SILVER_D)
    c.put(47, 80, BRONZE_D); c.put(49, 80, BRONZE_D); c.put(51, 80, BRONZE_D)
    jester(c, 35, 44, 8, pal="green", mood="grin")
    return c


def triumvirate():
    c = Card()
    jester(c, 23, 34, 4.8, pal="blue", crowned=True)
    jester(c, 47, 34, 4.8, pal="purple", crowned=True)
    jester(c, 35, 55, 7, pal="classic", crowned=True)
    return c


CARDS = {
    "bounty_hunter": bounty_hunter, "third_wheel": third_wheel, "vulture": vulture, "laughing_third": laughing_third,
    "kingslayer": kingslayer, "middle_of_the_pack": middle_of_the_pack, "triumvirate": triumvirate,
}

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "out"
    for k, f in CARDS.items(): f().save(k, out)
    print("wrote", len(CARDS), "jokers to", out)
