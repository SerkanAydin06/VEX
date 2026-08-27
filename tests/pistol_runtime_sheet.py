#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = Path('/tmp/pistol_visual_audit')
OUT.mkdir(parents=True, exist_ok=True)
PISTOLS = ('p01', 'p07', 'p14', 'p20')
STEMS = [
    'idle',
    *[f'fire_{i}' for i in range(1, 5)],
    *[f'reload_{i}' for i in range(1, 5)],
    'zoom',
    *[f'aim_fire_{i}' for i in range(1, 5)],
]
SCREEN = (1920, 1080)
PIVOT = (960.0, 540.0)


def vec2(text: str, key: str, default: tuple[float, float]) -> tuple[float, float]:
    m = re.search(rf'^{re.escape(key)}\s*=\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)$', text, re.M)
    return (float(m.group(1)), float(m.group(2))) if m else default


def scalar(text: str, key: str, default: float) -> float:
    m = re.search(rf'^{re.escape(key)}\s*=\s*([-0-9.]+)$', text, re.M)
    return float(m.group(1)) if m else default


def anchor(im: Image.Image) -> tuple[float, float]:
    bbox = im.getchannel('A').getbbox()
    if bbox is None:
        return (0.0, 0.0)
    l, t, r, b = bbox
    return (l + (r-l)*0.5 - im.width*0.5, b - im.height*0.5)


def checker() -> Image.Image:
    out = Image.new('RGBA', SCREEN, (35,35,35,255))
    d = ImageDraw.Draw(out)
    cell = 64
    for y in range(0, SCREEN[1], cell):
        for x in range(0, SCREEN[0], cell):
            if ((x//cell)+(y//cell)) % 2:
                d.rectangle((x,y,min(x+cell-1,SCREEN[0]-1),min(y+cell-1,SCREEN[1]-1)), fill=(47,47,47,255))
    return out


def draw_reticle(screen: Image.Image, style: str) -> None:
    d = ImageDraw.Draw(screen)
    x, y = int(PIVOT[0]), int(PIVOT[1])
    if style == 'red_dot':
        d.ellipse((x-4,y-4,x+4,y+4), fill=(15,15,15,230))
        d.ellipse((x-2,y-2,x+2,y+2), fill=(255,30,20,255))
    else:
        d.line((x-5,y,x+5,y), fill=(255,255,255,255), width=1)
        d.line((x,y-5,x,y+5), fill=(255,255,255,255), width=1)


def main() -> int:
    for weapon in PISTOLS:
        resource = (ROOT/'resources'/'weapons'/f'{weapon}.tres').read_text(encoding='utf-8')
        scene = (ROOT/'scenes'/'ui'/'weapons'/f'{weapon}_view.tscn').read_text(encoding='utf-8')
        base_pos = vec2(scene, 'position', (1060.0, 772.0))
        base_scale = vec2(scene, 'scale', (0.6, 0.6))
        zoom_offset = vec2(resource, 'hud_zoom_offset', (0.0,0.0))
        aim_offset = vec2(resource, 'hud_aim_fire_offset', (0.0,0.0))
        ads_mult = scalar(resource, 'hud_ads_scale_multiplier', 1.0)
        preserve = bool(re.search(r'^hud_aim_fire_preserve_frame_motion\s*=\s*true$', resource, re.M))
        style = 'red_dot' if 'hud_ads_reticle_style = "red_dot"' in resource else 'small_cross'

        folder = ROOT/'assets'/'weapons'/weapon
        images = {stem: Image.open(folder/f'{weapon}_{stem}.png').convert('RGBA') for stem in STEMS}
        anchors = {stem: anchor(im) for stem, im in images.items()}
        idle_anchor = anchors['idle']
        zoom_anchor = (anchors['zoom'][0] + zoom_offset[0], anchors['zoom'][1] + zoom_offset[1])

        tiles: list[Image.Image] = []
        for stem in STEMS:
            if stem == 'zoom':
                off = zoom_offset
            elif stem.startswith('aim_fire_'):
                if preserve:
                    off = (zoom_offset[0] + aim_offset[0], zoom_offset[1] + aim_offset[1])
                else:
                    off = (zoom_anchor[0]-anchors[stem][0]+aim_offset[0], zoom_anchor[1]-anchors[stem][1]+aim_offset[1])
            else:
                off = (idle_anchor[0]-anchors[stem][0], idle_anchor[1]-anchors[stem][1])

            ads = stem == 'zoom' or stem.startswith('aim_fire_')
            if ads and ads_mult > 1.0:
                pos = (
                    PIVOT[0] + (base_pos[0]-PIVOT[0]) * ads_mult,
                    PIVOT[1] + (base_pos[1]-PIVOT[1]) * ads_mult,
                )
                sx, sy = base_scale[0]*ads_mult, base_scale[1]*ads_mult
            else:
                pos = base_pos
                sx, sy = base_scale

            im = images[stem]
            scaled = im.resize((max(1, round(im.width*sx)), max(1, round(im.height*sy))), Image.Resampling.LANCZOS)
            center_x = pos[0] + off[0]*sx
            center_y = pos[1] + off[1]*sy
            x = round(center_x - scaled.width/2)
            y = round(center_y - scaled.height/2)
            screen = checker()
            screen.alpha_composite(scaled, (x,y))
            if ads:
                draw_reticle(screen, style)
            tiles.append(screen.convert('RGB'))

        tw, th = 480, 270
        label_h = 26
        cols = 5
        rows = math.ceil(len(tiles)/cols)
        sheet = Image.new('RGB', (cols*tw, rows*(th+label_h)), (20,20,20))
        d = ImageDraw.Draw(sheet)
        for i, (stem, tile) in enumerate(zip(STEMS, tiles)):
            tile = tile.resize((tw,th), Image.Resampling.LANCZOS)
            c, r = i%cols, i//cols
            x0, y0 = c*tw, r*(th+label_h)
            sheet.paste(tile, (x0,y0))
            d.text((x0+6,y0+th+5), f'{weapon}_{stem}', fill=(240,240,240))
        sheet.save(OUT/f'{weapon}_runtime_sheet.jpg', quality=94)

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
