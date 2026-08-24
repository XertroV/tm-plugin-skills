#!/usr/bin/env python3
"""Bounded, low-impact re-capture of gallery evidence passes.

Constraints (user-directed):
- The gallery window stays pinned at (40, 60) the whole time. Never moved.
- No focus stealing: TM is raised once via a temporary keep-above hint.
- One screenshot at a time, hard budget, at most one retry per frame.
- Passes that cannot be captured clean are reported and skipped, not ground.

Gating: fresh captures must agree with the recipe's freshly captured post-1
reference at each frame (<=0.1% canvas pixels differ, x >= CANVAS_X excludes
the sidebar whose scrollbar position legitimately varies) and each pass must
loop-close (frame 0 vs 120, frame-counter glyphs aside). Committed evidence
cannot serve as the pixel reference: the live build's text raster differs by
a constant subpixel drift from the August captures. A static overlay covering
post-1 itself is not pixel-detectable; the downstream parent-vision montage
review is the arbiter for that.
"""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import time
from pathlib import Path

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "prototypes" / "issue-12-gallery"
EVIDENCE = GALLERY / "evidence" / "gallery-screenshots"
FRAMES = (0, 30, 60, 90, 120)
CANVAS_X = 260  # recipe canvas; x < 260 is the gallery sidebar (benign variance)
AGREEMENT_TOLERANCE_PCT = 0.1
LOOP_TOLERANCE_PCT = 1.0
PIN = (40, 60)
SHOT_BUDGET = 200  # hard cap on spectacle invocations, retries included
ONE_RETRY_PER_FRAME = True

# Per recipe: which post passes to re-capture (enough to reach >=3 clean).
TARGETS: dict[str, list[str]] = {
    "altitude-ledger": ["post-1", "post-2", "post-3"],
    "apex-envelope": ["post-1", "post-2"],
    "chicane-typesetter": ["post-2", "post-3"],
    "ghost-delta-cartogram": ["post-1", "post-2", "post-3"],
    "kinetic-spectrum-reactor": ["post-1", "post-2"],
    "midnight-switchyard": ["post-1", "post-2"],
    "slipstream-loom": ["post-1", "post-2", "post-3"],
    "spectral-relay-typography": ["post-1", "post-2"],
    "strategy-switchboard": ["post-1", "post-2"],
    "trajectory-orrery": ["post-1", "post-2", "post-3"],
    "weatherline-observatory": ["post-2"],
}


def load_capture_module():
    spec = importlib.util.spec_from_file_location(
        "capture_gallery_evidence", ROOT / "scripts" / "capture-gallery-evidence.py"
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def canvas_pct(a: Path, b: Path) -> float:
    image_a = Image.open(a).convert("RGB")
    image_b = Image.open(b).convert("RGB")
    if image_a.size != image_b.size:
        return 100.0
    w, h = image_a.size
    diff = ImageChops.difference(image_a, image_b)
    mask = diff.convert("L").point(lambda v: 255 if v > 48 else 0)
    cropped = mask.crop((CANVAS_X, 0, w, h))
    return 100.0 * cropped.histogram()[255] / (cropped.size[0] * cropped.size[1])


class Budget(Exception):
    pass


class CaptureSession:
    def __init__(self, cge) -> None:
        self.cge = cge
        self.rig = cge.Rig()
        self.shots = 0

    def close(self) -> None:
        self.rig.close()

    def shot(self, dest: Path, recipe: str, frame: int) -> bool:
        """One screenshot at the fixed pin. False if polluted or errored."""
        if self.shots >= SHOT_BUDGET:
            raise Budget()
        self.shots += 1
        try:
            self.cge.call("VisualRecipeGallery.PinWindow", {"x": PIN[0], "y": PIN[1]})
            state = self.cge._set_frame(recipe, frame)
            time.sleep(0.2)
            wx, wy = (int(v) for v in state["windowPos"].split(","))
            ww, wh = (int(v) for v in state["windowSize"].split(","))
            self.rig.capture(wx, wy, ww, wh, dest)
            return True
        except Exception as exc:  # noqa: BLE001
            print(f"      capture error: {type(exc).__name__}: {exc}", flush=True)
            return False

    def capture_pass(self, recipe: str, pass_name: str, reference: Path | None) -> bool:
        """Capture 5 frames into the evidence dir; gate on reference + loop."""
        dest_dir = EVIDENCE / recipe / pass_name
        dest_dir.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            staged: list[Path] = []
            for frame in FRAMES:
                shot = tmp / f"frame-{frame:03d}.png"
                attempts = 2 if ONE_RETRY_PER_FRAME else 1
                for attempt in range(attempts):
                    if not self.shot(shot, recipe, frame):
                        continue
                    if reference is not None:
                        pct = canvas_pct(
                            reference / f"frame-{frame:03d}.png", shot
                        )
                        if pct > AGREEMENT_TOLERANCE_PCT:
                            print(
                                f"    frame {frame}: {pct:.2f}% vs reference"
                                f" (attempt {attempt + 1})",
                                flush=True,
                            )
                            continue
                    break
                else:
                    print(f"  {recipe}/{pass_name}: frame {frame} failed; skip pass", flush=True)
                    return False
                staged.append(shot)
            loop = canvas_pct(staged[0], staged[-1])
            if loop > LOOP_TOLERANCE_PCT:
                print(f"  {recipe}/{pass_name}: loop {loop:.2f}%; skip pass", flush=True)
                return False
            for frame, shot in zip(FRAMES, staged):
                target = dest_dir / f"frame-{frame:03d}.png"
                shot_bytes = shot.read_bytes()
                target.write_bytes(shot_bytes)  # copy: staging tmpfs is cross-device
            print(f"  {recipe}/{pass_name}: captured clean (loop {loop:.2f}%)", flush=True)
            return True


def main() -> None:
    mode = sys.argv[1] if len(sys.argv) > 1 else "run"
    if mode == "list":
        for recipe, passes in TARGETS.items():
            print(f"{recipe}: {', '.join(passes)}")
        return
    cge = load_capture_module()
    session = CaptureSession(cge)
    failed: list[str] = []
    try:
        for recipe, passes in TARGETS.items():
            print(f"== {recipe} ==", flush=True)
            reference: Path | None = None
            for pass_name in passes:
                dest_dir = EVIDENCE / recipe / pass_name
                if reference is None:
                    # post-1 (or first target) is the within-session reference.
                    if not session.capture_pass(recipe, pass_name, None):
                        failed.append(f"{recipe}/{pass_name}")
                        break
                    reference = dest_dir
                else:
                    if not session.capture_pass(recipe, pass_name, reference):
                        failed.append(f"{recipe}/{pass_name}")
    except Budget:
        print("SHOT BUDGET EXHAUSTED; stopping", flush=True)
    finally:
        session.close()
    print(f"screenshots taken: {session.shots}")
    if failed:
        print("FAILED: " + ", ".join(failed))
        raise SystemExit(1)
    print("all target passes captured")


if __name__ == "__main__":
    main()
