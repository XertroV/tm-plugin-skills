#!/usr/bin/env python3
"""Capture deterministic gallery evidence PNGs via the live tm-control-mcp bridge.

Drives the installed VisualRecipeGallery plugin through its capture tool pack
(SelectRecipe / SetFrame / SetWindowOpen / PinWindow), screenshots the
Trackmania monitor with KDE spectacle (monitor mode — no window activation, so
the capture is independent of which app has focus), and crops the pinned
gallery window into checked-in evidence frames under
evidence/gallery-screenshots/<recipe>/<pass>/.

The gallery window is pinned to a fixed anchor and the animation is paused, so
each frame is captured with a minimal settle. The whole 5-frame recipe capture
takes ~1.5s; a full 12-recipe pass ~18s.

This is a live tool: it requires Trackmania + Openplanet + tm-control-mcp +
the VisualRecipeGallery plugin running locally, plus KDE's `spectacle`. It is
intentionally not part of static CI.

Usage:
    python scripts/capture-gallery-evidence.py --pass-name convergence
    python scripts/capture-gallery-evidence.py --pass-name post-1 --recipes split-monument apex-envelope
"""

from __future__ import annotations

import argparse
import json
import re
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

PIN_X = 40
PIN_Y = 60
WINDOW_W = 1000
WINDOW_H = 650


def call(tool: str, payload: dict) -> dict:
    result = subprocess.run(
        CALL + [tool, json.dumps(payload)],
        text=True,
        capture_output=True,
        timeout=30,
    )
    stdout = result.stdout
    if result.returncode != 0 or "Connection refused" in stdout or "Could not reach TM Control MCP" in stdout:
        _wait_for_bridge()
        result = subprocess.run(CALL + [tool, json.dumps(payload)], text=True, capture_output=True, timeout=30)
        stdout = result.stdout
        if result.returncode != 0:
            raise SystemExit(f"bridge call failed for {tool}: {result.stderr or stdout}")
    data = json.loads(stdout)
    inner = data["data"]["result"]
    if not inner.get("success"):
        if inner.get("code") == "unknown_tool":
            _reload_gallery()
            return call(tool, payload)
        raise SystemExit(f"bridge tool {tool} failed: {inner}")
    return inner["output"]


def _wait_for_bridge() -> None:
    print("  (bridge lost; waiting for tm-control-mcp + gallery)", flush=True)
    for _ in range(60):
        probe = subprocess.run(CALL + ["GetReadiness", "{}"], text=True, capture_output=True, timeout=15)
        if '"ready":true' in probe.stdout or '"ready": true' in probe.stdout:
            break
        time.sleep(2.0)
    else:
        raise SystemExit("tm-control-mcp bridge did not recover")
    _reload_gallery()


def _reload_gallery() -> None:
    subprocess.run(
        CALL + ["ControlPlugin", json.dumps({"id": "VisualRecipeGallery", "action": "load"})],
        text=True, capture_output=True, timeout=45,
    )
    time.sleep(4.0)  # fresh load resets render state; let it settle
    call("VisualRecipeGallery.PinWindow", {"x": PIN_X, "y": PIN_Y})
    print("  (gallery reloaded after dependency cascade)", flush=True)

def featured_recipes() -> list[str]:
    manifest = json.loads((GALLERY / "manifest.json").read_text(encoding="utf-8"))
    return [r["id"] for r in manifest["recipes"] if r["curation"] == "featured"]


