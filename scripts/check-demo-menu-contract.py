#!/usr/bin/env python3
"""Require every Skillpack Demos main window to be toggleable from one submenu."""

from __future__ import annotations

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
        text = "\n".join(path.read_text(encoding="utf-8") for path in sources)
        if "UI::Begin(" not in text:
            continue
        window_plugins += 1
        relative = plugin.relative_to(ROOT)
        if "void RenderMenu()" not in text:
            fail(f"{relative}: main window has no RenderMenu")
        if SUBMENU not in text or "UI::EndMenu()" not in text:
            fail(f"{relative}: main window is not listed under the Skillpack Demos submenu")
        if not re.search(r"UI::MenuItem\([^;]+,\s*[^;]+,\s*[A-Za-z_]\w*\)", text):
            fail(f"{relative}: submenu item has no checked visibility state")
        if not re.search(r"UI::Begin\([^;]+,\s*[A-Za-z_]\w*\)", text):
            fail(f"{relative}: main window has no toggleable open-state argument")

    if window_plugins == 0:
        fail("no Skillpack Demos main windows found")
    gallery = (ROOT / "prototypes" / "issue-12-gallery" / "generated" / "VisualRecipeGallery" / "src" / "Main.as").read_text(encoding="utf-8")
    for phrase in ('UI::BeginTabItem("Featured")', 'UI::BeginTabItem("Boring")', "EnsureSelectionMatchesCuration"):
        if phrase not in gallery:
            fail(f"gallery curation contract missing {phrase}")
    print(f"demo menu validation passed ({window_plugins} toggleable main windows)")


if __name__ == "__main__":
    main()
