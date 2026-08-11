# UI scaling and coordinate spaces

Use this reference whenever Openplanet UI code mixes fixed sizes, measured UI geometry, screen dimensions, draw lists, NanoVG, Manialink, mouse input, or projected world positions.

The supported API is `UI::GetScale()`. There is no `UI::Scale`; that name is only informal shorthand.

## Core rule: Convert only at boundaries

Give nontrivial values names that identify their units: `screenPx`, `uiLogical`, `cursorLocal`, `mlPos`, or `worldPos`. Keep calculations in one coordinate space, then convert once at the receiving API boundary.

For setters explicitly documented as auto-scaled, pass logical design constants
directly. If a source has independently been established as screen-space or
render-pixel geometry, divide by `UI::GetScale()` before sending it to one of those
setters. Other boundaries require API-specific evidence or a live probe.

Do not scatter `* UI::GetScale()` and `/ UI::GetScale()` through an expression. Expressions with mixed units are difficult to review and are the main source of double scaling.

## What the API explicitly guarantees

These are **API-documented** contracts in current Openplanet documentation/typed API metadata:

- `UI::GetScale()` returns the user-selected Openplanet UI scale. It is relevant when numbers represent pixels and should support high UI scales.
- `UI::SetNextWindowPos(...)` automatically scales its position.
- `UI::SetNextWindowSize(...)` automatically scales its size.
- `UI::SetNextWindowContentSize(...)` automatically scales its size.
- `UI::SetNextWindowSizeConstraints(...)` automatically scales its bounds.
- `UI::SetNextItemWidth(...)` automatically scales its width.
- `UI::GetCursorScreenPos()` returns absolute coordinates and is preferred over `UI::GetCursorPos()`.
- `UI::GetItemRect()` returns the previous control's rectangle in screen space.
- `UI::GetMousePos()` is documented as relative to the current window's top-left,
  although substantial corpus code appears to treat it as absolute. Runtime behavior
  is therefore a required probe rather than a settled recommendation.
- A `UI::GetWindowDrawList()` handle belongs to the current window and must not be retained outside it.
- `UI::TableSetupColumn(...)` documents no automatic-scaling guarantee.

Current primary API page: <https://openplanet.dev/docs/api/UI/GetScale>.

Anything below labeled **Corpus-derived** is a strong convention observed across Max's plugins, not a universal guarantee for undocumented getter units. Verify uncertain boundaries with the diagnostic probe at the end.

## Coordinate-space guide

### Logical Openplanet UI units

Automatically scaled setters consume logical UI values:

```angelscript
UI::SetNextWindowPos(100, 80);
UI::SetNextWindowSize(500, 300);
UI::SetNextItemWidth(240);
```

Pass design constants directly. Do not multiply them first.

If the source is a physical screen measurement, divide once:

```angelscript
float scale = UI::GetScale();
vec2 windowPosLogical = screenPosPx / scale;
UI::SetNextWindowPos(int(windowPosLogical.x), int(windowPosLogical.y));
```

Corpus-derived examples include `tm-match-recorder/src/MatchLogUI.as:16-19`, `tm-green-timer/src/Main.as:35-42`, `tm-dashboard/Source/SettingsWidgets.as:90,100-104`, and `tm-unintrusive-checkpoint-timer/src/CustomPos.as:37-44`.

### Screen-space and render-pixel geometry

Use `screenSpace` or `renderPx` in names unless a framebuffer/DPI probe establishes
hardware-pixel semantics. Corpus code often treats these as current screen geometry,
but current API documentation does not specify scaling units for every getter:

- `Display::GetWidth()` and `Display::GetHeight()`;
- absolute draw-list positions and rectangles;
- `UI::GetCursorScreenPos()`;
- measured window position/size and mouse geometry in code that crosses into auto-scaled setters.

Use physical values directly with physical drawing APIs. Divide only when crossing into a documented auto-scaled UI setter.

### Window-local and absolute cursor coordinates