def tm_monitor() -> tuple[int, int, int]:
    """Return (spectacle -m index, monitor origin x, monitor origin y) for TM's monitor."""
    winid = subprocess.run(
        ["xdotool", "search", "--name", "^Trackmania$"], capture_output=True, text=True, check=True
    ).stdout.split()[-1]
    geo = subprocess.run(
        ["xdotool", "getwindowgeometry", winid], capture_output=True, text=True, check=True
    ).stdout
    m = re.search(r"Position: (\d+),(\d+)", geo)
    tm_x, tm_y = int(m.group(1)), int(m.group(2))

    # Parse monitor geometries from kscreen-doctor. kscreen-doctor lists outputs
    # 1-indexed ("Output: 1 DP-3"); spectacle -m is 0-indexed in the same order.
    # Strip ANSI color codes from the output before matching.
    out = subprocess.run(["kscreen-doctor", "-o"], capture_output=True, text=True, check=True).stdout
    out = re.sub(r"\x1b\[[0-9;]*m", "", out)
    mons = []  # (x, y, w, h) per output, 0-indexed to match spectacle -m
    for gm in re.finditer(r"Geometry: (\d+),(\d+) (\d+)x(\d+)", out):
        mons.append(tuple(int(v) for v in gm.groups()))
    for idx, (mx, my, mw, mh) in enumerate(mons):
        if mx <= tm_x < mx + mw and my <= tm_y < my + mh:
            return idx, mx, my
    raise SystemExit(f"could not locate TM monitor for window at ({tm_x},{tm_y}); monitors={mons}")


class Rig:
    def __init__(self) -> None:
        self.mon_idx, self.mon_x, self.mon_y = tm_monitor()
        # TM window id + origin, refreshed once per pass.
        self.winid = subprocess.run(
            ["xdotool", "search", "--name", "^Trackmania$"], capture_output=True, text=True, check=True
        ).stdout.split()[-1]
        geo = subprocess.run(
            ["xdotool", "getwindowgeometry", self.winid], capture_output=True, text=True, check=True
        ).stdout
        m = re.search(r"Position: (\d+),(\d+)", geo)
        self.tm_x, self.tm_y = int(m.group(1)), int(m.group(2))
        # Raise TM above desktop windows WITHOUT stealing keyboard focus:
        # `xdotool windowactivate` grabs focus every frame, which disrupts
        # whatever the human is typing. A temporary _NET_WM_STATE_ABOVE via
        # wmctrl raises the window for capture purposes only; it is removed
        # again in close().
        self._set_keep_above(True)
        self._shot = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        self._shot_path = Path(self._shot.name)
        self._shot.close()

    def _wm_winid(self) -> str:
        return f"0x{int(self.winid):x}"

    def _set_keep_above(self, above: bool) -> None:
        action = "add" if above else "remove"
        subprocess.run(
            ["wmctrl", "-i", "-b", f"{action},above", self._wm_winid()],
            capture_output=True, timeout=10,
        )

    def close(self) -> None:
        self._set_keep_above(False)

    def capture(self, win_x: int, win_y: int, win_w: int, win_h: int, dest: Path) -> None:
        # TM was raised above desktop windows once at Rig init (keep-above,
        # no focus change). In-game overlays can still cover the pinned
        # gallery; the title-bar check below rejects those frames and the
        # caller recaptures.
        subprocess.run(
            ["spectacle", "-b", "-n", "-m", str(self.mon_idx), "-o", str(self._shot_path)],
            check=True, capture_output=True,
        )
        from PIL import Image
        lx = (self.tm_x - self.mon_x) + win_x
        ly = (self.tm_y - self.mon_y) + win_y
        image = Image.open(self._shot_path)
        crop = image.crop((lx, ly, lx + win_w, ly + win_h))
        crop.save(dest)
        if not _is_gallery_frame(crop):
            raise _PollutedFrame(dest)


class _PollutedFrame(Exception):
    pass


def _is_gallery_frame(crop) -> bool:
    """The gallery title bar always renders 'Visual Recipe Gallery PROTOTYPE' as
    light text on a dark bar (~12% light pixels); a foreign/black window has
    ~3%. Detect pollution so the frame can be recaptured rather than archived."""
    region = crop.convert("RGB").crop((10, 4, 320, 24))
    px = list(region.getdata())
    light = sum(1 for p in px if (p[0] + p[1] + p[2]) / 3 > 140)
    return (100 * light / len(px)) >= 6.0


