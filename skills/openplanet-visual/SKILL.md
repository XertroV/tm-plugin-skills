---
name: openplanet-visual
description: Use when designing, changing, or validating visible Openplanet ImGui, NVG, overlay, animation, or custom-composition UI.
license: CC0-1.0 OR Unlicense
compatibility: Requires Openplanet plugin source. Live Openplanet and fresh screenshot access are required for visual-completion claims; openplanet-lsp and control tooling improve evidence.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet visual

## Purpose

Create theme-respecting Openplanet UI and overlays with deterministic, inspectable evidence. Choose the shallowest visual depth that satisfies the product goal. Finish through live lifecycle proof and fresh screenshot critique, never source inspection alone.

## Choose one depth

1. **Theme-preserving ImGui (default).** Use stock `UI::*` widgets and active theme metrics/colors. Build hierarchy with layout, built-in fonts, tabs, tables, and clipping. Do not install a broad fixed palette. Use semantic color sparingly; derive translucency from `UI::GetStyleColor(...)` when practical.
2. **NVG.** Choose explicitly for HUD, canvas, or world-space drawing. Use only license-cleared/new recipes. Restore scissor, transform, alpha, and other global drawing state on every path.
3. **Advanced custom composition.** Choose explicitly for requested brand/cinematic work: custom ImGui style, draw lists, gradients, sprites, shapes, or animation. Isolate style/clip state and prove balanced cleanup. Do not leak this depth into default UI.

See [design and ownership](references/design-and-ownership.md).
Before mixing fixed dimensions, measured UI geometry, screen pixels, draw
lists, NanoVG, Manialink, mouse input, or projected world positions, load
[UI scaling and coordinate spaces](references/ui-scaling-and-coordinate-spaces.md).

## Workflow

1. **Pin intent and evidence scope.** Record plugin/game/Openplanet scope, requested depth, theme, viewport, UI scale, overlay/game state, expected pixels, and available capture/lifecycle tools. If screenshot access is absent, visual completion is blocked.
2. **Map ownership before drawing.** Give each surface one authoritative owner. `RenderInterface()` owns normal overlay-visible ImGui. Add a `Render()` fallback only for an intentional show-while-overlay-hidden mode, and return there while `UI::IsOverlayShown()` is true. Test both states. Never submit one window ID twice in a frame.
3. **Assign stable identity.** Give every window and interactive item an explicit stable ID. Prefer `label###persistent-key` when visible text changes. Scope repeated controls with balanced IDs. Derive identity from persistent domain keys/indices or retain one random value for the instance lifetime—never regenerate it per frame.
4. **Contain actions.** Render callbacks draw and make cheap local, nonthrowing changes only. Snapshot click-time values into typed state; launch yielding, throwing, I/O, network, dynamic-callback, or game-mutating work through a real `startnew(...)` boundary. Define busy/cancel/generation state, revalidate after yields, catch/report failures, and clean up. A `CoroutineFunc` invoked inline is not containment.
5. **Choose the evidence surface.** For this skillpack or reusable recipe work, add
   every visual example—stable, candidate, helper, prototype, and interactive
   component—to the one reachable `Skillpack Demos` gallery; do not create a
   competing gallery window. For ordinary product UI, use a project-local
   reachable demo/test state inside that plugin instead of importing this
   repository's gallery infrastructure. Reject duplicate installed `info.toml`
   owners of whichever evidence surface is used. Temporary fault fixtures stay
   separate and are removed after evidence capture.
   Every demo/test plugin main window is independently toggleable from a checked
   item under a `Skillpack Demos` submenu in Openplanet's Plugins menu. The menu
   item and window close button share one persistent visibility boolean.
   Lead with the most interesting, reusable demos people will want to adopt.
   Keep foundational or diagnostic examples available under a clearly secondary
   `Boring` tab rather than placing them front and center.
6. **Make reusable galleries deterministic.** For gallery/recipe work, keep
   handwritten recipe code canonical in one place. Put stable ID, title, depth,
   source, maturity, license, optional truthful provenance, expected result,
   deterministic capture frames, and instrumentation in one schema-validated
   manifest. Generate navigation and exact recipe copies; reject stale output and
   byte drift; assemble twice and compare tree digests. For ordinary product UI,
   record deterministic states and captures using the project's own harness.
7. **Add adjacent evidence.** Each testable `Feature.as` gets a neighboring `Feature_Test.as` with `[Test] void Name(Tests::Context@ ctx)` over a pure seam. Keep every example reachable and self-explanatory in pixels: show simulated state, branch/owner decision, expected invariant, and PASS/FAIL. Instrument style/clip/scissor/resource/animation depths where applicable.
8. **Validate exact staged bytes.** Run repository/schema/determinism checks and `openplanet-lsp`; preserve all diagnostics. Then load the same bytes in Openplanet. Static success leaves the recipe a candidate.
9. **Prove lifecycle.** Preserve a post-action `Loaded plugin '<id>'` line for the exact staged plugin, no later attributable compile error before intentional unload, and behavior-specific interaction. Account for dependency reload order and stale duplicate installations.
10. **Capture and critique.** Select the manifest case exactly; capture a fresh PNG after reload; record its modification time and declared state. Describe what is visible, compare it with `expected`, and inspect zero depth counters after drawing and after switching away/back. For default UI, include a representative second/light/high-contrast theme; for NVG, varied scene backgrounds; for advanced work, deterministic motion frames and style isolation. State critique before the next focused change and repeat until it passes.
11. **Report proportionally.** Use Static, Compiled, Exercised, Observed, and Adversarial labels. Missing runtime or screenshot tooling lowers the claim; it never becomes a pass. Include exact version/bytes, logs, captures, state matrix, gaps, and next probe.

Load [manifest and capture contract](references/manifest-and-capture.md) while building or reviewing the gallery.

The bundled gallery currently reports `candidate-static-only` after a fresh
generator/LSP run. Do not call any recipe stable or working until its current
live load, behavior, screenshot, theme, and action evidence closes.

## Provenance truth

Never fabricate provenance. Newly authored and owner-authorized Bosslike-derived snippets may omit an external source. Copied/adapted public code retains source repository/path and a compatible license. Audit fonts, images, audio, sprites, and other assets separately from code permission. Do not copy unresolved-license `tm-agent` code; its screenshot-loop procedure may be independently restated, while its fixed brand palette belongs only to the opt-in advanced depth.

## Completion gate

Visual work is complete only when the exact staged bytes have static diagnostics, fresh successful Openplanet load evidence, behavior smoke, fresh declared-state screenshots, observed critique, and applicable cleanup/ownership checks. Otherwise say precisely **candidate/static**, **compiled**, or **blocked**—not “done.”
