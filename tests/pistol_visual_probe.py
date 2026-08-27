#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw
import math
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = Path("/tmp/pistol_visual_audit")
OUT.mkdir(parents=True, exist_ok=True)

PISTOLS = ("p01", "p07", "p14", "p20")
FIRST_PERSON = [
    "idle",
    *[f"fire_{i}" for i in range(1, 5)],
    *[f"reload_{i}" for i in range(1, 5)],
    "zoom",
    *[f"aim_fire_{i}" for i in range(1, 5)],
]
SERIES = {
    "fire": [f"fire_{i}" for i in range(1, 5)],
    "reload": [f"reload_{i}" for i in range(1, 5)],
    "aim_fire": [f"aim_fire_{i}" for i in range(1, 5)],
}


def alpha_stats(path: Path) -> dict[str, object]:
    im = Image.open(path).convert("RGBA")
    alpha = im.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise AssertionError("alpha tamamen boş")
    hist = alpha.histogram()
    nonzero = sum(hist[1:])
    opaque = hist[255]
    semi = nonzero - opaque
    coverage = nonzero / (im.width * im.height)

    total = 0
    sx = 0
    sy = 0
    px = alpha.load()
    for y in range(im.height):
        for x in range(im.width):
            a = px[x, y]
            if a:
                total += a
                sx += x * a
                sy += y * a
    cx = sx / total
    cy = sy / total
    left, top, right, bottom = bbox
    # hud_weapon_presenter.gd içindeki _get_texture_visual_anchor ile aynı hesap.
    anchor = (
        left + (right - left) * 0.5 - im.width * 0.5,
        bottom - im.height * 0.5,
    )
    return {
        "size": im.size,
        "bbox": bbox,
        "center": (cx, cy),
        "anchor": anchor,
        "coverage": coverage,
        "semi": semi,
        "opaque": opaque,
    }