`UI::GetCursorScreenPos()` is API-documented as absolute and preferred.
`UI::GetCursorPos()` is conventionally treated as window-local, consistently with
ImGui, but current Openplanet documentation does not spell out its origin or units.

Prefer `UI::GetCursorScreenPos()` for:

- draw-list primitives;
- absolute hit boxes;
- overlays aligned to a widget;
- geometry crossing child or window boundaries.

Do not reconstruct absolute coordinates as `UI::GetWindowPos() + UI::GetCursorPos()`: title bars, content origins, padding, scrolling, and child windows make that fragile. Do not divide a cursor value merely because it came from a cursor getter; conversion depends on the destination coordinate space.

### Content-region measurements

`UI::GetContentRegionAvail()` measures the current remaining layout region, but its
units are not documented. Corpus code contains both direct and scale-divided reuse
with item-width APIs:

```angelscript
float availablePx = UI::GetContentRegionAvail().x;
UI::SetNextItemWidth(availablePx / UI::GetScale());
```

Divided examples: `tm-ghosts-plus-plus/src/GPS_Scrubber/GpsScrubber.as:40-42`,
`tm-ghosts-plus-plus/src/Scrubber.as:291-297`, and
`tm-music-mania/src/LittleWindow.as:127-130,188-194`. Direct counterexamples include
`tm-autohide-opponents/src/Settings.as:290,306,322,338`,
`tm-better-room-manager/src/GameModeSettings.as:746`, and
`tm-freecam-show-cp/src/Main.as:78`.

Do not present either form as universally correct. Compare direct and divided reuse
at scale 1 and 2; this is a mandatory probe boundary.

### ImGui draw-list coordinates

Screen-space origins from `UI::GetItemRect()` and absolute origins from
`UI::GetCursorScreenPos()` can be passed to the current window draw list. The need
to scale design offsets, radii, thicknesses, and icon sizes is corpus-derived rather
than an explicit Openplanet contract. A cautious pattern is:

1. obtain the origin from `UI::GetCursorScreenPos()`, `UI::GetItemRect()`, or another known absolute source;
2. after proving the primitive's units, scale logical design offsets only when they should follow Openplanet UI scale;
3. add those scaled offsets to the absolute origin;
4. do not divide the final draw-list coordinates;
5. do not retain the draw-list handle after the active window ends.

Evidence: `tm-better-chat/src/AutoCompletion/Command.as:36-42`, `AutoCompletion/Emote.as:30-34`, `AutoCompletion/Mention.as:32-34`, and `UI/Tag.as:14-35`.

### Fixed table columns

`UI::TableSetupColumn(...)` has no documented auto-scale promise. Some plugins
explicitly scale fixed-width constants:

```angelscript
UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed, 100 * UI::GetScale());
```

Evidence includes `tm-simple-room-admin/src/Interface.as:501-505`,
`tm-plugin-hotkeys/src/Bind.as:51-57`, and
`tm-magic-spectator/src/Interface.as:65-70`. Many others pass constants or measured
widths directly, including `tm-archivist/src/Settings.as:155-156` and
`tm-better-totd/src/Stats.as:213-219`.

Treat fixed-width scaling as unresolved until probed. Never multiply a
`WidthStretch` weight: the same argument is a relative weight in that mode.

### NanoVG coordinates

Corpus code treats NanoVG as an independently scaled overlay canvas and explicitly
applies screen-height or custom transforms. Current Openplanet metadata does not
document NanoVG's base units or relationship to UI scale. Verify against display
bounds, then choose one scaling policy deliberately:

1. exact physical pixels;
2. resolution-relative scale such as `screenHeight / 1440`;
3. Openplanet UI scale via `UI::GetScale()`;
4. a user-configurable overlay scale.

Do not combine resolution normalization and UI scale accidentally. That is double scaling, not extra compatibility.

Resolution-relative examples include `tm-green-timer/src/GreenTimer.as:134-137`, `tm-alt-tab-freeze-warning/src/Main.as:79-85`, and `tm-map-together/src/Main.as:92-104`. Explicit NVG transforms appear in `tm-cgf-library/src/TTG/TicTacGo.as:1666-1673`.

