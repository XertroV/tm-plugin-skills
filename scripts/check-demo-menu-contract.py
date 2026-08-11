#!/usr/bin/env python3
"""Require every Skillpack Demos main window to be toggleable from one submenu."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATEGORY = 'category = "Skillpack Demos"'
SUBMENU = 'UI::BeginMenu("Skillpack Demos")'


def fail(message: str) -> None:
    raise SystemExit(f"demo menu validation failed: {message}")


def main() -> None:
    plugin_roots = sorted(
        info.parent
        for info in ROOT.rglob("info.toml")
        if ".git" not in info.parts and CATEGORY in info.read_text(encoding="utf-8")
    )
    if not plugin_roots:
        fail("no Skillpack Demos plugins found")

    window_plugins = 0
    for plugin in plugin_roots:
        sources = sorted(plugin.rglob("*.as"))
        window_sources = []
        for source in sources:
            text = source.read_text(encoding="utf-8")
            if "UI::Begin(" in text:
                window_sources.append((source, text))
        if not window_sources:
            continue
        window_plugins += 1
        relative = plugin.relative_to(ROOT)
        for source, text in window_sources:
            owner = source.relative_to(ROOT)
            if "void RenderMenu()" not in text:
                fail(f"{owner}: window owner has no colocated RenderMenu")
            if SUBMENU not in text or "UI::EndMenu()" not in text:
                fail(f"{owner}: main window is not listed under the Skillpack Demos submenu")
            window_states = re.findall(r"UI::Begin\([^;]+,\s*([A-Za-z_]\w*)\)", text)
            if not window_states:
                fail(f"{owner}: main window has no toggleable open-state argument")
            for state in window_states:
                menu_item = rf"UI::MenuItem\([^;]+,\s*[^;]+,\s*{re.escape(state)}\)"
                if not re.search(menu_item, text):
                    fail(f"{owner}: submenu item does not share window state {state}")
                if f"{state} = !{state}" not in text:
                    fail(f"{owner}: submenu item does not toggle window state {state}")

    if window_plugins == 0:
        fail("no Skillpack Demos main windows found")
    gallery = (ROOT / "prototypes" / "issue-12-gallery" / "generated" / "VisualRecipeGallery" / "src" / "Main.as").read_text(encoding="utf-8")
    for phrase in ('UI::BeginTabItem("Featured")', 'UI::BeginTabItem("Boring")', "EnsureSelectionMatchesCuration"):
        if phrase not in gallery:
            fail(f"gallery curation contract missing {phrase}")
    manifest = json.loads((ROOT / "prototypes" / "issue-12-gallery" / "manifest.json").read_text(encoding="utf-8"))
    curations = [recipe["curation"] for recipe in manifest["recipes"]]
    if set(curations) != {"featured", "boring"}:
        fail("gallery manifest must contain both featured and boring recipes")
    initial = re.search(r"^int g_selectedRecipe = (\d+);$", gallery, re.MULTILINE)
    if initial is None or curations[int(initial.group(1))] != "featured":
        fail("gallery initial selection is not featured")
    catalog = (ROOT / "prototypes" / "issue-12-gallery" / "generated" / "VisualRecipeGallery" / "src" / "GeneratedCatalog.as").read_text(encoding="utf-8")
    generated_curations = re.findall(r"RecipeMeta\([^\n]+, (true|false), (?:true|false), \"candidate-static-only\"", catalog)
    expected_curations = ["true" if value == "featured" else "false" for value in curations]
    if generated_curations != expected_curations:
        fail("generated catalog curation does not match manifest order")
    print(f"demo menu validation passed ({window_plugins} toggleable main windows)")


if __name__ == "__main__":
    main()
