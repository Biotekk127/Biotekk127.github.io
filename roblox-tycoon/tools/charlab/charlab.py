#!/usr/bin/env python3
"""CharLab: validate and render a Brainrot character definition outside Roblox.

    python3 tools/charlab/charlab.py src/shared/Characters/NoodleGoblin.luau --out preview.png

Runs the character file with tools/charlab/mockkit.luau (same transform/animation
semantics as src/shared/CharacterKit.luau), prints a validation report and writes a
contact sheet:
  row 1: full character - front, 3/4 front-left, right side, back, top-down
  row 2: two animation poses, a 3/4 close-up of the head area, the mini (front + 3/4)

Requires: the `luau` CLI (pass --luau or put it on PATH), numpy and pillow.
Exit code is 1 when the validator reports errors.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))

# Roblox WedgePart: full bottom face and full back face (+Z); the slope rises from the
# bottom-front edge (y=-h, z=-d) to the top-back edge (y=+h, z=+d).


# --------------------------------------------------------------------------------------
# Running the mock kit
# --------------------------------------------------------------------------------------

def run_mock(luau, character_path, mode, t):
    with open(os.path.join(HERE, "mockkit.luau"), encoding="utf-8") as f:
        kit_src = f.read()
    with open(character_path, encoding="utf-8") as f:
        char_src = f.read()
    t_literal = "nil" if t is None else repr(float(t))
    bundle = (
        "local __run = (function()\n" + kit_src + "\nend)()\n"
        "local __def = (function()\n" + char_src + "\nend)()\n"
        f'__run(__def, "{mode}", {t_literal})\n'
    )
    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as tmp:
        tmp.write(bundle)
    try:
        proc = subprocess.run([luau, tmp.name], capture_output=True, text=True, timeout=60)
    finally:
        os.unlink(tmp.name)
    out = proc.stdout.strip().splitlines()
    if proc.returncode != 0 or not out:
        return {"parts": [], "lights": [], "particles": [], "stats": {},
                "issues": [{"level": "error", "message": "Luau failed: " + (proc.stderr.strip() or "no output")}]}
    try:
        return json.loads(out[-1])
    except json.JSONDecodeError as e:
        return {"parts": [], "lights": [], "particles": [], "stats": {},
                "issues": [{"level": "error", "message": f"Bad JSON from mock ({e}); extra prints in the character file? {out[:3]}"}]}


# --------------------------------------------------------------------------------------
# Ray casting renderer (orthographic)
# --------------------------------------------------------------------------------------

def hex_rgb(h):
    try:
        return np.array([int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)], dtype=np.float64) / 255.0
    except (ValueError, TypeError, IndexError):
        return np.array([0.6, 0.6, 0.6])


def part_matrix(cf):
    pos = np.array(cf[0:3], dtype=np.float64)
    rot = np.array(cf[3:12], dtype=np.float64).reshape(3, 3)
    return pos, rot


def part_corners(part):
    pos, rot = part_matrix(part["cf"])
    s = np.array(part["size"], dtype=np.float64) / 2
    signs = np.array([[x, y, z] for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)], dtype=np.float64)
    return pos + (signs * s) @ rot.T


def convex_planes(shape, h):
    hx, hy, hz = h
    planes = [
        (np.array([1.0, 0, 0]), hx), (np.array([-1.0, 0, 0]), hx),
        (np.array([0, -1.0, 0]), hy), (np.array([0, 0, 1.0]), hz),
    ]
    if shape == "Wedge":
        n = np.array([0.0, hz, -hy])
        ln = np.linalg.norm(n)
        planes.append((n / ln, 0.0))
    else:
        planes += [(np.array([0, 1.0, 0]), hy), (np.array([0, 0, -1.0]), hz)]
    return planes


def intersect(shape, size, o, d):
    """o: (N,3) ray origins in local space, d: (3,) direction. Returns t (N,), normal (N,3)."""
    n = o.shape[0]
    inf = np.full(n, np.inf)
    h = np.array(size, dtype=np.float64) / 2
    if shape in ("Block", "Wedge"):
        tnear = np.full(n, -np.inf)
        tfar = np.full(n, np.inf)
        normal = np.zeros((n, 3))
        valid = np.ones(n, dtype=bool)
        for pn, c in convex_planes(shape, h):
            denom = pn @ d
            num = c - o @ pn
            if abs(denom) < 1e-12:
                valid &= num >= 0
                continue
            tt = num / denom
            if denom < 0:
                upd = tt > tnear
                tnear = np.where(upd, tt, tnear)
                normal[upd] = pn
            else:
                tfar = np.minimum(tfar, tt)
        hit = valid & (tnear <= tfar) & (tfar > 0) & np.isfinite(tnear)
        return np.where(hit, tnear, inf), normal
    if shape in ("Ellipsoid", "Ball"):
        r = h if shape == "Ellipsoid" else np.full(3, h.min())
        os_ = o / r
        ds = d / r
        a = ds @ ds
        b = 2 * (os_ @ ds)
        c = np.einsum("ij,ij->i", os_, os_) - 1
        disc = b * b - 4 * a * c
        hit = disc >= 0
        sq = np.sqrt(np.where(hit, disc, 0))
        t0 = (-b - sq) / (2 * a)
        p = o + np.outer(t0, d)
        normal = p / (r * r)
        normal /= np.linalg.norm(normal, axis=1, keepdims=True) + 1e-12
        return np.where(hit & (t0 > 0), t0, inf), normal
    if shape == "Cylinder":
        radius = min(h[1], h[2])
        hx = h[0]
        # slab on X
        if abs(d[0]) < 1e-12:
            tx0 = np.where(np.abs(o[:, 0]) <= hx, -np.inf, np.inf)
            tx1 = np.where(np.abs(o[:, 0]) <= hx, np.inf, -np.inf)
        else:
            ta = (-hx - o[:, 0]) / d[0]
            tb = (hx - o[:, 0]) / d[0]
            tx0, tx1 = np.minimum(ta, tb), np.maximum(ta, tb)
        a = d[1] ** 2 + d[2] ** 2
        if a < 1e-12:
            inside = o[:, 1] ** 2 + o[:, 2] ** 2 <= radius ** 2
            tc0 = np.where(inside, -np.inf, np.inf)
            tc1 = np.where(inside, np.inf, -np.inf)
        else:
            b = 2 * (o[:, 1] * d[1] + o[:, 2] * d[2])
            c = o[:, 1] ** 2 + o[:, 2] ** 2 - radius ** 2
            disc = b * b - 4 * a * c
            ok = disc >= 0
            sq = np.sqrt(np.where(ok, disc, 0))
            tc0 = np.where(ok, (-b - sq) / (2 * a), np.inf)
            tc1 = np.where(ok, (-b + sq) / (2 * a), -np.inf)
        tnear = np.maximum(tx0, tc0)
        tfar = np.minimum(tx1, tc1)
        hit = (tnear <= tfar) & (tfar > 0) & np.isfinite(tnear)
        from_cap = tx0 >= tc0
        p = o + np.outer(np.where(np.isfinite(tnear), tnear, 0), d)
        normal = np.zeros((n, 3))
        normal[:, 1] = p[:, 1]
        normal[:, 2] = p[:, 2]
        normal /= np.linalg.norm(normal, axis=1, keepdims=True) + 1e-12
        cap_n = np.zeros((n, 3))
        cap_n[:, 0] = -np.sign(d[0]) if abs(d[0]) > 1e-12 else 1
        normal = np.where(from_cap[:, None], cap_n, normal)
        return np.where(hit, tnear, inf), normal
    return inf, np.zeros((n, 3))


MATERIAL_SHADE = {
    "Neon": "emissive", "Glass": "glossy", "Metal": "metal", "Foil": "metal", "DiamondPlate": "metal",
    "Ice": "glossy", "ForceField": "emissive", "Marble": "glossy", "CorrodedMetal": "metal",
}


def render(scene, view_dir, up, width, height, bounds=None, light_dir=None):
    parts = scene["parts"]
    d = np.array(view_dir, dtype=np.float64)
    d /= np.linalg.norm(d)
    u = np.array(up, dtype=np.float64)
    r = np.cross(d, u)
    r /= np.linalg.norm(r)
    u = np.cross(r, d)

    if bounds is None:
        pts = np.vstack([part_corners(p) for p in parts]) if parts else np.zeros((1, 3))
        lo, hi = pts.min(axis=0), pts.max(axis=0)
    else:
        lo, hi = np.array(bounds[0]), np.array(bounds[1])
    corners = np.array([[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])])
    center = (lo + hi) / 2
    px = (corners - center) @ r
    py = (corners - center) @ u
    span = max((px.max() - px.min()) / width, (py.max() - py.min()) / height) * 1.12 + 1e-6
    scale = span  # studs per pixel

    xs = (np.arange(width) - width / 2 + 0.5) * scale
    ys = (height / 2 - np.arange(height) - 0.5) * scale
    gx, gy = np.meshgrid(xs, ys)
    origins = center + gx[..., None] * r + gy[..., None] * u - d * 1000.0
    origins = origins.reshape(-1, 3)

    npx = width * height
    depth = np.full(npx, np.inf)
    color = np.zeros((npx, 3))
    ident = np.full(npx, -1, dtype=np.int64)
    if light_dir is None:
        light_dir = -d * 0.6 + u * 0.7 - r * 0.4
    L = np.array(light_dir, dtype=np.float64)
    L /= np.linalg.norm(L)

    def screen_rect(part):
        c = part_corners(part)
        sx = (c - center) @ r / scale + width / 2
        sy = height / 2 - (c - center) @ u / scale
        x0, x1 = max(int(math.floor(sx.min())) - 1, 0), min(int(math.ceil(sx.max())) + 1, width)
        y0, y1 = max(int(math.floor(sy.min())) - 1, 0), min(int(math.ceil(sy.max())) + 1, height)
        return x0, x1, y0, y1

    def shade(part, normal_world, view):
        base = hex_rgb(part["color"])
        kind = MATERIAL_SHADE.get(part["material"], "matte")
        if kind == "emissive":
            return np.clip(np.tile(base, (normal_world.shape[0], 1)) * 1.15 + 0.08, 0, 1)
        lam = np.clip(normal_world @ L, 0, 1)
        col = base * (0.38 + 0.62 * lam[:, None])
        if kind in ("glossy", "metal"):
            hvec = L - view
            hvec /= np.linalg.norm(hvec)
            spec = np.clip(normal_world @ hvec, 0, 1) ** (24 if kind == "glossy" else 10)
            col = col + spec[:, None] * (0.55 if kind == "glossy" else 0.4)
        return np.clip(col, 0, 1)

    order = sorted(range(len(parts)), key=lambda i: parts[i]["transparency"] > 0.02)
    for idx in order:
        part = parts[idx]
        if part["transparency"] >= 0.97:
            continue
        x0, x1, y0, y1 = screen_rect(part)
        if x0 >= x1 or y0 >= y1:
            continue
        rows = np.arange(y0, y1)
        cols = np.arange(x0, x1)
        pix = (rows[:, None] * width + cols[None, :]).reshape(-1)
        pos, rot = part_matrix(part["cf"])
        o_local = (origins[pix] - pos) @ rot
        d_local = rot.T @ d
        t, n_local = intersect(part["shape"], part["size"], o_local, d_local)
        closer = t < depth[pix]
        if not closer.any():
            continue
        sel = pix[closer]
        n_world = n_local[closer] @ rot.T
        col = shade(part, n_world, d)
        alpha = 1 - part["transparency"]
        if alpha < 0.999:
            # blend over whatever is already behind (opaque parts were drawn first)
            color[sel] = color[sel] * (1 - alpha) + col * alpha
            behind_bg = ident[sel] < 0
            if behind_bg.any():
                color[sel[behind_bg]] = col[behind_bg] * alpha + np.array([0.93, 0.94, 0.97]) * (1 - alpha)
            depth[sel] = np.minimum(depth[sel], t[closer])
            ident[sel] = np.where(ident[sel] < 0, idx, ident[sel])
        else:
            color[sel] = col
            depth[sel] = t[closer]
            ident[sel] = idx

    img = np.zeros((height, width, 3))
    # background gradient
    grad = np.linspace(0.97, 0.86, height)[:, None, None]
    img[:] = grad * np.array([0.95, 0.96, 1.0])
    mask = (ident >= 0).reshape(height, width)
    img[mask] = color.reshape(height, width, 3)[mask]
    # outlines between different parts / background
    idg = ident.reshape(height, width)
    edge = np.zeros_like(mask)
    edge[:, 1:] |= idg[:, 1:] != idg[:, :-1]
    edge[1:, :] |= idg[1:, :] != idg[:-1, :]
    img[edge] *= 0.45
    out = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))

    draw = ImageDraw.Draw(out)

    def project(p):
        p = np.array(p, dtype=np.float64)
        return ((p - center) @ r / scale + width / 2, height / 2 - (p - center) @ u / scale)

    for light in scene.get("lights", []):
        x, y = project(light["pos"])
        c = tuple(int(v * 255) for v in hex_rgb(light["color"]))
        draw.ellipse([x - 6, y - 6, x + 6, y + 6], outline=(255, 200, 0), width=2, fill=c)
    for em in scene.get("particles", []):
        x, y = project(em["pos"])
        c = tuple(int(v * 255) for v in hex_rgb(em["color"]))
        draw.polygon([(x, y - 8), (x + 3, y - 2), (x + 8, y), (x + 3, y + 2), (x, y + 8), (x - 3, y + 2), (x - 8, y), (x - 3, y - 2)],
                     fill=c, outline=(40, 40, 40))
    return out, project


def draw_limits(img, project, full):
    """Faint lines for the allowed volume (ground y=0, top 9.5, |x|,|z| <= 3.2)."""
    draw = ImageDraw.Draw(img)
    if full:
        box = [(-3.2, 0, -3.2), (3.2, 9.5, 3.2)]
    else:
        box = [(-1.35, -1.35, -1.35), (1.35, 1.35, 1.35)]
    (x0, y0, z0), (x1, y1, z1) = box
    corners = [(x, y, z) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
    edges = [(a, b) for a in range(8) for b in range(a + 1, 8)
             if sum(1 for i in range(3) if corners[a][i] != corners[b][i]) == 1]
    for a, b in edges:
        pa, pb = project(corners[a]), project(corners[b])
        draw.line([pa, pb], fill=(120, 150, 255), width=1)


def label(img, text):
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 15)
    except OSError:
        font = ImageFont.load_default()
    draw.rectangle([0, 0, img.width, 22], fill=(30, 22, 52))
    draw.text((6, 3), text, fill=(255, 255, 255), font=font)
    return img


# --------------------------------------------------------------------------------------

VIEWS = {
    # Characters face -Z (Roblox LookVector), so the "front" camera sits at -Z looking +Z.
    "front": ((0, 0, 1), (0, 1, 0)),
    "3/4 front-left": ((0.62, -0.32, 0.72), (0, 1, 0)),
    "right side": ((-1, 0, 0), (0, 1, 0)),
    "back": ((0, 0, -1), (0, 1, 0)),
    "top-down": ((0, -1, 0.0001), (0, 0, -1)),
}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("character")
    ap.add_argument("--out", required=True, help="PNG contact sheet to write")
    ap.add_argument("--luau", default=shutil.which("luau") or "luau")
    ap.add_argument("--size", type=int, default=340, help="pixel width of each tile")
    args = ap.parse_args()

    base = run_mock(args.luau, args.character, "full", None)
    pose_a = run_mock(args.luau, args.character, "full", 0.37)
    pose_b = run_mock(args.luau, args.character, "full", 1.13)
    mini = run_mock(args.luau, args.character, "mini", None)

    issues = [("FULL", i) for i in base.get("issues", [])] + [("MINI", i) for i in mini.get("issues", [])]
    st, ms = base.get("stats", {}), mini.get("stats", {})
    print(f"Full: {st.get('parts', 0)} parts, {st.get('animated', 0)} animated, {st.get('groups', 0)} groups, "
          f"{st.get('lights', 0)} lights, {st.get('particles', 0)} particle emitters")
    if st.get("min"):
        print("  bounds min (x,y,z) = (%.2f, %.2f, %.2f)  max = (%.2f, %.2f, %.2f)" % (*st["min"], *st["max"]))
    print(f"Mini: {ms.get('parts', 0)} parts")
    if ms.get("min"):
        print("  bounds min (x,y,z) = (%.2f, %.2f, %.2f)  max = (%.2f, %.2f, %.2f)" % (*ms["min"], *ms["max"]))
    errors = 0
    for where, i in issues:
        if i["level"] == "error":
            errors += 1
        print(f"  [{i['level'].upper()}] {where}: {i['message']}")
    if not issues:
        print("  No issues.")

    w = args.size
    h = int(w * 1.3)
    tiles = []
    full_bounds = [(-3.4, -0.2, -3.4), (3.4, 9.7, 3.4)]
    if base["parts"]:
        for name, (vd, up) in VIEWS.items():
            img, proj = render(base, vd, up, w, h, bounds=full_bounds if name != "top-down" else None)
            if name in ("front", "right side", "back", "3/4 front-left"):
                draw_limits(img, proj, True)
            tiles.append(label(img, name))
        for name, scene in (("anim pose t=0.37", pose_a), ("anim pose t=1.13", pose_b)):
            img, _ = render(scene, VIEWS["3/4 front-left"][0], (0, 1, 0), w, h, bounds=full_bounds)
            tiles.append(label(img, name))
        # Close-up on the top half (usually the face)
        top_half = [(-3.3, 4.2, -3.3), (3.3, 9.6, 3.3)]
        img, _ = render(base, (0.3, -0.15, 0.94), (0, 1, 0), w, h, bounds=top_half)
        tiles.append(label(img, "close-up (upper half)"))
    if mini["parts"]:
        for name, vd in (("mini front", (0, 0, 1)), ("mini 3/4", (0.62, -0.32, 0.72))):
            img, proj = render(mini, vd, (0, 1, 0), w, h, bounds=[(-1.45, -1.45, -1.45), (1.45, 1.45, 1.45)])
            draw_limits(img, proj, False)
            tiles.append(label(img, name))

    cols = 5
    rows = max(1, math.ceil(len(tiles) / cols))
    sheet = Image.new("RGB", (cols * w, rows * h), (20, 16, 34))
    for i, tile in enumerate(tiles):
        sheet.paste(tile, ((i % cols) * w, (i // cols) * h))
    sheet.save(args.out)
    print(f"Wrote {args.out}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
