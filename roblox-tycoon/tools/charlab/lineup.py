#!/usr/bin/env python3
"""Build a side-by-side lineup of every character from check_all.py renders.

    python3 tools/charlab/check_all.py --luau path/to/luau --out previews/
    python3 tools/charlab/lineup.py previews/ --out lineup.png [--view front|three_quarter|side|back|closeup]

Characters are ordered by rarity (the order their droppers unlock in Items.luau).
"""
import argparse
import os
import re

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

RARITY_COLORS = {
    "Common": (190, 190, 205), "Uncommon": (90, 230, 110), "Rare": (70, 170, 255),
    "Epic": (185, 95, 255), "Legendary": (255, 205, 60), "Mythic": (255, 70, 140), "Secret": (255, 255, 255),
}
# Tile positions in the charlab contact sheet (5 columns x 2 rows).
VIEWS = {"front": (0, 0), "three_quarter": (1, 0), "side": (2, 0), "back": (3, 0), "closeup": (2, 1)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("renders", help="directory with <Id>.png contact sheets from check_all.py")
    ap.add_argument("--out", required=True)
    ap.add_argument("--view", default="three_quarter", choices=sorted(VIEWS))
    args = ap.parse_args()

    with open(os.path.join(ROOT, "src", "shared", "Items.luau"), encoding="utf-8") as f:
        ids = re.findall(r'Character = "(\w+)"', f.read())
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 17)
        small = ImageFont.truetype("DejaVuSans-Bold.ttf", 14)
    except OSError:
        font = small = ImageFont.load_default()

    cards = []
    for cid in ids:
        path = os.path.join(args.renders, cid + ".png")
        src_path = os.path.join(ROOT, "src", "shared", "Characters", cid + ".luau")
        if not os.path.exists(path) or not os.path.exists(src_path):
            continue
        with open(src_path, encoding="utf-8") as f:
            src = f.read()
        # The character's display Name follows its Id in the returned table (helper functions
        # earlier in the file also use Name = "..." for parts).
        name_match = re.search(r'Id\s*=\s*"' + cid + r'"\s*,\s*Name\s*=\s*"([^"]+)"', src)
        name = name_match.group(1) if name_match else cid
        rarity = (re.search(r'Rarity\s*=\s*"(\w+)"', src) or [None, "Common"])[1]
        sheet = Image.open(path)
        tw, th = sheet.width // 5, sheet.height // 2
        col, row = VIEWS[args.view]
        tile = sheet.crop((col * tw, row * th + 22, (col + 1) * tw, (row + 1) * th))
        color = RARITY_COLORS.get(rarity, (255, 255, 255))
        card = Image.new("RGB", (tw, tile.height + 52), (26, 20, 44))
        card.paste(tile, (0, 0))
        draw = ImageDraw.Draw(card)
        draw.text((tw // 2, tile.height + 6), name, fill=(255, 255, 255), font=font, anchor="mt")
        draw.text((tw // 2, tile.height + 30), rarity.upper() if rarity == "Secret" else rarity,
                  fill=color, font=small, anchor="mt")
        draw.rectangle([0, 0, tw - 1, card.height - 1], outline=color, width=3)
        cards.append(card)

    if not cards:
        raise SystemExit("No renders found - run check_all.py first")
    cols = 6
    rows = (len(cards) + cols - 1) // cols
    cw, ch = cards[0].size
    out = Image.new("RGB", (cw * cols, ch * rows + 40), (18, 14, 30))
    draw = ImageDraw.Draw(out)
    draw.text((out.width // 2, 8), f"ALL BRAINROTS - {args.view.replace('_', ' ')} view (Common -> Secret)",
              fill=(255, 220, 80), font=font, anchor="mt")
    for i, card in enumerate(cards):
        out.paste(card, ((i % cols) * cw, 40 + (i // cols) * ch))
    out.save(args.out)
    print(f"Wrote {args.out} ({len(cards)} characters)")


if __name__ == "__main__":
    main()
