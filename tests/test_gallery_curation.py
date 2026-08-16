#!/usr/bin/env python3
"""Curation contract for the adopter-facing visual gallery."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from jsonschema import Draft202012Validator


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
        self.assertGreaterEqual(len(featured), 12)
        self.assertEqual(len(featured), len({recipe["id"] for recipe in featured}))
        for recipe in featured:
            with self.subTest(recipe=recipe["id"]):
                self.assertIn("showcase-composition", recipe["state_contract"]["instrumentation"])
                self.assertEqual([0, 30, 60, 90, 120], recipe["state_contract"]["capture_frames"])
                self.assertTrue((GALLERY / recipe["source"]).is_file())
                source = GALLERY / recipe["source"]
                self.assertTrue(source.with_name(source.stem + "_Test.as").is_file())

    def test_every_featured_recipe_has_durable_visual_review_evidence(self) -> None:
        schema = json.loads(
            (GALLERY / "visual-review-receipts.schema.json").read_text(encoding="utf-8")
        )
        reviews = json.loads(
            (GALLERY / "visual-review-receipts.json").read_text(encoding="utf-8")
        )
        Draft202012Validator(schema).validate(reviews)
        by_recipe = {receipt["recipe"]: receipt for receipt in reviews["receipts"]}
        featured = [recipe for recipe in self.manifest["recipes"] if recipe["curation"] == "featured"]
        self.assertEqual({recipe["id"] for recipe in featured}, set(by_recipe))
        for recipe in featured:
            with self.subTest(recipe=recipe["id"]):
                receipt = by_recipe[recipe["id"]]
                self.assertGreaterEqual(len(receipt["convergence_passes"]), 1)
                self.assertGreaterEqual(len(receipt["post_completion_passes"]), 3)
                for review_pass in receipt["convergence_passes"] + receipt["post_completion_passes"]:
                    self.assertEqual("pass", review_pass["parent_vision"])
                    self.assertEqual("pass", review_pass["source_geometry"])
                    self.assertTrue(review_pass["commit"])
                    self.assertEqual(
                        recipe["state_contract"]["capture_frames"],
                        review_pass["frames"],
                    )
                    self.assertEqual(
                        len(review_pass["frames"]), len(review_pass["screenshots"])
                    )
                    for screenshot in review_pass["screenshots"]:
                        self.assertTrue((GALLERY / screenshot).is_file(), screenshot)

    def test_tm_agent_inspired_showcases_are_independent_reimplementations(self) -> None:
        for recipe_id in ("spectral-relay-typography",):
            recipe = self.by_id[recipe_id]
            provenance = recipe["provenance"]
            self.assertEqual("independent-reimplementation", provenance["kind"])
            self.assertIn("no source, palette, or assets copied", provenance["note"])

    def test_split_monument_is_an_editorial_featured_composition(self) -> None:
        recipe = self.by_id["split-monument"]
        self.assertEqual("featured", recipe["curation"])
        self.assertEqual([0, 30, 60, 90, 120], recipe["state_contract"]["capture_frames"])
        self.assertIn("showcase-composition", recipe["state_contract"]["instrumentation"])
        source = (GALLERY / recipe["source"]).read_text(encoding="utf-8")
        for signature in (
            "HighlightSector",
            "SectorDelta",
            "NEW BEST",
            "SECTOR I",
            "SECTOR II",
            "SECTOR III",
        ):
            self.assertIn(signature, source)

    def test_apex_envelope_is_a_calibrated_featured_instrument(self) -> None:
        recipe = self.by_id["apex-envelope"]
        self.assertEqual("featured", recipe["curation"])
        self.assertEqual([0, 30, 60, 90, 120], recipe["state_contract"]["capture_frames"])
        source = (GALLERY / recipe["source"]).read_text(encoding="utf-8")
        for signature in ("MarkerPosition", "SafeHalfWidth", "MARGIN", "OVERSLIP"):
            self.assertIn(signature, source)
        self.assertIn("Math::Max(430.0f, available.x - 16.0f)", source)
        test_path = GALLERY / recipe["source"]
        test_source = test_path.with_name(test_path.stem + "_Test.as").read_text(
            encoding="utf-8"
        )
        self.assertIn("Margin(0), RecipeApexEnvelope::Margin(120)", test_source)
        self.assertIn("IsOverslip(0) == RecipeApexEnvelope::IsOverslip(120)", test_source)

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