def capture_recipe(recipe: str, pass_name: str, rig: Rig) -> None:
    dest_dir = EVIDENCE / recipe / pass_name
    dest_dir.mkdir(parents=True, exist_ok=True)
    _select_and_pause(recipe)
    for frame in FRAMES:
        state = _set_frame(recipe, frame)
        time.sleep(0.2)  # one or two rendered frames at the pinned state
        win_x, win_y = (int(v) for v in state["windowPos"].split(","))
        win_w, win_h = (int(v) for v in state["windowSize"].split(","))
        dest = dest_dir / f"frame-{frame:03d}.png"
        # Retry through transient capture pollution (a foreign window stacked
        # over TM) by re-raising TM and recapturing.
        for attempt in range(4):
            try:
                rig.capture(win_x, win_y, win_w, win_h, dest)
                break
            except _PollutedFrame:
                time.sleep(0.4)
        else:
            raise SystemExit(f"could not capture a clean gallery frame for {recipe}@{frame}")
        print(f"  {recipe} @ {frame:3d} -> {dest.relative_to(GALLERY)}", flush=True)


def _select_and_pause(recipe: str) -> None:
    call("VisualRecipeGallery.SelectRecipe", {"id": recipe})
    call("VisualRecipeGallery.SetWindowOpen", {"open": True})
    call("VisualRecipeGallery.PinWindow", {"x": PIN_X, "y": PIN_Y})


def _set_frame(recipe: str, frame: int) -> dict:
    """Pin a frame, tolerating one mid-pass reload by re-asserting recipe+pause."""
    for attempt in range(2):
        call("VisualRecipeGallery.SetFrame", {"frame": frame, "playing": False})
        state = call("VisualRecipeGallery.GetState", {})
        if state["recipe"] == recipe and state["captureFrame"] == frame and not state["animationPlaying"]:
            return state
        # A reload re-enabled animation and drifted the frame; re-select and retry.
        _select_and_pause(recipe)
    raise SystemExit(f"could not pin {recipe}@{frame} after reload recovery: {state}")


def _verify_loop_closure(recipes: list[str], pass_name: str) -> None:
    """Verify the drawn composition closes the 120-frame loop.

    The composition geometry at frame 120 equals frame 0 (the loop period), but
    several recipes print the absolute frame index in a header/footer counter,
    which legitimately differs ("DRAFT 000/120" vs "DRAFT 120/120"). We therefore
    compare the full window and require that any differences are confined to a
    small fraction of pixels (the frame-counter glyphs), not structural changes.
    """
    from PIL import Image, ImageChops
    failures = []
    for recipe in recipes:
        first = Image.open(EVIDENCE / recipe / pass_name / "frame-000.png").convert("RGB")
        last = Image.open(EVIDENCE / recipe / pass_name / "frame-120.png").convert("RGB")
        if first.size != last.size:
            failures.append(f"{recipe} (size {first.size} != {last.size})")
            continue
        diff = ImageChops.difference(first, last)
        if diff.getbbox() is None:
            continue  # pixel-identical
        # Count pixels that differ by more than a small threshold.
        histogram = diff.convert("L").point(lambda v: 255 if v > 48 else 0).histogram()
        changed = histogram[255]
        total = diff.size[0] * diff.size[1]
        # Frame-counter text is well under 1% of the window; anything more is a
        # structural desync (wrong recipe, focus loss, or mid-pass reload).
        if changed / total > 0.01:
            failures.append(f"{recipe} ({changed / total:.2%} pixels differ)")
    if failures:
        raise SystemExit(
            "loop closure violated for: " + ", ".join(failures)
            + " — capture desync or a mid-pass reload; rerun this pass"
        )
    print(f"loop closure verified for {len(recipes)} recipes (composition identical; frame-counter text may differ)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pass-name", required=True, help="convergence, post-1, post-2, post-3, ...")
    parser.add_argument("--recipes", nargs="*", default=None, help="subset of featured recipe ids")
    args = parser.parse_args()

    recipes = args.recipes if args.recipes else featured_recipes()
    rig = Rig()
    print(f"capturing pass '{args.pass_name}' for {len(recipes)} recipes x {len(FRAMES)} frames")
    call("VisualRecipeGallery.GetState", {})
    call("VisualRecipeGallery.PinWindow", {"x": PIN_X, "y": PIN_Y})
    time.sleep(1.0)  # settle after pin
    start = time.time()
    for recipe in recipes:
        capture_recipe(recipe, args.pass_name, rig)
    _verify_loop_closure(recipes, args.pass_name)
    print(f"done in {time.time() - start:.1f}s")


if __name__ == "__main__":
    main()
