# Visual design and ownership

## Depth routing

| Signal | Depth |
| --- | --- |
| Settings, tabs, buttons, ordinary data tables | Theme-preserving ImGui |
| HUD text, markers, world/canvas labels | NVG |
| Requested brand chrome, cinematic FX, sprites, custom animation | Advanced |

Default ImGui inherits the installed Openplanet theme. Read style metrics; do not force `WindowBg`, `Text`, title, header, and button palettes. NVG/custom styling is opt-in and restores every modified stack/global state.

## Ownership and identity

- `RenderInterface()` owns normal overlay-visible windows.
- `Render()` may own the same surface only while the overlay is hidden, and only for an explicit HUD-like mode.
- Exactly one callback submits the interior per state/frame.
- Every interactive widget/window has a stable explicit ID; `###` preserves identity across changing labels.
- Detect separate installed plugins with the same display name; callback correctness cannot prevent two plugin instances.

## Callback containment

Drawing paths are deterministic, bounded, and exception-minimal. Risky semantic actions cross `startnew(...)` using typed click-time snapshots, explicit busy/cancel/generation ownership, post-yield reacquisition, and terminal cleanup. Inject a throwing action and a transition-during-yield probe; later frames must still render and stale work must abort safely.

## Evidence origins and limits

The three-depth direction is the approved skillpack design. Dips++ NVG helpers and Bosslike animation/sprite code are Unlicense evidence, but assets require separate review. The 2026-04-20 `tm-agent` screenshot loop is procedural evidence; its local source license was unresolved in issue-3 research, so do not copy it verbatim or treat its amber/slate palette as a default.
