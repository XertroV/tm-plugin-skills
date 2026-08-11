# Questions this prototype resolves

1. **Who owns recipe code?** Handwritten `recipes/*.as` files are canonical; the standalone plugin receives exact generated copies.
2. **How is drift prevented?** One command deletes/reassembles output, compares exact bytes and expected file set, validates generated dispatch order, then proves a second assembly has the same tree digest.
3. **What owns metadata/navigation?** One schema-validated manifest owns tier, title, entrypoint, provenance/license, maturity, expected result, capture frames, and instrumentation. Generated navigation follows manifest order and tier grouping.
4. **What is the copy mechanic?** The generated folder is a conventional monolithic `info.toml` + `src/` Openplanet plugin with no dependencies or external assets.
5. **How are screenshots deterministic?** The gallery owns an integer capture frame, exposes only manifest-declared frame buttons plus a slider, and the matrix names theme, viewport, UI scale, game state, recipe, and frame.
6. **How are leaks made observable?** Canonical examples expose style/clip/scissor depth or animation frame state; the generated gallery reports selected-recipe instrumentation after drawing. Static checks require balanced operations where declared.
7. **What does a local pass mean?** Schema/assembly/static diagnostics only. It cannot promote maturity; runtime load, behavior, fresh screenshots, alternate themes/scales/states, and observed critique remain mandatory.
8. **Which candidate content is safe here?** Only tiny independently written API examples under this repo's dual public-domain license. No `tm-agent` verbatim code, unavailable Bosslike public snippets, fonts/assets, reviewer pages, control bridges, or unsafe policy material.

## Deliberately unresolved until live testing

- Whether every AngelScript call compiles in the user's actual Openplanet build despite zero LSP diagnostics.
- Whether NVG and draw-list output matches the written expectation in menu and in-map states.
- Whether active themes and UI scales expose layout/contrast defects.
- Whether runtime counters stay balanced across recipe switches and repeated frames.
- Which candidates, if any, deserve stable production recipe status.
