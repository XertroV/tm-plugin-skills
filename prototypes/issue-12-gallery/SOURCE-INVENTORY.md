# Featured-gallery source inventory

This inventory ranks visual and interaction theses found in Max's local Openplanet corpus. It is research evidence, not copying permission. Every gallery recipe remains independently authored: do not copy source, constants, dimensions, palette, branding, fonts, media, recorded game/map data, or bundled assets.

License notes refer only to locally observed repository files. Assets and upstream-derived files require separate provenance checks even when repository code is permissively licensed.

## Ranking criteria

1. Still-frame impact.
2. Motion or interaction quality.
3. Reusable implementation technique.
4. Openplanet/AngelScript gallery feasibility.
5. Distinctness from Kinetic Spectrum Reactor and Spectral Relay Typography.
6. Provenance and dependency risk.

## Ranked sources

| Rank | Source | Visual thesis and reusable technique | Feasibility | Provenance / caution |
|---:|---|---|---|---|
| 1 | `tm-dips-plus-plus/src/Anims/SubtitlesAnim.as:468-604` | Cinematic lightning split: one timeline drives flash, panel displacement, polygonal masks, primary seams, and fading branches. | High; replace the logo with procedural geometry and omit audio. | Dips++ code is Unlicensed locally. Do not reuse its logo, audio, font, palette, or bolt geometry. |
| 2 | `tm-minimap/src/MiniMap.as:318-383,403-430,486-507,515-553` | Living route heatmap: bilinear splatting, persistence decay, smoothed focus/zoom transforms, checkpoint topology, and layered markers. | High with a seeded synthetic route and agents. | Local Unlicense. Do not copy map imagery, data, or palette. |
| 3 | `tm-dips-plus-plus/src/Minimap.as:29-53,67-104,154-180,187-299,319-341` | Altitude ladder: reduce a 3D race to one vertical axis, prioritize labels, interpolate positions, and distinguish live/PB/falling states. | High with deterministic synthetic climbers. | Dips++ is Unlicensed; independently redesign composition, labels, data, fonts, and colors. |
| 4 | `tm-editor-plus-plus/src/Components/Cursor/RotationGizmo.as:431-603` | Depth-aware orbital gizmo: project rings, split strokes on near/far transitions, preserve perceived size, and hit-test line segments. | Medium-high with gallery-owned projection math. | Editor++ is Unlicensed. Do not transplant mature geometry, constants, or axis treatment. |
| 5 | `tm-editor-plus-plus/src/Components/NodeGraph/Node.as:133-155,203-250,327-447` | Hybrid node workbench: custom draw-list nodes and sockets under real ImGui widgets, content-derived sizing, coordinate conversion, and typed propagation. | High with a small synthetic graph. | Editor++ is Unlicensed; independently author node shapes, routing, type language, and interaction model. |
| 6 | `tm-ghosts-plus-plus/src/Scrubber.as:251-329,369-405,423-474` | Precision replay transport: dominant timeline, adaptive controls, double-precision time, progressive disclosure, modifier-sensitive scrubbing, and context actions. | High with a deterministic simulated replay. | Ghosts++ is Unlicensed. Do not duplicate its toolbar hierarchy, icons, labels, or control dimensions. |
| 7 | `tm-cotd-hud/src/Histogram.as:28-149,153-223` | Interactive distribution skyline: normalized buckets, callback-driven semantics, full-height hover targets, selected outlines, and geometry-anchored readouts. | High with seeded distributions and built-in fonts. | Local Unlicense. Do not inherit exact colors, typography, event labels, or layout. |
| 8 | `tm-player-trails/src/Trails.as:57-138` | Perspective-sensitive trajectory ribbons: ring-buffer paths, discontinuity rejection, optional offset strands, and segmented restroking for changing width. | High after replacing world projection with deterministic 2D paths. | Local Unlicense. Independently redesign path shapes, annotations, and palette. |
| 9 | `tm-editor-trails/TrailView.as:14-240` | Synchronized spatial trail playback: projected traces, event markers, sample interpolation, current-time slice, follow mode, and timeline coupling. | Medium-high with an isometric synthetic field. | Authored by Miss; no local license found. Research-only—copy no code or presentation details. |
| 10 | `tm-dashboard/Source/Pads/Gamepad.as:3-31,129-258` | Analog cateye/control instrument: signed steering plus throttle/brake encoded as mirrored deforming geometry and clipped magnitude fills. | High with deterministic scalar channels. | Authored by Miss; local MIT license reported, but independent composition remains preferred. Do not copy the cateye silhouette or palette. |
| 11 | `tm-bosslike/src/Animations/Flames.as:1-72` | Organic Bézier contour: phase-offset control points and nonlinear lateral displacement create a coherent breathing silhouette without particles. | High and asset-free. | Bosslike is Unlicensed. Borrow only the thesis of deterministic curve deformation, not its flame silhouette or control values. |
| 12 | `tm-dips-plus-plus/src/Anims/FloorTitle.as:30-202` | Broadcast wipe: explicit stage-local timing, opposing scissored panels, measured title fitting, and a strong hold frame. | High with default fonts and a new editorial composition. | Dips++ is Unlicensed. Reuse no title, font, palette, dimensions, or keyframe constants. |
| 13 | `tm-dips-plus-plus/src/Anims/SubtitlesAnim.as:193-370` | Elastic narrative stack: measured container bounds interpolate while new lines enter, old lines recede, and a portrait satellite remains outside the text mass. | High using generated copy and procedural avatar geometry. | Dips++ is Unlicensed; do not use portrait, dialogue, voice, font, or panel styling. |
| 14 | `tm-dashboard/Source/Things/Gearbox.as:112-241` | Threshold telemetry rail: map one scalar through safe, build, and danger zones; derive continuous, dot, and segmented modes from available width. | High, but should be transformed beyond a generic progress bar. | Dashboard provenance requires care; do not copy implementation, thresholds, dimensions, or palette. |
| 15 | `tm-map-together/src/PlayerEphemUpdates.as:132-225,319-333` | Collaborative presence constellation: frame-rate-independent easing, mode-to-style mapping, anchored labels, and physical cross markers. | Medium-high with synthetic anchors and no networking. | Local Unlicense was reported; use no names, network protocol, font, label silhouette, or colors. |
| 16 | `tm-editor-plus-plus/src/Components/Tools/CoordPathDrawingTab.as:27-258` | Survey/path instrument: serializable route state, clipped point inspector, recording affordance, camera jump, projected guides, point rings, and bounds. | Medium-high as an interactive planning canvas. | Editor++ is Unlicensed. Redesign inspector, waypoints, path rendering, and copy. |
| 17 | `tm-show-editor-inputs/src/DrawKeyPresses.as:43-137` | Compact input chord visualizer: measured keycaps, stable mouse slots, active-only rows, and layout that avoids jitter. | High; add hold duration and temporal decay to reach Featured quality. | Verify local license and any Kenney/icon provenance separately; use default glyphs or procedural marks. |
| 18 | `tm-map-together/src/NvgMessages.as:16-195` | Semantic event stream: event-owned lifetime and fade, measured backing boxes, severity-specific styling, and collapsing newest-first stack. | High, but must evolve beyond ordinary toast notifications. | Confirm local repository and font licensing; independently author taxonomy, layout, and transitions. |
| 19 | `tm-bosslike/src/Game/Draw/NvgStatusBox.as` and `tm-bosslike/src/Game/Draw/MainDraw.as` | Layered status composition: reusable measured status surfaces integrated into a larger game-state presentation. | Medium; useful primarily as composition and hierarchy research. | Bosslike is Unlicensed, but bundled fonts/media and game branding are separate; copy none of them. |
| 20 | `tm-dips-plus-plus/src/Anims/PersonalBestStatusAnim.as:124-160` and `tm-bosslike/src/Game/Anim/TextAnim.as:67-75` | Measured typographic motion: deterministic per-character baseline state plus alignment/bounds discipline. | High as a clean-room typography engine. | Both repositories are locally permissive, but do not copy text, fonts, animation curves, palette, or branded presentation. |

