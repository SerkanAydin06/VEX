#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import statistics
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
WEAPONS = ("p01", "p07", "p14", "p20")


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def load_png(path: Path) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"PNG değil: {path}")
    pos = 8
    width = height = bit_depth = color_type = None
    idat = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, comp, filt, interlace = struct.unpack(">IIBBBBB", payload)
            if bit_depth != 8 or interlace != 0:
                raise ValueError(f"Desteklenmeyen PNG: depth={bit_depth}, interlace={interlace}")
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break
    channels = {6: 4, 2: 3, 0: 1}.get(color_type)
    if channels is None:
        raise ValueError(f"Desteklenmeyen PNG color type: {color_type}")
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows: list[bytearray] = []
    offset = 0
    prev = bytearray(stride)
    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        scan = bytearray(raw[offset:offset + stride])
        offset += stride
        recon = bytearray(stride)
        for i, value in enumerate(scan):
            left = recon[i - channels] if i >= channels else 0
            up = prev[i]
            up_left = prev[i - channels] if i >= channels else 0
            if filter_type == 0:
                recon[i] = value
            elif filter_type == 1:
                recon[i] = (value + left) & 0xFF
            elif filter_type == 2:
                recon[i] = (value + up) & 0xFF
            elif filter_type == 3:
                recon[i] = (value + ((left + up) >> 1)) & 0xFF
            elif filter_type == 4:
                recon[i] = (value + _paeth(left, up, up_left)) & 0xFF
            else:
                raise ValueError(f"Bilinmeyen PNG filtresi: {filter_type}")
        rows.append(recon)
        prev = recon

    pixels: list[tuple[int, int, int, int]] = []
    for row in rows:
        for x in range(width):
            i = x * channels
            if color_type == 6:
                pixels.append((row[i], row[i + 1], row[i + 2], row[i + 3]))
            elif color_type == 2:
                pixels.append((row[i], row[i + 1], row[i + 2], 255))
            else:
                v = row[i]
                pixels.append((v, v, v, 255))
    return width, height, pixels


def rgba_at(pixels, width: int, x: int, y: int):
    return pixels[y * width + x]


def runs(values: list[bool]) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    start = None
    for i, on in enumerate(values + [False]):
        if on and start is None:
            start = i
        elif not on and start is not None:
            out.append((start, i - 1))
            start = None
    return out


def _row_runs(width: int, pixels, y: int, threshold: int = 64) -> list[tuple[int, int]]:
    values = [rgba_at(pixels, width, x, y)[3] >= threshold for x in range(width)]
    return runs(values)


def detect_sight(width: int, height: int, pixels) -> tuple[str, float, float, str]:
    cx = width // 2
    candidate_rows: list[tuple[int, int, int]] = []
    upper_limit = int(height * 0.48)
    for y in range(upper_limit):
        if any(rgba_at(pixels, width, x, y)[3] >= 64 for x in range(cx - 5, cx + 6)):
            continue
        left = None
        right = None
        for x in range(cx - 6, max(-1, cx - 280), -1):
            if rgba_at(pixels, width, x, y)[3] >= 64:
                left = x
                break
        for x in range(cx + 6, min(width, cx + 281)):
            if rgba_at(pixels, width, x, y)[3] >= 64:
                right = x
                break
        if left is not None and right is not None and 50 <= right - left <= 360:
            candidate_rows.append((y, left, right))

    groups: list[list[tuple[int, int, int]]] = []
    for item in candidate_rows:
        if not groups or item[0] != groups[-1][-1][0] + 1:
            groups.append([item])
        else:
            groups[-1].append(item)
    groups = [g for g in groups if len(g) >= 18]
    if groups:
        optic = max(groups, key=len)
        ys = [v[0] for v in optic]
        lefts = [v[1] for v in optic]
        rights = [v[2] for v in optic]
        sight_x = (statistics.median(lefts) + statistics.median(rights)) * 0.5
        sight_y = (ys[0] + ys[-1]) * 0.5
        detail = f"optic_window y={ys[0]}..{ys[-1]} inner_x~{statistics.median(lefts):.1f}..{statistics.median(rights):.1f}"
        return "optic", sight_x, sight_y, detail

    top_y = None
    top_run = None
    for y in range(upper_limit):
        row = _row_runs(width, pixels, y)
        nearby = [r for r in row if r[1] >= cx - 180 and r[0] <= cx + 180]
        if not nearby:
            continue
        chosen = min(nearby, key=lambda r: abs(((r[0] + r[1]) * 0.5) - cx))
        if chosen[1] - chosen[0] + 1 >= 2:
            top_y = y
            top_run = chosen
            break
    if top_y is None or top_run is None:
        return "unknown", float(cx), float(height // 2), "no central sight candidate"
    sight_x = (top_run[0] + top_run[1]) * 0.5
    detail = f"front_sight_top y={top_y} x_run={top_run[0]}..{top_run[1]}"
    return "iron", sight_x, float(top_y), detail


def alignment_offset(width: int, height: int, sight_x: float, sight_y: float) -> tuple[float, float]:
    # WeaponView sahnelerinin ortak tasarım koordinatları: pos=(1060,772), scale=0.6.
    target_x, target_y = 960.0, 540.0
    sprite_x, sprite_y = 1060.0, 772.0
    scale = 0.6
    local_target_x = (target_x - sprite_x) / scale
    local_target_y = (target_y - sprite_y) / scale
    texture_local_x = sight_x - width * 0.5
    texture_local_y = sight_y - height * 0.5
    return local_target_x - texture_local_x, local_target_y - texture_local_y


def analyze(weapon_id: str) -> None:
    path = ROOT / f"assets/weapons/{weapon_id}/{weapon_id}_zoom.png"
    width, height, pixels = load_png(path)
    opaque = [(i % width, i // width) for i, p in enumerate(pixels) if p[3] >= 32]
    xs = [p[0] for p in opaque]
    ys = [p[1] for p in opaque]
    bbox = (min(xs), min(ys), max(xs), max(ys)) if opaque else None
    cx = width // 2
    central_rows = [
        any(rgba_at(pixels, width, x, y)[3] >= 64 for x in range(cx - 6, cx + 7))
        for y in range(height // 2)
    ]
    kind, sight_x, sight_y, detail = detect_sight(width, height, pixels)
    off_x, off_y = alignment_offset(width, height, sight_x, sight_y)
    print(f"=== {weapon_id.upper()} ZOOM ===")
    print(f"size={width}x{height} alpha_bbox={bbox} center=({cx},{height // 2})")
    print(f"center-column opaque runs (upper half): {runs(central_rows)}")
    print(f"AUTO_SIGHT kind={kind} point=({sight_x:.1f},{sight_y:.1f}) {detail}")
    print(f"AUTO_OFFSET hud_zoom_offset=Vector2({round(off_x)}, {round(off_y)}) raw=({off_x:.2f},{off_y:.2f})")
    print()


def main() -> None:
    for weapon_id in WEAPONS:
        analyze(weapon_id)


if __name__ == "__main__":
    main()
