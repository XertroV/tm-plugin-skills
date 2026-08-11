#!/usr/bin/env python3
"""Curation contract for the adopter-facing visual gallery."""

from __future__ import annotations

import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GALLERY = ROOT / "prototypes" / "issue-12-gallery"


class GalleryCurationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = json.loads((GALLERY / "manifest.json").read_text(encoding="utf-8"))
        self.by_id = {recipe["id"]: recipe for recipe in self.manifest["recipes"]}

    def test_foundational_proofs_are_boring(self) -> None:
        for recipe_id in (
            "visibility-safe-action",
            "nvg-scissor",
            "drawlist-gradient",
            "deterministic-pulse",
        ):
            self.assertEqual("boring", self.by_id[recipe_id]["curation"], recipe_id)

    def test_featured_is_a_deliberate_showcase_not_a_foundational_proof(self) -> None:
        featured = [recipe for recipe in self.manifest["recipes"] if recipe["curation"] == "featured"]
        self.assertEqual(["kinetic-spectrum-reactor"], [recipe["id"] for recipe in featured])
        recipe = featured[0]
        self.assertIn("showcase-composition", recipe["state_contract"]["instrumentation"])
        self.assertEqual([0, 30, 60, 90, 120], recipe["state_contract"]["capture_frames"])
        self.assertTrue((GALLERY / recipe["source"]).is_file())
        source = GALLERY / recipe["source"]
        self.assertTrue(source.with_name(source.stem + "_Test.as").is_file())

    def test_animations_autoplay_with_a_pause_play_control(self) -> None:
        generated_main = (
            GALLERY / "generated" / "VisualRecipeGallery" / "src" / "Main.as"
        ).read_text(encoding="utf-8")
        generated_catalog = (
            GALLERY / "generated" / "VisualRecipeGallery" / "src" / "GeneratedCatalog.as"
        ).read_text(encoding="utf-8")
        self.assertIn("bool g_animationPlaying = true;", generated_main)
        self.assertIn("AdvanceAnimationFrame(recipe);", generated_main)
        self.assertIn('g_animationPlaying ? "Pause animation" : "Play animation"', generated_main)
        self.assertIn("bool IsAnimated", generated_catalog)
        self.assertIn("true, true, \"candidate-static-only\"", generated_catalog)


if __name__ == "__main__":
    unittest.main()
