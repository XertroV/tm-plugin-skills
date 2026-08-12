#!/usr/bin/env python3
"""Contract for the standalone Openplanet scaling reference."""

from __future__ import annotations

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/openplanet-visual/SKILL.md"
REFERENCE = ROOT / "skills/openplanet-visual/references/ui-scaling-and-coordinate-spaces.md"
PROBE = ROOT / "prototypes/ui-scaling-probe/Main.as"
PROBE_INFO = ROOT / "prototypes/ui-scaling-probe/info.toml"


class VisualScalingReferenceTests(unittest.TestCase):
    def test_standalone_reference_exists_and_is_linked(self) -> None:
        self.assertTrue(REFERENCE.is_file(), "standalone UI scaling reference is missing")
        skill = SKILL.read_text(encoding="utf-8")
        self.assertIn("references/ui-scaling-and-coordinate-spaces.md", skill)

    def test_reference_distinguishes_supported_api_from_shorthand(self) -> None:
        text = REFERENCE.read_text(encoding="utf-8")
        self.assertIn("`UI::GetScale()`", text)
        self.assertIn("There is no `UI::Scale`", text)

    def test_reference_covers_every_coordinate_boundary(self) -> None:
        text = REFERENCE.read_text(encoding="utf-8")
        required = (
            "Logical Openplanet UI units",
            "Screen-space and render-pixel geometry",
            "Window-local and absolute cursor coordinates",
            "ImGui draw-list coordinates",
            "NanoVG coordinates",
            "Manialink coordinates",
            "World and viewport coordinates",
            "Convert only at boundaries",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, text)

    def test_reference_records_contracts_gotchas_and_evidence_limits(self) -> None:
        text = REFERENCE.read_text(encoding="utf-8")
        required = (
            "SetNextWindowPos",
            "SetNextWindowSize",
            "SetNextItemWidth",
            "GetContentRegionAvail",
            "GetCursorScreenPos",
            "TableSetupColumn",
            "double scaling",
            "mixed units",
            "Runtime scale refresh",
            "1.0 and 2.0",
            "Corpus-derived",
            "API-documented",
        )
        for phrase in required:
            with self.subTest(phrase=phrase):
                self.assertIn(phrase, text)

    def test_live_probe_covers_undocumented_coordinate_boundaries(self) -> None:
        self.assertTrue(PROBE.is_file())
        self.assertTrue(PROBE_INFO.is_file())
        source = PROBE.read_text(encoding="utf-8")
        info = PROBE_INFO.read_text(encoding="utf-8")
        self.assertIn('category = "Skillpack Demos"', info)
        self.assertIn('SkillpackDemoLib::RegisterMenuItem("ui-scaling-probe"', source)
        self.assertNotIn('UI::BeginMenu("Skillpack Demos', source)
        for term in (
            "UI::GetScale()",
            "UI::GetWindowPos()",
            "UI::GetWindowSize()",
            "UI::GetCursorPos()",
            "UI::GetCursorScreenPos()",
            "UI::GetContentRegionAvail()",
            "UI::GetMousePos()",
            "UI::GetFrameHeight()",
            "UI::MeasureString",
            "UI::SetNextItemWidth(100)",
            "UI::TableSetupColumn",
            "UI::GetWindowDrawList()",
            "SCALE_PROBE",
        ):
            with self.subTest(term=term):
                self.assertIn(term, source)


if __name__ == "__main__":
    unittest.main()
