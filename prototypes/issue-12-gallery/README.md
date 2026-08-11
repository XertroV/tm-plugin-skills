# Issue 12 visual-gallery assembly proof

> **THROWAWAY PROTOTYPE — not a production skill or stable recipe library.**

This prototype answers whether one canonical recipe source can assemble a standalone Openplanet gallery without a hand-copied second implementation. All AngelScript examples remain `candidate-static-only` until the generated plugin is loaded and visually exercised in Trackmania/Openplanet. A successful local command is **not** live validation.

## One command

```bash
./prototypes/issue-12-gallery/prototype.py
```

The command validates `recipe.schema.json` and `manifest.json`, rebuilds `generated/SkillpackDemoLib/` plus dependent `generated/VisualRecipeGallery/` from canonical `recipes/*.as`, rejects drift/stale files/forbidden inputs, runs structural contracts, and runs `openplanet-lsp check` for both plugins when available. It exits non-zero on any failure.

## Ownership decision proved

- `recipes/*.as` is the only handwritten implementation of a recipe.
- A neighboring `Feature_Test.as` is the canonical companion for Openplanet `[Test]` functions and is assembled beside `Feature.as`.
- `docs/testing-openplanet-plugins.md` defines the companion signature, safe test seams, Developer-menu workflow, and live evidence gate.
- `SkillpackDemoLib` owns reusable dev-only helpers. It exposes implementation files through ordinary `exports`, so Openplanet compiles those helpers into each dependent demo plugin. Use `shared_exports` only when cross-plugin shared identity/state is actually required.
- `manifest.json` is the only handwritten catalog/navigation/license record. Provenance may be recorded when known and useful but is optional.
- `generated/VisualRecipeGallery/src/recipes/*.as` is a byte-for-byte assembly output. Editing it fails drift validation and the next run overwrites it.
- `GeneratedCatalog.as` and the plugin shell are deterministic generator output.
- `screenshot-matrix.json` owns capture cases; it is validation data, not another implementation.

The generator intentionally contains no production packaging abstraction. Delete this directory after its decisions are incorporated into the eventual implementation ticket.

## Deliberate exclusions

No third-party fonts, images, audio, sprite assets, reviewer/admin pages, control bridges, policy-bypass material, or unresolved-license source is included. The examples happen to be tiny independently written API demonstrations under this repository's `CC0-1.0 OR Unlicense`. The final design permits owner-authorized Bosslike-derived snippets and newly authored snippets without a listed external source; provenance must never be fabricated, and asset/font restrictions remain separate.

## Live-test boundary

`prototype.py` proves assembly, schema, provenance fields, state-model reachability, stack instrumentation, screenshot-matrix coverage, and static diagnostics. It cannot prove rendering, visual quality, actual stack cleanup in Openplanet, or behavior across themes/scales/game states. Those are mandatory `live-pending` gates in `VALIDATION-CONTRACT.md`; recipes must not be promoted to stable before those gates pass.

The implementation workflow is incremental and live: each new snippet is assembled into an appropriate temp/demo plugin, reviewed for best practices, loaded, compile-verified, behavior-smoked, and left available for Max to inspect before more recipes build on it. Multiple demo plugins are allowed when isolation is useful. They share the dedicated **`Skillpack Demos`** category rather than mixing into ordinary Developer plugins.

Reusable remote-control infrastructure belongs in `SkillpackDemoLib`: a bounded localhost JSON router plus registries for controllable components. A UI/NVG component may register stable actions such as click, hover, or a named mouse-button interaction. Actions default to `force=false`: if the component was not drawn/visible in the current render epoch, the callback does nothing and returns a concise structured error explaining that it was not visible and that the caller may retry after opening it or explicitly use `force=true`. Forced invocation calls the registered semantic callback; it must not pretend that a physical hover/click occurred. Every failure response includes a short cause and short next step or documentation pointer.

The component registry uses an explicit per-frame lifecycle: the host calls `BeginRenderEpoch()` before drawing; each component calls `MarkDrawn(id)` only after it actually submits its UI/NVG hit target; and control requests compare the component's last-drawn epoch with the current completed epoch. Merely setting an `IsVisible` property is insufficient evidence that a control was drawn. Registration IDs must be stable and unique, callbacks are removed on plugin teardown/reload, and remote hover is modeled as requested semantic state with a bounded lifetime rather than a claim that the physical mouse moved.

ImGui identity is mandatory for interactive controls. Buttons, selectables, collapsibles, inputs, sliders, tabs, trees, popups, and windows receive stable IDs even when their visible labels look unique. Prefer `label###stable-id` when the visible label may change but identity must not; use `##suffix` only when the visible portion itself is part of the intended identity. For loops and reusable helpers, scope with balanced `UI::PushID(...)`/`UI::PopID()` or generate IDs from stable keys, numeric indices, and explicit combinations. Random IDs are acceptable only when created once and retained for the component lifetime—never regenerate them each frame. A common `InteractiveComponentBase` should own ID composition, render-epoch marking, and remote registration for both UI and NVG controls.

Guard against duplicate rendering too: Openplanet provides distinct `Render()` and `RenderInterface()` callbacks, and some plugin structures accidentally route the same UI through both. Drawing one ImGui window ID twice can append a copy of its interior. Follow the established overlay-aware pattern: `RenderInterface()` owns the normal Openplanet-overlay path; `Render()` may draw the same window only for an intentional HUD-like “show while UI hidden” mode, and must return while `UI::IsOverlayShown()` is true. If no such mode exists, use only `RenderInterface()`. IDs prevent widget/window collisions, but they do not make duplicate rendering correct.