### Manialink coordinates

Manialink/game-UI coordinates are neither ImGui logical units nor screen pixels. Their conversion must account for Manialink bounds, aspect-ratio side offsets, screen dimensions, and inverted Y.

Keep the chain explicit:

```text
Manialink coordinates
  --MLToScreen--> physical screen pixels
  --divide UI scale--> logical SetNextWindowPos input
```

The inverse remains unresolved because `UI::GetWindowPos()` units are undocumented.
Probe whether multiplying the getter by `UI::GetScale()` restores a stable
Manialink round trip before prescribing a reverse conversion.

Evidence: `tm-unintrusive-checkpoint-timer/src/CustomPos.as:40-44,68-89` and `tm-customize-cp-counter/src/CustomPos.as:68-82,105-122`.

### World and viewport coordinates

World positions, rotations, editor coordinates, block coordinates, and camera values are unrelated to Openplanet UI scale. Never multiply them by `UI::GetScale()`.

Project world geometry through the relevant camera/viewport API first, then determine
that projection API's output coordinate space before converting to a UI or overlay
destination.

Openplanet UI scale is also not OS DPI scale, Manialink `RelativeScale`, screen-height normalization, an NVG transform, or scaling of Trackmania's editor UI scene.

## Common gotchas

### Double scaling an auto-scaled setter

Wrong:

```angelscript
UI::SetNextItemWidth(100 * UI::GetScale());
```

Right for a logical design width:

```angelscript
UI::SetNextItemWidth(100);
```

Right for an already measured physical width:

```angelscript
UI::SetNextItemWidth(measuredWidthPx / UI::GetScale());
```

Apply the same distinction to `SetNextWindowPos` and `SetNextWindowSize`.

### Mixing units in one expression

After dividing a physical window position and size into logical units, add a logical gap such as `16`, not `16 * scale`. `tm-memory-timeline/src/MemorySnapshotRecordingTab.as:255-260` contains this suspicious mixed-unit shape.

For centering, choose one complete formulation:

```text
logical:  (screenWidthPx / scale - windowWidthLogical) / 2
physical: (screenWidthPx - windowWidthLogical * scale) / 2 / scale
```

Do not subtract a logical width directly from a physical screen width. See `tm-match-recorder/src/MatchLogUI.as:16-19` for a scale-sensitive case worth correcting separately.

### Converting position but not size

When both values came from physical screen geometry and both destinations auto-scale, convert both. `tm-dips-plus-plus/src/AuxiliaryAssets.as:63-69` divides its screen-derived position but not its screen-derived size, so scale values other than 1.0 can change the intended proportions.

### Asymmetric Manialink drag conversion

`tm-customize-cp-counter/src/CustomPos.as:68-82` divides `MLToScreen(...)` before `SetNextWindowPos`, but the reverse path sends `UI::GetWindowPos()` to `ScreenToML(...)` while a nearby comment questions a missing multiplication. Treat this as an unresolved live-test target, not established correctness.

### Scaling style and measured values twice

Do not blindly multiply values returned by style or measurement APIs. They may already describe current-layout pixels. Suspicious corpus examples include `tm-kr5-leaderboard-thingy/src/MapInfo.as:117` and Dips++ style calculations. Compare values at scale 1 and 2 before adding another multiplier.

`UI::PushStyleVar`, `UI::GetStyleVar*`, `UI::PushFontSize`, and `UI::PushFont` do
not document scaling behavior. Passing design constants directly is a corpus
convention, not a contract. Probe default and pushed style getter values, measured
text, font size, and resulting item rectangles at scales 1 and 2.

Do not generalize the documented `SetNextItemWidth` contract to `PushItemWidth`,
`Dummy`, `BeginChild(size)`, cursor setters, style setters, or font setters. Each
needs independent documentation or runtime evidence. Include
`GetFrameHeightWithSpacing()` in the probe: its description mentions pixel spacing
but does not state whether those pixels already incorporate UI scale.

### Runtime scale refresh

