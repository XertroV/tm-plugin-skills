#!/usr/bin/env python3
"""Create a truthful VisualRecipeGallery evidence record."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "prototypes" / "issue-12-gallery"
GENERATED = GALLERY / "generated"


def tree_digest(path: Path) -> str:
    digest = hashlib.sha256()
    for item in sorted(candidate for candidate in path.rglob("*") if candidate.is_file()):
        digest.update(item.relative_to(path).as_posix().encode())
        digest.update(b"\0")
        digest.update(item.read_bytes())
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--static-only", action="store_true")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not args.static_only:
        raise SystemExit("live recording requires explicit runtime inputs; use --static-only for an honest pending record")

    subprocess.run(["python", str(GALLERY / "prototype.py")], cwd=ROOT, check=True)
    matrix = json.loads((GALLERY / "screenshot-matrix.json").read_text(encoding="utf-8"))
    commit = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, check=True, text=True, capture_output=True
    ).stdout.strip()
    cases = [
        {
            "id": case["id"],
            "recipe": case["recipe"],
            "frame": case["frame"],
            "status": "pending",
            "capture": None,
            "critique": None,
        }
        for case in matrix["required_cases"]
    ]
    record = {
        "schema_version": 1,
        "component": "VisualRecipeGallery",
        "commit": commit,
        "source_tree_sha256": tree_digest(GENERATED),
        "evidence_level": "candidate-static-only",
        "static": {"schema": True, "deterministic_generation": True, "lsp": True},
        "live": {
            "status": "pending",
            "runtime_load": False,
            "native_tests": False,
            "screenshots": False,
            "visual_critique": False,
            "openplanet_version": None,
            "game_version": None,
            "log_reference": None,
        },
        "cases": cases,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(f"wrote static-only evidence record: {args.output}")


if __name__ == "__main__":
    main()
