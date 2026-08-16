#!/usr/bin/env python3
"""Capture deterministic gallery evidence PNGs via the live tm-control-mcp bridge.

Drives the installed VisualRecipeGallery plugin through its capture tool pack
(SelectRecipe / SetFrame / SetWindowOpen), screenshots the Trackmania monitor
with KDE spectacle, and crops the gallery window into tightly-cropped,
checked-in evidence frames under evidence/gallery-screenshots/<recipe>/<pass>/.

This is a live tool: it requires Trackmania + Openplanet + tm-control-mcp +
the VisualRecipeGallery plugin running on the local machine, and KDE's
`spectacle` for screen capture. It is intentionally not part of static CI.

Usage:
    python scripts/capture-gallery-evidence.py --pass-name convergence
    python scripts/capture-gallery-evidence.py --pass-name post-1 --recipes split-monument apex-envelope
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "prototypes" / "issue-12-gallery"
EVIDENCE = GALLERY / "evidence" / "gallery-screenshots"
CALL = [
    sys.executable,
    str(Path.home() / "src" / "openplanet" / "my-plugins" / "tm-control-mcp" / "tools" / "call.py"),
]
FRAMES = (0, 30, 60, 90, 120)

# Trackmania runs windowed on the DP-3 monitor (spectacle -m 1) at desktop
# (2564,1470); the gallery window sits at a capture-bridge-reported screen-local
# position. Monitor-local crop origin = TM offset + window pos. These constants
# describe the current capture rig; they are inputs, not contract data.
TM_MONITOR = 1
TM_LOCAL_X = 4
TM_LOCAL_Y = 30
WINDOW_W = 900
WINDOW_H = 692


def call(tool: str, payload: dict) -> dict:
    result = subprocess.run(
        CALL + [tool, json.dumps(payload)],
        text=True,
        capture_output=True,
        timeout=30,
    )
    if result.returncode != 0:
        raise SystemExit(f"bridge call failed for {tool}: {result.stderr or result.stdout}")
    data = json.loads(result.stdout)
    inner = data["data"]["result"]
    if not inner.get("success"):
        raise SystemExit(f"bridge tool {tool} failed: {inner}")
    return inner["output"]


def featured_recipes() -> list[str]:
    manifest = json.loads((GALLERY / "manifest.json").read_text(encoding="utf-8"))
    return [r["id"] for r in manifest["recipes"] if r["curation"] == "featured"]


def capture_frame(recipe: str, frame: int, pass_name: str) -> Path:
    call("VisualRecipeGallery.SelectRecipe", {"id": recipe})
    call("VisualRecipeGallery.SetFrame", {"frame": frame, "playing": False})
    call("VisualRecipeGallery.SetWindowOpen", {"open": True})
    state = call("VisualRecipeGallery.GetState", {})
    if state["recipe"] != recipe or state["captureFrame"] != frame:
        raise SystemExit(f"state mismatch for {recipe}@{frame}: {state}")
    time.sleep(0.6)  # let a few frames render at the pinned state

    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as handle:
        shot_path = Path(handle.name)
    subprocess.run(
        ["spectacle", "-b", "-n", "-m", str(TM_MONITOR), "-o", str(shot_path)],
        check=True,
        capture_output=True,
    )

    from PIL import Image

    win_x, win_y = (int(v) for v in state["windowPos"].split(","))
    local_x = TM_LOCAL_X + win_x
    local_y = TM_LOCAL_Y + win_y
    image = Image.open(shot_path)
    crop = image.crop((local_x, local_y, local_x + WINDOW_W, local_y + WINDOW_H))

    dest_dir = EVIDENCE / recipe / pass_name
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"frame-{frame:03d}.png"
    crop.save(dest)
    shot_path.unlink()
    return dest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pass-name", required=True, help="convergence, post-1, post-2, post-3, ...")
    parser.add_argument("--recipes", nargs="*", default=None, help="subset of featured recipe ids")
    args = parser.parse_args()

    recipes = args.recipes if args.recipes else featured_recipes()
    print(f"capturing pass '{args.pass_name}' for {len(recipes)} recipes x {len(FRAMES)} frames")
    for recipe in recipes:
        for frame in FRAMES:
            dest = capture_frame(recipe, frame, args.pass_name)
            print(f"  {recipe} @ {frame:3d} -> {dest.relative_to(GALLERY)}")
    print("done")


if __name__ == "__main__":
    main()