## Deliberate exclusions

- `tm-agent/src/TextEffect.as`: too close to Spectral Relay Typography's traveling character signal.
- `tm-agent/src/BorderEffect.as`: too close to Kinetic Spectrum Reactor's animated perimeter.
- Asset-led sprite systems and `FrogDance.as`: visually dependent on bundled art rather than reusable procedural technique.
- `tm-menu-bg-scene-randomizer/src/SelectablePseudoButton.as`: file states upstream provenance and no independently verified upstream license was established; useful interaction evidence, but not a Featured thesis.

## Selected twelve-piece Featured portfolio

Existing:

1. Kinetic Spectrum Reactor — perimeter containment field and recessed core.
2. Spectral Relay Typography — counter-propagating signals through a monumental wordmark.

New independently authored recipes:

3. Split Monument — asymmetrical editorial result card.
4. Apex Envelope — calibrated steering/safety instrument.
5. Strategy Switchboard — tactile semantic decision matrix.
6. Brake-Heat Relief — tactile ring-buffer telemetry landscape.
7. Altitude Ledger — vertical spatial race summary with collision-managed labels.
8. Ghost Delta Cartogram — paired route and signed gain/loss field.
9. Midnight Switchyard — state propagation through a branching rail diagram.
10. Weatherline Observatory — procedural contour/weather field.
11. Chicane Typesetter — crisp typography physically following a racing line.
12. Slipstream Loom — layered over/under ribbon renderer.

The selected set intentionally spans light and dark compositions, static-first and animated work, data and atmosphere, horizontal and vertical layouts, typography and geometry, and direct interaction. Each must remain compelling without custom assets or fonts.