The scale is user-configurable, but current API docs do not say whether it changes
live, becomes visible without plugin reload, or requires restart.

Some plugins refresh during `RenderEarly` or render-time code, including
`tm-editor-plus-plus/src/Main.as:172-183` and
`tm-openplanet-plugin-template/src/GlobalVars.as:1-9`.

Others cache once or explicitly mention restart, including
`tm-plugin-hotkeys/src/Main.as:1`, `tm-magic-spectator/src/Main.as:49-50`,
`tm-dips-plus-plus/src/Main.as:236-238`, and
`tm-proximity-voice-chat/src/UI.as:18`. Reading at render time is safer if live
changes are supported; do not classify startup caches as wrong without the live-change probe.

### Ambiguous getter units

Current API descriptions do not explicitly document units or scaling behavior for every getter. `UI::GetMousePos()` is described as relative to the window's top-left, while corpus code sometimes treats it as absolute. Avoid broad claims; verify exact behavior when alignment depends on it.

## Practical decision table

| Source | Destination | Action |
| --- | --- | --- |
| Logical design constant | Auto-scaled setter | Pass directly |
| Proven screen-space/render measurement | Auto-scaled setter | Divide by `UI::GetScale()` once |
| Absolute screen position | Draw list | Pass directly |
| Logical padding/radius | Draw list | Probe primitive; explicit scaling is Corpus-derived |
| Content-region measurement | Same current layout | Use directly |
| Content-region measurement | `SetNextItemWidth` | Unresolved: compare direct vs divided at 1.0/2.0 |
| Fixed logical column width | `TableSetupColumn` | Unresolved; never scale stretch weights |
| Manialink coordinate | ImGui window setter | Manialink → screen px → divide scale |
| World coordinate | UI | Project first; never scale world values |
| Resolution-relative NVG geometry | NVG | Verify base units, then apply one deliberate policy |

## Refresh and test policy

Reading `UI::GetScale()` at render time is a conservative convention. Whether a
settings change becomes visible live or only after reload/restart is itself a probe result.

Test scaling-sensitive UI at minimum at UI scales **1.0 and 2.0**, including:

- a moved window;
- a child window;
- scrolling;
- a non-16:9 viewport;
- draw-list and NVG alignment;
- mouse hit testing;
- Manialink round trips when applicable.

A useful diagnostic plugin should display and log, at both scales:

- `Display::GetWidth/Height`;
- `UI::GetScale()`;
- `UI::GetWindowPos/Size`;
- `UI::GetCursorPos()` and `UI::GetCursorScreenPos()`;
- `UI::GetMousePos()`;
- `UI::GetContentRegionAvail()`;
- resulting item/window rectangles after passing a constant logical `100`.

That probe is the evidence needed to resolve undocumented getter units and expose accidental double scaling.

The checked-in DEV probe is `prototypes/ui-scaling-probe`. It compiles independently,
appears under `Plugins > Skillpack Demos > UI Scaling Probe`, and logs a single
`SCALE_PROBE` line on load or on demand. Capture its readout at scale 1.0 and again
at 2.0 without reloading between settings changes. Treat a one-scale capture as
partial evidence only: it cannot establish which getter values already incorporate
UI scale.

## Corpus audit provenance

A 2026-08-12 audit found no literal `UI::Scale` use. Raw reference counts vary
depending on comment filtering, sibling-repository inclusion, and duplicate checkout
policy, so this guide does not promote an unreproducible count as evidence. Direct
`UI::GetScale()` references occur in Better Chat, CGF Library, Customize CP Counter,
Dashboard, Dips++, Dips++ Editor, Draw Tests, Editor++, Ghosts++, Green Timer,
Magic Spectator, Match Recorder, Memory Explorer/Timeline, Music Mania, the plugin
template, Plugin Hotkeys, Proximity Voice Chat, Simple Room Admin, Unintrusive CP
Timer, and related plugins.

The rules above separate **API-documented** behavior from **Corpus-derived** conventions and explicitly retain unresolved live probes rather than presenting inference as contract.
