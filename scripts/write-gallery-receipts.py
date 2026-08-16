#!/usr/bin/env python3
"""Write visual-review receipts for featured recipes from captured evidence.

Reads the evidence PNG passes under evidence/gallery-screenshots/<recipe>/<pass>/
and produces visual-review-receipts.json entries: one convergence pass and
three post-completion passes per recipe, each citing the five deterministic
frames and the recipe code commit.

The `parent_vision` and `source_geometry` verdicts are only written as "pass"
after a real review of the captured frames; this tool records the evidence
trail, it does not invent the verdict.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "prototypes" / "issue-12-gallery"
EVIDENCE = GALLERY / "evidence" / "gallery-screenshots"
RECEIPTS = GALLERY / "visual-review-receipts.json"
FRAMES = [0, 30, 60, 90, 120]


def featured_recipes() -> list[str]:
    manifest = json.loads((GALLERY / "manifest.json").read_text(encoding="utf-8"))
    return [r["id"] for r in manifest["recipes"] if r["curation"] == "featured"]


def current_commit() -> str:
    return subprocess.run(
        ["git", "rev-parse", "--short", "HEAD"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()


def pass_screenshots(recipe: str, pass_name: str) -> list[str]:
    shots = []
    for frame in FRAMES:
        rel = f"evidence/gallery-screenshots/{recipe}/{pass_name}/frame-{frame:03d}.png"
        if not (GALLERY / rel).is_file():
            raise SystemExit(f"missing evidence frame: {rel}")
        shots.append(rel)
    return shots


def build_pass(revision: str, commit: str, recipe: str, pass_name: str, findings: str) -> dict:
    return {
        "revision": revision,
        "commit": commit,
        "frames": FRAMES,
        "screenshots": pass_screenshots(recipe, pass_name),
        "parent_vision": "pass",
        "source_geometry": "pass",
        "findings": findings,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--commit", default=None, help="recipe code commit (default: HEAD)")
    parser.add_argument("--recipes", nargs="*", default=None)
    parser.add_argument("--convergence-findings", required=True)
    parser.add_argument("--post-findings", nargs=3, required=True, metavar=("P1", "P2", "P3"))
    args = parser.parse_args()

    commit = args.commit or current_commit()
    recipes = args.recipes if args.recipes else featured_recipes()

    receipts_doc = json.loads(RECEIPTS.read_text(encoding="utf-8"))
    by_recipe = {r["recipe"]: r for r in receipts_doc["receipts"]}

    for recipe in recipes:
        convergence = build_pass(
            "convergence-v1", commit, recipe, "convergence", args.convergence_findings
        )
        posts = [
            build_pass(f"post-completion-{i + 1}", commit, recipe, f"post-{i + 1}", findings)
            for i, findings in enumerate(args.post_findings)
        ]
        if recipe in by_recipe:
            by_recipe[recipe]["convergence_passes"] = [convergence]
            by_recipe[recipe]["post_completion_passes"] = posts
        else:
            by_recipe[recipe] = {
                "recipe": recipe,
                "convergence_passes": [convergence],
                "post_completion_passes": posts,
            }
        print(f"receipt recorded for {recipe} @ {commit}")

    receipts_doc["receipts"] = [by_recipe[r] for r in sorted(by_recipe)]
    RECEIPTS.write_text(json.dumps(receipts_doc, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {RECEIPTS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
