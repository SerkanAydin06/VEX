#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
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


def ascii_crop(width: int, height: int, pixels, cols: int = 96, rows: int = 44) -> list[str]:
    x0, x1 = int(width * 0.25), int(width * 0.75)
    y0, y1 = 0, int(height * 0.56)
    chars = " .:-=+*#%@"
    result: list[str] = []
    for ry in range(rows):
        sy0 = y0 + (y1 - y0) * ry // rows
        sy1 = y0 + (y1 - y0) * (ry + 1) // rows
        line = []
        for rx in range(cols):
            sx0 = x0 + (x1 - x0) * rx // cols
            sx1 = x0 + (x1 - x0) * (rx + 1) // cols
            total = max(1, (sx1 - sx0) * (sy1 - sy0))
            alpha_sum = 0
            for y in range(sy0, sy1):
                base = y * width
                for x in range(sx0, sx1):
                    alpha_sum += pixels[base + x][3]
            density = alpha_sum / (255.0 * total)
            idx = min(len(chars) - 1, int(density * len(chars)))
            line.append(chars[idx])
        result.append("".join(line))
    return result


def analyze(weapon_id: str) -> None:
    path = ROOT / f"assets/weapons/{weapon_id}/{weapon_id}_zoom.png"
    width, height, pixels = load_png(path)
    opaque = [(i % width, i // width) for i, p in enumerate(pixels) if p[3] >= 32]
    xs = [p[0] for p in opaque]
    ys = [p[1] for p in opaque]
    bbox = (min(xs), min(ys), max(xs), max(ys)) if opaque else None

    cx = width // 2
    central_rows: list[bool] = []
    for y in range(height // 2):
        central_rows.append(any(rgba_at(pixels, width, x, y)[3] >= 64 for x in range(cx - 6, cx + 7)))

    colored: dict[str, list[tuple[int, int]]] = {"red": [], "green": [], "blue": [], "bright": []}
    for y in range(int(height * 0.45)):
        for x in range(int(width * 0.35), int(width * 0.65)):
            r, g, b, a = rgba_at(pixels, width, x, y)
            if a < 96:
                continue
            if r > 160 and r > g * 1.35 and r > b * 1.35:
                colored["red"].append((x, y))
            if g > 160 and g > r * 1.25 and g > b * 1.20:
                colored["green"].append((x, y))
            if b > 160 and b > r * 1.25 and b > g * 1.15:
                colored["blue"].append((x, y))
            if min(r, g, b) > 210:
                colored["bright"].append((x, y))

    print(f"=== {weapon_id.upper()} ZOOM ===")
    print(f"size={width}x{height} alpha_bbox={bbox} center=({cx},{height // 2})")
    print(f"center-column opaque runs (upper half): {runs(central_rows)}")
    for name, points in colored.items():
        if not points:
            continue
        avg_x = sum(p[0] for p in points) / len(points)
        avg_y = sum(p[1] for p in points) / len(points)
        min_x = min(p[0] for p in points); max_x = max(p[0] for p in points)
        min_y = min(p[1] for p in points); max_y = max(p[1] for p in points)
        print(f"{name}: n={len(points)} centroid=({avg_x:.1f},{avg_y:.1f}) bbox=({min_x},{min_y})-({max_x},{max_y})")
    print("ASCII alpha crop: x=25%-75%, y=0%-56%")
    for line in ascii_crop(width, height, pixels):
        print(line)
    print()


def main() -> None:
    for weapon_id in WEAPONS:
        analyze(weapon_id)


if __name__ == "__main__":
    main()
