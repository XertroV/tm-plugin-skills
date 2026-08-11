# Prototype validation contract

## Static/assembly gates (automated by `prototype.py`)

1. Manifest validates against the checked-in schema; IDs, source paths, namespaces, and output paths are unique.
2. Every recipe is explicitly `candidate-static-only`, independently authored, repository-licensed, and has expected output plus capture states.
3. Generated recipe bytes and SHA-256 values equal canonical recipe bytes; generated files are exactly the expected set.
4. Generated catalog order equals manifest order and navigation can reach every recipe.
5. Every declared recipe capture frame has a screenshot case; matrix values belong to declared axes.
6. Default-tier recipe source has no style/color push; each instrumented stack operation has a balanced decrement in canonical source.
7. No binary/assets/fonts, forbidden source imports, reviewer/admin artifacts, or unsafe policy/evasion content enter the prototype.
8. `openplanet-lsp check generated/VisualRecipeGallery` runs when the executable is present and must report zero diagnostics.
9. Running the command twice produces the same tree digest.

## Live gates (mandatory before any promotion; intentionally not claimed here)

For every required screenshot case:

1. Assemble, copy/open the generated folder as a standalone plugin, and load/reload it.
2. Record a fresh `Loaded plugin 'Visual Recipe Gallery PROTOTYPE'` event and verify no later compile error.
3. Select the case's recipe and exact capture frame. Set the named theme, viewport, UI scale, and game state.
4. Capture a fresh PNG and record its post-reload modification time.
5. Critique what rendered against `expected`; do not infer success from source.
6. Confirm style, clip, and scissor depth counters read zero after drawing; switch away and back to detect retained animation state.
7. For default ImGui, compare both themes and reject plugin-forced palette assumptions. For NVG, check clipping and scene legibility. For advanced examples, check clipping, deterministic motion state, and intentional style isolation.
8. Record pass/fail and evidence path. Independent critique is recommended for advanced polish, not universally required.

A static pass leaves maturity unchanged. Only a later, explicit live-validation workflow may propose `stable`; this prototype does not define that promotion mutation.
