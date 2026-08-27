#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
P14 = ROOT / "assets" / "weapons" / "p14"
FILES = [
    "p14_idle.png",
    "p14_fire_1.png", "p14_fire_2.png", "p14_fire_3.png", "p14_fire_4.png",
    "p14_reload_1.png", "p14_reload_2.png", "p14_reload_3.png", "p14_reload_4.png",
    "p14_zoom.png",
    "p14_aim_fire_1.png", "p14_aim_fire_2.png", "p14_aim_fire_3.png", "p14_aim_fire_4.png",
    "p14_side.png",
]


def paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else b if pb <= pc else c


def decode_rgba(path: Path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", f"not PNG: {path.name}"
    pos = 8
    idat = bytearray()
    width = height = bit_depth = color_type = None
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos+4])[0]
        kind = data[pos+4:pos+8]
        payload = data[pos+8:pos+8+length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type, comp, filt, interlace = struct.unpack(">IIBBBBB", payload)
            assert bit_depth == 8, f"{path.name}: bit depth {bit_depth}"
            assert interlace == 0, f"{path.name}: interlaced"
            assert color_type in (4, 6), f"{path.name}: no alpha color type={color_type}"
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            break
    channels = 4 if color_type == 6 else 2
    raw = zlib.decompress(bytes(idat))
    stride = width * channels
    rows = []
    prev = bytearray(stride)
    offset = 0
    for _y in range(height):
        f = raw[offset]
        src = raw[offset+1:offset+1+stride]
        offset += 1 + stride
        out = bytearray(stride)
        for i, x in enumerate(src):
            left = out[i-channels] if i >= channels else 0
            up = prev[i]
            ul = prev[i-channels] if i >= channels else 0
            if f == 0:
                val = x
            elif f == 1:
                val = (x + left) & 255
            elif f == 2:
                val = (x + up) & 255
            elif f == 3:
                val = (x + ((left + up) >> 1)) & 255
            elif f == 4:
                val = (x + paeth(left, up, ul)) & 255
            else:
                raise AssertionError(f"{path.name}: bad filter {f}")
            out[i] = val
        rows.append(out)
        prev = out
    return width, height, color_type, rows


def stats(path: Path):
    w, h, ct, rows = decode_rgba(path)
    channels = 4 if ct == 6 else 2
    alpha_i = 3 if ct == 6 else 1
    xs = []
    ys = []
    semi = 0
    opaque = 0
    alpha_sum = 0
    weighted_x = 0
    weighted_y = 0
    for y, row in enumerate(rows):
        for x in range(w):
            a = row[x * channels + alpha_i]
            if a:
                xs.append(x); ys.append(y)
                alpha_sum += a
                weighted_x += x * a
                weighted_y += y * a
                if a == 255:
                    opaque += 1
                else:
                    semi += 1
    assert xs, f"{path.name}: empty alpha"
    bbox = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
    cx = weighted_x / alpha_sum
    cy = weighted_y / alpha_sum
    return {
        "w": w, "h": h, "ct": ct, "bbox": bbox,
        "bw": bbox[2]-bbox[0], "bh": bbox[3]-bbox[1],
        "cx": cx, "cy": cy,
        "opaque": opaque, "semi": semi,
        "coverage": (opaque + semi) / (w*h),
    }


def print_series(label: str, names: list[str], all_stats: dict[str, dict]):
    print(f"SERIES {label}")
    prev = None
    for name in names:
        s = all_stats[name]
        jump = ""
        if prev is not None:
            jump = f" dC=({s['cx']-prev['cx']:+.1f},{s['cy']-prev['cy']:+.1f}) dBBox=({s['bbox'][0]-prev['bbox'][0]:+d},{s['bbox'][1]-prev['bbox'][1]:+d},{s['bbox'][2]-prev['bbox'][2]:+d},{s['bbox'][3]-prev['bbox'][3]:+d})"
        print(f"  {name:20s} center=({s['cx']:.1f},{s['cy']:.1f}) bbox={s['bbox']} size={s['bw']}x{s['bh']} cov={s['coverage']:.3f}{jump}")
        prev = s


def main() -> int:
    all_stats = {}
    errors = []
    for name in FILES:
        path = P14 / name
        if not path.exists():
            errors.append(f"missing {name}")
            continue
        try:
            s = stats(path)
        except Exception as exc:
            errors.append(f"{name}: {exc}")
            continue
        all_stats[name] = s
        print(f"FILE {name} {s['w']}x{s['h']} alpha_type={s['ct']} bbox={s['bbox']} center=({s['cx']:.1f},{s['cy']:.1f}) semi={s['semi']} coverage={s['coverage']:.3f}")
        if name != "p14_side.png" and (s['w'], s['h']) != (1536, 1024):
            errors.append(f"{name}: expected 1536x1024, got {s['w']}x{s['h']}")
        if s['coverage'] > 0.80:
            errors.append(f"{name}: alpha coverage suspiciously high ({s['coverage']:.3f}); background may not be transparent")
    for label, names in [
        ("fire", [f"p14_fire_{i}.png" for i in range(1,5)]),
        ("reload", [f"p14_reload_{i}.png" for i in range(1,5)]),
        ("aim_fire", [f"p14_aim_fire_{i}.png" for i in range(1,5)]),
    ]:
        if all(n in all_stats for n in names):
            print_series(label, names, all_stats)
            for a, b in zip(names, names[1:]):
                sa, sb = all_stats[a], all_stats[b]
                if abs(sb['cx']-sa['cx']) > 180 or abs(sb['cy']-sa['cy']) > 180:
                    errors.append(f"{label}: abrupt alpha-center jump {a}->{b}: ({sb['cx']-sa['cx']:.1f},{sb['cy']-sa['cy']:.1f})")
    print(f"P14 VISUAL PROBE: {len(errors)} error(s)")
    for e in errors:
        print("ERROR:", e)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
