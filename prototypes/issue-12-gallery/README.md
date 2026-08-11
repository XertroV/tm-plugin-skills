# Issue 12 visual-gallery assembly proof

> **THROWAWAY PROTOTYPE — not a production skill or stable recipe library.**

This prototype answers whether one canonical recipe source can assemble a standalone Openplanet gallery without a hand-copied second implementation. All AngelScript examples remain `candidate-static-only` until the generated plugin is loaded and visually exercised in Trackmania/Openplanet. A successful local command is **not** live validation.

## One command

```bash
./prototypes/issue-12-gallery/prototype.py
```

The command validates `recipe.schema.json` and `manifest.json`, rebuilds `generated/VisualRecipeGallery/` from canonical `recipes/*.as`, rejects drift/stale files/forbidden inputs, runs structural contracts, and runs `openplanet-lsp check` when available. It exits non-zero on any failure.

## Ownership decision proved

- `recipes/*.as` is the only handwritten implementation of a recipe.
- `manifest.json` is the only handwritten catalog/navigation/license record. Provenance may be recorded when known and useful but is optional.
- `generated/VisualRecipeGallery/src/recipes/*.as` is a byte-for-byte assembly output. Editing it fails drift validation and the next run overwrites it.
- `GeneratedCatalog.as` and the plugin shell are deterministic generator output.
- `screenshot-matrix.json` owns capture cases; it is validation data, not another implementation.

The generator intentionally contains no production packaging abstraction. Delete this directory after its decisions are incorporated into the eventual implementation ticket.

## Deliberate exclusions

No third-party fonts, images, audio, sprite assets, reviewer/admin pages, control bridges, policy-bypass material, or unresolved-license source is included. The examples happen to be tiny independently written API demonstrations under this repository's `CC0-1.0 OR Unlicense`. The final design permits owner-authorized Bosslike-derived snippets and newly authored snippets without a listed external source; provenance must never be fabricated, and asset/font restrictions remain separate.

## Live-test boundary

`prototype.py` proves assembly, schema, provenance fields, state-model reachability, stack instrumentation, screenshot-matrix coverage, and static diagnostics. It cannot prove rendering, visual quality, actual stack cleanup in Openplanet, or behavior across themes/scales/game states. Those are mandatory `live-pending` gates in `VALIDATION-CONTRACT.md`; recipes must not be promoted to stable before those gates pass.
