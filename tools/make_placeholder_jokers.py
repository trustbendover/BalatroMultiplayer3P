#!/usr/bin/env python3
"""PLACEHOLDER art for the special 3-player jokers (mod/assets/{1x,2x}/j_<key>.png).
Simple pixel-style cards in the Balatro card frame; replace with real art later."""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "mod", "assets")
EDGE, WHITE, INK = (191, 199, 213, 255), (255, 255, 255, 255), (55, 66, 74, 255)
RED, GOLD, BLUE, GREEN, PURPLE = (254, 95, 85, 255), (234, 192, 88, 255), (0, 147, 255, 255), (75, 194, 146, 255), (133, 103, 207, 255)


def frame(bg):
    im = Image.new("RGBA", (71, 95), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([1, 1, 69, 93], radius=4, fill=EDGE)
    d.rounded_rectangle([2, 2, 68, 92], radius=3, fill=WHITE)
    d.rounded_rectangle([5, 5, 65, 89], radius=2, fill=bg)
    return im, d


def person(d, x, y, col, crown=False, x_eyes=False):
    d.ellipse([x - 5, y - 5, x + 5, y + 5], fill=col, outline=INK)
    d.rectangle([x - 6, y + 7, x + 6, y + 20], fill=col, outline=INK)
    if x_eyes:
        for ex in (x - 3, x + 2):
            d.line([ex - 1, y - 2, ex + 1, y], fill=INK); d.line([ex - 1, y, ex + 1, y - 2], fill=INK)
    else:
        d.point([(x - 2, y - 1), (x + 2, y - 1)], fill=INK)
    if crown:
        d.polygon([(x - 5, y - 6), (x - 5, y - 11), (x - 2, y - 8), (x, y - 12), (x + 2, y - 8), (x + 5, y - 11), (x + 5, y - 6)], fill=GOLD, outline=INK)


def label(d, text):
    d.rectangle([8, 76, 62, 86], fill=WHITE, outline=INK)
    d.text((35 - 3 * len(text), 77), text, fill=INK)


def draw(key):
    if key == "third_wheel":
        im, d = frame((96, 166, 255, 255))
        d.ellipse([10, 30, 34, 54], outline=INK, width=3); d.ellipse([37, 30, 61, 54], outline=INK, width=3)
        d.ellipse([24, 52, 46, 74], outline=RED, width=3); label(d, "3RD")
    elif key == "vulture":
        im, d = frame((120, 96, 80, 255))
        d.polygon([(35, 22), (12, 40), (24, 40), (35, 50), (46, 40), (58, 40)], fill=INK)
        d.ellipse([31, 16, 39, 24], fill=RED); d.polygon([(39, 20), (44, 22), (39, 23)], fill=GOLD); label(d, "X-1")
    elif key == "laughing_third":
        im, d = frame((255, 214, 102, 255))
        person(d, 18, 30, BLUE); person(d, 52, 30, RED)
        d.line([24, 40, 46, 40], fill=INK, width=2); d.ellipse([27, 50, 43, 66], fill=WHITE, outline=INK)
        d.arc([30, 55, 40, 63], 0, 180, fill=INK, width=2); label(d, "HAHA")
    elif key == "kingslayer":
        im, d = frame((70, 70, 90, 255))
        d.polygon([(22, 40), (22, 26), (29, 33), (35, 22), (41, 33), (48, 26), (48, 40)], fill=GOLD, outline=INK)
        d.line([18, 66, 54, 18], fill=WHITE, width=3); d.line([16, 60, 24, 68], fill=GOLD, width=3); label(d, "X2")
    elif key == "bounty_hunter":
        im, d = frame((214, 170, 110, 255))
        d.rectangle([14, 14, 56, 70], fill=(245, 230, 200, 255), outline=INK)
        d.text((20, 16), "WANTED", fill=INK); person(d, 35, 36, RED, crown=True); d.text((26, 60), "$$$", fill=GREEN)
        label(d, "BOUNTY")
    elif key == "middle_of_the_pack":
        im, d = frame((150, 200, 150, 255))
        d.rectangle([8, 40, 24, 70], fill=WHITE, outline=INK); d.rectangle([27, 52, 43, 70], fill=GOLD, outline=INK)
        d.rectangle([46, 60, 62, 70], fill=WHITE, outline=INK); person(d, 35, 26, BLUE); label(d, "2ND")
    elif key == "triumvirate":
        im, d = frame((133, 103, 207, 255))
        person(d, 18, 34, BLUE); person(d, 35, 26, GOLD, crown=True); person(d, 52, 34, RED); label(d, "X3")
    else:
        raise SystemExit(key)
    d.text((54, 6), "3P", fill=WHITE)
    return im


KEYS = ["third_wheel", "vulture", "laughing_third", "kingslayer", "bounty_hunter", "middle_of_the_pack", "triumvirate"]
if __name__ == "__main__":
    for k in KEYS:
        im = draw(k)
        im.save(os.path.join(ROOT, "1x", f"j_{k}.png"))
        im.resize((142, 190), Image.NEAREST).save(os.path.join(ROOT, "2x", f"j_{k}.png"))
    print("wrote", len(KEYS), "placeholder jokers")
