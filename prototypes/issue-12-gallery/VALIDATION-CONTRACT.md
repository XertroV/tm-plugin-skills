# Prototype validation contract

## Static/assembly gates (automated by `prototype.py`)

1. Manifest validates against the checked-in schema; IDs, source paths, namespaces, and output paths are unique.
2. Every recipe is explicitly `candidate-static-only`, has an applicable license, expected output, and capture states. Provenance is optional; if present it must be truthful. Bosslike-derived and newly authored snippets need no listed external source.
3. Generated recipe bytes and SHA-256 values equal canonical recipe bytes; generated files are exactly the expected set.
4. Generated catalog order equals manifest order and navigation can reach every recipe.
5. Every declared recipe capture frame has a screenshot case; matrix values belong to declared axes.
6. Default-tier recipe source has no style/color push; each instrumented stack operation has a balanced decrement in canonical source.
7. No binary/assets/fonts, forbidden source imports, reviewer/admin artifacts, or unsafe policy/evasion content enter the prototype.
8. `openplanet-lsp check` runs for both `generated/SkillpackDemoLib` and dependent `generated/VisualRecipeGallery` (with the generated plugin directory configured for dependency resolution) and must report zero diagnostics.
9. Running the command twice produces the same tree digest.
10. Each testable feature uses a neighboring `Feature_Test.as` with `[Test]` functions. The filename is the skillpack convention; Openplanet discovers `[Test]` metadata. Companion tests compile into the demo plugin and directly test feature behavior. Ordinary exports are compiled into dependent modules rather than the library's own module, so their focused tests live in a dependent demo companion. Every manifest recipe must have a companion test unless the manifest records a concrete, reviewed reason that it cannot be tested through the current Openplanet test API.
11. Ordinary tests do not invoke UI, draw-list, or NVG drawing APIs. They exercise extracted pure seams; live demo and screenshot gates prove actual rendering and stack restoration.
12. Every applicable rule in `docs/openplanet-gotchas.md` is represented by implementation, an automated gate, live evidence, or an explicit reviewed non-applicability record. Prose-only acknowledgement is insufficient for components that exercise the gotcha.
13. When the local Openplanet plugin directory is available, exactly one installed plugin folder may own the gallery's display name. A stale second folder fails validation instead of producing a second prototype window.
14. Every demo/test plugin main window is independently toggleable and listed
    under a `Skillpack Demos` submenu in the Plugins menu; the menu checkmark and
    window close button share one visibility state. Windowless libraries are exempt.
15. Every recipe declares `featured` or `boring`. The gallery opens on Featured,
    which contains the most interesting reusable demos. Foundational/diagnostic
    recipes remain selectable under the secondary Boring tab.
16. Scaling guidance has a dedicated DEV probe under `prototypes/ui-scaling-probe`.
    Its scale 1.0 and 2.0 captures are evidence for undocumented getter and boundary
    behavior; one scale alone must remain explicitly partial.

## Live gates (mandatory before any promotion; intentionally not claimed here)

Every snippet is introduced through a temporary/development plugin as it is written, not accumulated for one late integration pass. All visual examples must remain selectable inside the one authoritative Visual Recipe Gallery window; isolated visual fixtures may exist for fault testing but must not create a competing gallery window. Non-visual components get a `Skillpack Demos` behavior demo whenever controls, state readouts, logs, or a deterministic fault probe can communicate their contract effectively. All skillpack demo plugins use the dedicated Openplanet category **`Skillpack Demos`** so Max can find and inspect them together; do not mix them into the generic Developer category.

For every required screenshot case:

1. Assemble, copy/open the generated folder as a standalone plugin, and load/reload it.
2. Record a fresh `Loaded plugin 'Visual Recipe Gallery PROTOTYPE'` event and verify no later compile error.
3. Select the case's recipe and exact capture frame. Set the named theme, viewport, UI scale, and game state.
4. Capture a fresh PNG and record its post-reload modification time.
5. Critique what rendered against `expected`; do not infer success from source.
6. Confirm style, clip, and scissor depth counters read zero after drawing; switch away and back to detect retained animation state.
7. For default ImGui, compare both themes and reject plugin-forced palette assumptions. For NVG, check clipping and scene legibility. For advanced examples, check clipping, deterministic motion state, and intentional style isolation.
8. Record pass/fail and evidence path. Independent critique is recommended for advanced polish, not universally required.

Before adding the next recipe, the current increment must pass source review for current Openplanet/AngelScript best practices, static checks, a fresh in-game compile/load log window, and its behavior-specific smoke. Keep the demo loaded and visible when practical so Max can inspect the running code throughout development. A recipe that has only LSP/static evidence remains a candidate and cannot be described as working.

For every increment, preserve both diagnostic transcripts: `openplanet-lsp` and the fresh Openplanet build log. Compare errors and warnings, including deprecations. Same code, same reason, and ideally the same warning set is the parity target. If the game compiles but LSP reports an error, file an `openplanet-lsp` bug with the smallest known repro. If both reject it for materially different reasons, or warnings/deprecations differ, file an investigation issue with both exact transcripts and note that parity is not yet classified.

Remote-control component actions have separate gates: stable unique ID; registration/unregistration across reload; render-epoch visibility; default `force=false`; invisible/not-drawn actions make no state change; the error reports concise cause plus retry/open-or-force guidance; `force=true` invokes the semantic callback and reports that it was forced; mouse button/action names are validated; stale registrations fail safely; and UI/NVG implementations obey the same behavioral contract. Transport remains DEV-only, opt-in, loopback-bound, size/time bounded, fixed-route only, and concise on every failure.

The reference result envelope is `{v,id,ok,result}` on success and `{v,id,ok:false,error:{code,message,next}}` on failure. `message` states the immediate cause; `next` gives one concrete retry, force, or documentation action. Do not return a stack trace or unbounded payload. Required component error codes include `not_drawn`, `unknown_component`, `unknown_action`, `invalid_mouse_button`, `busy`, and `stale_registration`.

Interactive-ID gates:

- every user-interactive widget/window has an explicit stable ID;
- repeated labels in loops are scoped;
- ID helper output covers stable string keys, numeric indices, combinations, and retained random IDs;
- push/pop scopes are balanced;
- changing a visible label does not reset state when `###` identity is intended;
- no random ID changes per frame;
- for windows exposed through both callbacks, `RenderInterface()` handles the overlay-visible state;
- `Render()` returns when `UI::IsOverlayShown()` is true;
- the `Render()` fallback exists only for an explicit “show while UI hidden” mode; otherwise it is omitted; and
- tests exercise both overlay states and prove exactly one interior is submitted.

Hash assertions must be preceded by a nearby comment explaining their update policy: which source changes are expected to change the hash, when maintainers should regenerate/update it, and which unexpected changes indicate drift or breakage. Do not leave opaque golden hashes. Determinism tests should usually compare two clean builds directly; pin a literal digest only when that cross-version identity is itself the contract.

A static pass leaves maturity unchanged. Only a later, explicit live-validation workflow may propose `stable`; this prototype does not define that promotion mutation.