def checker(size: tuple[int, int], cell: int = 32) -> Image.Image:
    w, h = size
    out = Image.new("RGB", size, (42, 42, 42))
    draw = ImageDraw.Draw(out)
    for y in range(0, h, cell):
        for x in range(0, w, cell):
            if ((x // cell) + (y // cell)) % 2:
                draw.rectangle((x, y, min(x + cell - 1, w - 1), min(y + cell - 1, h - 1)), fill=(58, 58, 58))
    return out


def make_sheet(weapon: str, files: list[Path]) -> None:
    thumb_w, thumb_h = 384, 256
    label_h = 30
    cols = 5
    rows = math.ceil(len(files) / cols)
    sheet = Image.new("RGB", (cols * thumb_w, rows * (thumb_h + label_h)), (26, 26, 26))
    draw = ImageDraw.Draw(sheet)
    for idx, path in enumerate(files):
        rgba = Image.open(path).convert("RGBA")
        bg = checker(rgba.size, 64).convert("RGBA")
        bg.alpha_composite(rgba)
        frame = bg.convert("RGB")
        frame.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        col = idx % cols
        row = idx // cols
        x0 = col * thumb_w
        y0 = row * (thumb_h + label_h)
        x = x0 + (thumb_w - frame.width) // 2
        y = y0 + (thumb_h - frame.height) // 2
        sheet.paste(frame, (x, y))
        draw.text((x0 + 8, y0 + thumb_h + 6), path.name, fill=(240, 240, 240))
    sheet.save(OUT / f"{weapon}_contact_sheet.jpg", quality=94)


def parse_vec2(text: str, key: str) -> tuple[float, float]:
    match = re.search(rf'^{re.escape(key)}\s*=\s*Vector2\(([-0-9.]+),\s*([-0-9.]+)\)$', text, re.M)
    return (float(match.group(1)), float(match.group(2))) if match else (0.0, 0.0)


def presenter_alignment_report(weapon: str, stats: dict[tuple[str, str], dict[str, object]]) -> None:
    resource_text = (ROOT / "resources" / "weapons" / f"{weapon}.tres").read_text(encoding="utf-8")
    zoom_offset = parse_vec2(resource_text, "hud_zoom_offset")
    aim_offset = parse_vec2(resource_text, "hud_aim_fire_offset")
    preserve = bool(re.search(r'^hud_aim_fire_preserve_frame_motion\s*=\s*true$', resource_text, re.M))
    idle = stats.get((weapon, "idle"))
    zoom = stats.get((weapon, "zoom"))
    if not idle or not zoom:
        return
    idle_anchor = idle["anchor"]
    zoom_anchor = (zoom["anchor"][0] + zoom_offset[0], zoom["anchor"][1] + zoom_offset[1])
    print(f"PRESENTER {weapon}: zoom_offset={zoom_offset} preserve_aim_motion={preserve}")
    for stem in FIRST_PERSON:
        stat = stats.get((weapon, stem))
        if stat is None:
            continue
        anchor = stat["anchor"]
        if stem == "zoom":
            offset = zoom_offset
        elif stem.startswith("aim_fire_"):
            if preserve:
                offset = (zoom_offset[0] + aim_offset[0], zoom_offset[1] + aim_offset[1])
            else:
                offset = (
                    zoom_anchor[0] - anchor[0] + aim_offset[0],
                    zoom_anchor[1] - anchor[1] + aim_offset[1],
                )
        else:
            offset = (idle_anchor[0] - anchor[0], idle_anchor[1] - anchor[1])
        print(f"  {stem:12s} anchor=({anchor[0]:+.1f},{anchor[1]:+.1f}) presenter_offset=({offset[0]:+.1f},{offset[1]:+.1f})")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    all_stats: dict[tuple[str, str], dict[str, object]] = {}

    for weapon in PISTOLS:
        folder = ROOT / "assets" / "weapons" / weapon
        files: list[Path] = []
        print(f"=== {weapon.upper()} ===")
        for stem in FIRST_PERSON:
            path = folder / f"{weapon}_{stem}.png"
            if not path.exists():
                errors.append(f"{weapon}: eksik {path.name}")
                continue
            files.append(path)
            try:
                stat = alpha_stats(path)
            except Exception as exc:
                errors.append(f"{weapon}: {path.name}: {exc}")
                continue
            all_stats[(weapon, stem)] = stat
            size = stat["size"]
            bbox = stat["bbox"]
            center = stat["center"]
            anchor = stat["anchor"]
            coverage = float(stat["coverage"])
            print(
                f"{path.name:24s} size={size[0]}x{size[1]} "
                f"bbox={bbox} center=({center[0]:.1f},{center[1]:.1f}) "
                f"anchor=({anchor[0]:+.1f},{anchor[1]:+.1f}) "
                f"coverage={coverage:.3f} semi={stat['semi']}"
            )
            if size != (1536, 1024):
                errors.append(f"{weapon}: {path.name} first-person standardı 1536x1024 değil: {size}")
            if coverage > 0.82:
                errors.append(f"{weapon}: {path.name} alpha coverage aşırı yüksek ({coverage:.3f}); arka plan şeffaf olmayabilir")
            if coverage < 0.02:
                warnings.append(f"{weapon}: {path.name} görünür içerik çok küçük ({coverage:.3f})")
            left, top, right, bottom = bbox
            touching = []
            if left <= 1: touching.append("sol")
            if top <= 1: touching.append("üst")
            if right >= size[0] - 1: touching.append("sağ")
            if bottom >= size[1] - 1: touching.append("alt")
            if touching:
                warnings.append(f"{weapon}: {path.name} içerik PNG sınırına dayanıyor: {','.join(touching)}")

        if files:
            make_sheet(weapon, files)

        for series_name, stems in SERIES.items():
            prev = None
            print(f"SERIES {weapon} {series_name}")
            for stem in stems:
                stat = all_stats.get((weapon, stem))
                if stat is None:
                    continue
                center = stat["center"]
                bbox = stat["bbox"]
                if prev is not None:
                    pc = prev["center"]
                    pb = prev["bbox"]
                    dx = center[0] - pc[0]
                    dy = center[1] - pc[1]
                    print(f"  {stem}: dCenter=({dx:+.1f},{dy:+.1f}) dBBox=({bbox[0]-pb[0]:+d},{bbox[1]-pb[1]:+d},{bbox[2]-pb[2]:+d},{bbox[3]-pb[3]:+d})")
                    if abs(dx) > 220 or abs(dy) > 220:
                        errors.append(f"{weapon} {series_name}: ani frame merkez sıçraması {dx:+.1f},{dy:+.1f} @ {stem}")
                prev = stat

        for a, b, label, limit in [
            ("idle", "fire_1", "idle->fire_1", 180.0),
            ("zoom", "aim_fire_1", "zoom->aim_fire_1", 180.0),
        ]:
            sa = all_stats.get((weapon, a))
            sb = all_stats.get((weapon, b))
            if sa and sb:
                ca, cb = sa["center"], sb["center"]
                dist = math.hypot(cb[0] - ca[0], cb[1] - ca[1])
                print(f"TRANSITION {weapon} {label}: center distance={dist:.1f}")
                if dist > limit:
                    warnings.append(f"{weapon}: {label} alpha merkezi {dist:.1f}px değişiyor; görsel sıçrama açısından kontrol et")
        presenter_alignment_report(weapon, all_stats)

    print("\n=== WARNINGS ===")
    for item in warnings:
        print("WARNING:", item)
    print("\n=== ERRORS ===")
    for item in errors:
        print("ERROR:", item)
    print(f"PISTOL VISUAL PROBE: {len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
