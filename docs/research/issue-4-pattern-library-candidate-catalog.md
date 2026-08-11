# Issue 4 — Provenance-cleared pattern-library candidate catalog

**Ticket:** [Build the provenance-cleared pattern-library candidate catalog](https://github.com/XertroV/tm-plugin-skills/issues/4)
**Map:** [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1)
**Status:** Research evidence asset (do not treat as recipe implementation)
**Research date:** 2026-08-11
**Corpus root:** `~/src/openplanet/` (primarily `my-plugins/`, plus standalone sibling repos)

---

## 1. Question answered

Which recurring AngelScript/Openplanet patterns across Max’s repositories deserve promotion into version one’s candidate recipe library, and which should remain historical or experimental?

This document answers with a **ranked, provenance-cleared candidate catalog** and **promotion criteria**. It does **not** copy recipe code, implement skills, or close the ticket.

---

## 2. Method

### 2.1 Corpus

| Source | Scope (approx.) | Notes |
|--------|-----------------|-------|
| `my-plugins/*` | ~141 plugins with `info.toml`; ~154 git checkouts | Primary pattern mine |
| Standalone siblings | `tm-green-timer`, `tm-memory-explorer`, `tm-modless-skids`, `tm-proximity-voice-chat`, `tm-dipspp-editor`, … | Often fresher remotes of the same projects |
| Workspace index | `README_FOR_AGENTS.md`, `CLAUDE.md` | Process/wisdom, not recipes |
| Official docs (local archive) | openplanet.dev tutorials/reference (indexed, not re-mirrored here) | Validates that patterns map to real OP APIs |

License snapshot across `my-plugins/*`: **~134 Unlicense/public-domain**, ~3 MIT, ~18 no license file. Promotion prefers Unlicense/PD sources; MIT/no-license items are flagged.

### 2.2 Ranking dimensions

Each candidate is scored qualitatively **H / M / L** on:

| Dimension | Meaning |
|-----------|---------|
| **Recency** | Active 2025–2026 use vs. frozen older code |
| **Repetition** | Appears in many plugins or is the settled house default |
| **Settled history** | File/commit longevity; few thrashing rewrites |
| **Portability** | Works with only Openplanet + filesystem; no private infra |
| **Dependencies** | Built-in only vs. mature ecosystem dep vs. Max-only dep |
| **Testability** | Observable completion gates (log line, UI, state flag, reload) |

### 2.3 Intended tiers (catalog labels, not final product tiers)

| Tier | Meaning for later recipe promotion |
|------|-------------------------------------|
| **core-v1** | Strong default for portable skillpack recipes |
| **extended-v1** | Documented optional recipe; not assumed |
| **ecosystem-dep** | Prefer depending on mature plugin over reimplementing |
| **advanced-dev** | Hooks/patches/RE-adjacent; gated, not default |
| **historical** | Superseded or frozen; cite only as history |
| **experimental** | Recent/unsettled; watch, do not promote yet |
| **visual-coord** | Owned by [visual design ticket](https://github.com/XertroV/tm-plugin-skills/issues/3); listed only for coordination |

### 2.4 Provenance rules

For every candidate below:

- **Repo** — GitHub or local path under the openplanet workspace
- **File** — primary exemplar path
- **Commit** — latest meaningful file tip (short SHA) and/or introduction when known
- **License** — Unlicense/PD unless noted
- **Validation** — what must be true before a recipe may ship

Public snippets later **must** retain source repo/file and license (map constraint from issue 1).

---

## 3. Coordination with the visual ticket

[Issue 3 — Curate the theme-respecting three-tier visual design skill](https://github.com/XertroV/tm-plugin-skills/issues/3) owns:

- Default ImGui theme-respecting layout
- NVG helpers (text, stroke/shadow, labels, scissors, shapes, overlays)
- Advanced ImGui style vars, draw lists, gradients, animation libraries
- Screenshot completion gates; `tm-agent` brand styling vs. defaults
- Dips++ / Bosslike animation and sprite/draw-list systems

This catalog **does not** promote visual recipes. It only:

1. Names **structural UI shells** (windows, tabs, menu items, notifications) that visual recipes will sit inside.
2. Flags cross-links (`visual-coord`) where a structural pattern has a visual twin.
3. Keeps green-timer / HUD positioning as **behavior + window flags**, not palette/style.

---

## 4. Corpus findings (executive)

### 4.1 Ubiquity signals (file counts under `my-plugins`, order-of-magnitude)

| Pattern | Approx. files / plugins |
|---------|-------------------------|
| `GetApp()` | ~479 files |
| `startnew` / `yield` | ~411 / ~454 files |
| `trace` / `warn` | ~429 / ~442 files |
| `UI::Begin` / `UI::MenuItem` / `UI::ShowNotification` | ~151 / ~135 / ~121 files |
| `[Setting …]` usage | ~291 files |
| Separate `Settings.as` | ~68 files |
| `build.sh` present | ~139 plugins |
| `OnDisabled` / unload pairing | common on hook/ML plugins |
| `dependencies` peaks | `MLHook`, `VehicleState`, `NadeoServices`, `Camera`, `MLFeedRaceData` |

### 4.2 Settled house defaults

1. **Plugin root = `info.toml` + `src/`**, staged by `build.sh` (template), *or* portable folder-in-`Plugins/` (skillpack product default — different deployment story, same source shape).
2. **Callbacks split by concern:** `Main` boots coroutines; `RenderEarly` updates globals/state; `Render` / `RenderInterface` draw; `RenderMenu` toggles; `OnDisabled`/`OnDestroyed` unload.
3. **Settings:** `[Setting category=…]` + optional `[SettingsTab]`; enable flags drive UI.
4. **User feedback:** `Notify` / `NotifyError` / `NotifyWarning` wrapping `UI::ShowNotification` + log.
5. **Async:** `startnew` + `yield` loops; `WaitAndClearTaskLater` for Nadeo task results.
6. **Game context:** prefer a small **state monitor** (`TM_State` lineage) over ad-hoc `GetApp()` soup at call sites.
7. **Deps:** use **VehicleState / Camera / NadeoServices / MLHook / MLFeed** rather than reimplementing.

### 4.3 What not to promote as defaults

- Memory hooks / `MemPatcher` / pattern scans as everyday recipes (`advanced-dev` only).
- Private MapMonitor endpoints as universal infrastructure.
- Dashboard (upstream MIT, Miss) internals as Max-owned Unlicense recipes.
- Better Chat (Miss) patterns without separate license clearance.
- `tm-agent` / `tm-control-mcp` / `tm-mcptm` until license files exist (process exemplars only).
- Forced brand ImGui styling from `tm-agent` (visual ticket; anti-default).

---

## 5. Promotion criteria (resolve-with)

A pattern graduates from this catalog into a **v1 recipe** only if all hold:

1. **Provenance-clear:** Unlicense/PD (or explicit dual-license compatible with skillpack `CC0-1.0 OR Unlicense`), with repo/file/commit recorded.
2. **Settled:** used in ≥2 real plugins *or* is the canonical template form, with no active rewrite thrash.
3. **Portable path exists:** works without RemoteBuild/MCP/LSP; optional tools only tighten the loop.
4. **Dependency honest:** required deps listed; prefer mature ecosystem plugins over vendored clones when the dep is the product.
5. **Testable gate:** at least one of — compile/load clean, log assertion, settings round-trip, visible menu/window toggle, map-change edge, unload without leak/hook residue.
6. **Non-duplicative of issue 3** for pure visual content.
7. **Compact AngelScript** suitable for progressive disclosure (recipe short; deep variants in references).

**Stability sub-labels for later versioning policy (issue map still open):**

- `stable` — core-v1 after live validation
- `draft` — catalog-only
- `deprecated` — historical

---

## 6. Candidate catalog

IDs are stable handles for later tickets (`P-###`). Scores are H/M/L.

---

### 6.A Plugin structure and packaging

#### P-001 — Canonical plugin skeleton (`info.toml` + `src/` + callbacks)

| Field | Value |
|-------|--------|
| **Gist** | Minimal modern plugin: meta toml, `Main`/`RenderMenu`, settings enable flag, menu title with icon color. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H (none) · Testability H |
| **Tier** | **core-v1** |
| **Repo** | [XertroV/tm-openplanet-plugin-template](https://github.com/XertroV/tm-openplanet-plugin-template) |
| **Files** | `info.toml`, `src/Main.as`, `src/Settings.as` |
| **Commit** | tree `891025b` (2025-08-22); files introduced `78ac9dc` (2025-07-24) |
| **License** | Unlicense |
| **Validation** | Load plugin; menu item toggles `S_Enabled`; no compile error after reload. |
| **Notes** | Template README currently says “don’t put repo in Plugins/” because of *its* build staging. Skillpack portable default (folder-in-Plugins) remains valid — detect build script rather than requiring it (issue 1). |

#### P-002 — Staged build scripts (`build.sh` / `build.py` / `build.ps1`)

| Field | Value |
|-------|--------|
| **Gist** | Copy `src/*` + `info.toml` + license/readme into Openplanet Plugins staging; optional RemoteBuild hot reload. |
| **Scores** | Recency H · Repetition H (~139 `build.sh`) · Settled H · Portability M · Deps M · Testability H |
| **Tier** | **extended-v1** (capability-detected, not required) |
| **Repo** | template (above); also nearly every Max plugin |
| **Files** | `build.sh`, `build.py`, `build.ps1`, template `README.md` |
| **Commit** | template `891025b` |
| **License** | Unlicense |
| **Validation** | `./build.sh dev` produces staged folder; game shows Loaded plugin. |
| **Notes** | Coordinate with lifecycle/capability research (issue 6). Portable path = manual copy or live folder. |

#### P-003 — `#__DEFINES__` and dev/sig preprocessor splits

| Field | Value |
|-------|--------|
| **Gist** | `info.toml` `[script] #__DEFINES__`; code uses `#if DEV` / `#if SIG_DEVELOPER` for debug UI and tracing. |
| **Scores** | Recency H · Repetition H (~235 files) · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** |
| **Repo** | template `info.toml`; exemplars bosslike `DevLog.as`, mlfeed `Main.as` |
| **Files** | `info.toml`; `src/DevLog.as` (bosslike) |
| **Commit** | bosslike tip `79c1949`; pattern widespread |
| **License** | Unlicense |
| **Validation** | Dev build shows debug paths; release build strips them (no open debug windows). |

#### P-004 — Global frame metrics (`g_screen`, `g_scale`, `RenderEarly`)

| Field | Value |
|-------|--------|
| **Gist** | Update screen size and UI scale once per frame before other render work. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** |
| **Repo** | template |
| **Files** | `src/GlobalVars.as` |
| **Commit** | `78ac9dc` / tip `891025b` |
| **License** | Unlicense |
| **Validation** | Values change on resolution/scale change; consumers read globals only after `RenderEarly`. |
| **Visual-coord** | Positioning math only; no styling. |

#### P-005 — Plugin identity constants (name, icon, menu title)

| Field | Value |
|-------|--------|
| **Gist** | `Meta::ExecutingPlugin().Name`, hash-derived icon color (template demo) or fixed `Icons::*` + `MenuTitle`. |
| **Scores** | Recency H · Repetition H · Settled M · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** (fixed icon preferred over random-hash demo) |
| **Repo** | template `src/Main.as`, `src/Utils.as` (`GetRandomIcon`) |
| **Commit** | `78ac9dc` |
| **License** | Unlicense |
| **Validation** | Menu label stable across reloads when icon fixed. |
| **Notes** | Teach fixed icon as production form; hash-random is template sugar. |

---

### 6.B Settings

#### P-010 — Category settings + enable flag

| Field | Value |
|-------|--------|
| **Gist** | `[Setting category="General" name="Enabled"] bool S_Enabled = true;` drives menu and windows. |
| **Scores** | Recency H · Repetition H (General category ~197 hits) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template `src/Settings.as` |
| **Commit** | `78ac9dc` |
| **License** | Unlicense |
| **Validation** | Toggle in settings UI and via menu; persists across reloads. |

#### P-011 — Hidden settings for persisted UI state

| Field | Value |
|-------|--------|
| **Gist** | `[Setting hidden]` for positions, versions, internal enums not shown in default settings panels. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** |
| **Repo** | template; green-timer `src/GreenTimer.as`; ghosts-pp scrubber settings |
| **Files** | e.g. green-timer hidden pos/size; ghosts-pp `S_SavedOkayGameVersion` |
| **Commit** | green-timer file tip `0ce5b2e` (2024-12-20); ghosts-pp version compat `6269fe4` (2025-12-21) |
| **License** | Unlicense |
| **Validation** | Drag/persist position survives reload; hidden keys absent from casual settings browse. |

#### P-012 — Settings tabs and ranged settings

| Field | Value |
|-------|--------|
| **Gist** | `[SettingsTab name=… icon=… order=…]` custom panels; `min=`/`max=` on floats for positions. |
| **Scores** | Recency H · Repetition M (~64 files with SettingsTab) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | green-timer `src/Main.as` (`SettingsTab` General); ghosts-pp Game Version tab |
| **Commit** | green-timer `0ce5b2e`; ghosts-pp `6269fe4` |
| **License** | Unlicense |
| **Validation** | Custom tab renders; slider clamps; `OnSettingsChanged` reacts when used. |

#### P-013 — `OnSettingsChanged` fan-out

| Field | Value |
|-------|--------|
| **Gist** | Callback recomputes derived state / restarts coroutines when settings change. |
| **Scores** | Recency H · Repetition M (~37 plugins) · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **extended-v1** |
| **Repo** | many; e.g. `tm-buffer-time`, `tm-cotd-hud`, `tm-autohide-opponents` |
| **License** | prefer Unlicense exemplars (`tm-buffer-time`, etc.) |
| **Validation** | Change setting → observable reconfigure without full plugin reload. |

---

### 6.C Tabs, windows, menus (structural UI — not visual styling)

#### P-020 — Overlay window with enable binding

| Field | Value |
|-------|--------|
| **Gist** | `RenderInterface`: `UI::Begin(title, S_Enabled)`; early-return inner draw; always `UI::End()`. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template `src/DemoWindow.as` |
| **Commit** | `78ac9dc` |
| **License** | Unlicense |
| **Validation** | Window closes via X and clears enable; only when overlay shown. |
| **Visual-coord** | Contents/styling → issue 3. |

#### P-021 — Always-on `Render()` vs overlay `RenderInterface()`

| Field | Value |
|-------|--------|
| **Gist** | Gameplay HUD in `Render()`; tooling windows in `RenderInterface()`; document the split. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template DemoWindow comments; green-timer `Render`; bosslike `OpenplanetCallbacks.as` |
| **Commit** | bosslike callbacks tip path via `8789101` history; green-timer `0ce5b2e` |
| **License** | Unlicense |
| **Validation** | HUD visible with overlay hidden; tool window follows overlay. |

#### P-022 — Menu item toggle under Plugins menu

| Field | Value |
|-------|--------|
| **Gist** | `RenderMenu` + `UI::MenuItem(MenuTitle, "", S_Enabled)` toggles setting. |
| **Scores** | Recency H · Repetition H (~119 RenderMenu) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template `src/Main.as` |
| **Commit** | `78ac9dc` |
| **License** | Unlicense |
| **Validation** | Click menu ↔ setting/window state. |

#### P-023 — Simple Tab class (pop-out optional)

| Field | Value |
|-------|--------|
| **Gist** | Lightweight `Tab` with `DrawTab`/`DrawInner`/`DrawWindow`, optional pop-out and remove. |
| **Scores** | Recency M · Repetition M (BRM, archivist, vip-everyone, map-monitor) · Settled H (since ~2023) · Portability H · Deps H · Testability H |
| **Tier** | **extended-v1** (default multi-page UI) |
| **Repo** | [XertroV/tm-better-room-manager](https://github.com/XertroV/tm-better-room-manager) |
| **Files** | `src/Tabs/Tab.as` |
| **Commit** | file tip `61d29be` (2023-01-14); still shipped in 2026 releases |
| **License** | Unlicense |
| **Validation** | Tabs switch; pop-out window hosts same `DrawInner`. |
| **Visual-coord** | Tab chrome only. |

#### P-024 — Hierarchical TabGroup system (Editor++ scale)

| Field | Value |
|-------|--------|
| **Gist** | Nested `Tab`/`TabGroup`, selection propagation, sidebar labels, fav/warning indicators. |
| **Scores** | Recency H · Repetition M (E++, dips editor, unbeaten-ats, draw-tests) · Settled H (25 commits on UI_Tab) · Portability H · Deps H · Testability M |
| **Tier** | **extended-v1** (large tools only; not default for small plugins) |
| **Repo** | [XertroV/tm-editor-plus-plus](https://github.com/XertroV/tm-editor-plus-plus) |
| **Files** | `src/UI/UI_Tab.as`, `src/UI/UI_TabGroup.as` |
| **Commit** | UI_Tab tip `34ec600` (2025-05-13); repo tip active 2026-08 |
| **License** | Unlicense |
| **Validation** | Nested selection; pop-out; remove tab without leaking children. |
| **Notes** | Too heavy for v1 “hello window”; promote as progressive-disclosure reference. |

#### P-025 — Frameless HUD window flags + drag mode

| Field | Value |
|-------|--------|
| **Gist** | `NoTitleBar|NoResize|NoDecoration|AlwaysAutoResize` (+ conditional `NoMove`); drag mode writes hidden normalized position. |
| **Scores** | Recency M–H · Repetition M · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** (structural HUD shell) |
| **Repo** | [XertroV/tm-green-timer](https://github.com/XertroV/tm-green-timer) (my-plugins + standalone) |
| **Files** | `src/Main.as` |
| **Commit** | my-plugins file `0ce5b2e`; standalone tip `81a9f03` (2026-04) |
| **License** | Unlicense |
| **Validation** | Timer shows in race; drag mode persists; hide-when-UI-off works. |
| **Visual-coord** | Timer drawing/NVG → issue 3; this candidate is window/lifecycle only. |

#### P-026 — Notify helpers (success/error/warning/dev)

| Field | Value |
|-------|--------|
| **Gist** | Thin wrappers: notification + `print`/`warn`/`error`/`trace`; dev-only variants behind `#if DEV` / `SIG_DEVELOPER`. |
| **Scores** | Recency H · Repetition H (dozens of plugins) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template `src/Utils.as`; bosslike `src/UI.as` |
| **Commit** | template `78ac9dc`; bosslike tip `79c1949` |
| **License** | Unlicense |
| **Validation** | Trigger each path; Openplanet log + toast appear; colors distinguishable. |

#### P-027 — UI micro-helpers (tooltip, disabled button)

| Field | Value |
|-------|--------|
| **Gist** | `AddSimpleTooltip`, `MDisabledButton` / `UX::ButtonDisabled` — structural UX, not theming. |
| **Scores** | Recency H · Repetition H (~16+ UIHelpers copies) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | ghosts-pp `src/UIHelpers.as`; bosslike `src/UX.as`, `src/UI.as` |
| **Commit** | UIHelpers `b5f0792` (2024-01-20); still current |
| **License** | Unlicense |
| **Validation** | Hover tooltip; disabled button non-clickable. |
| **Visual-coord** | No colors beyond OP defaults. |

---

### 6.D Game-state access and monitoring (**TM_State required lead**)

#### P-030 — **TM_State frame monitor (required lead)**

| Field | Value |
|-------|--------|
| **Gist** | Namespace updated from `RenderEarly`/`RunUpdate`: map uid + change edges, solo/server/editor/playground flags, UISequence helpers, medal times, wait-for-map-change coroutine support. |
| **Scores** | Recency H · Repetition M (bosslike + music-mania lineage; many plugins reinvent subsets) · Settled H · Portability H · Deps H (none) · Testability H |
| **Tier** | **core-v1** (canonical state-monitoring recipe) |
| **Primary repo** | [XertroV/tm-bosslike](https://github.com/XertroV/tm-bosslike) |
| **Primary file** | `src/TM_State.as` |
| **Primary commit** | tip `79c1949` (2025-08-15); **8 file commits**; introduced `ebde960` era |
| **Secondary** | [XertroV/tm-music-mania](https://github.com/XertroV/tm-music-mania) `src/TM_State.as` — extended with menu/loading/context flags + embedded music (`1fe675c` 2025-01-02; tip `9a18918` 2026-01) |
| **License** | Unlicense (both) |
| **Validation** | Enter/leave map → `DidMapChange`; solo vs server flags correct; UISequence Playing/Finish/Podium getters match game; no null crashes on menu. |
| **Recipe guidance** | Promote a **compact portable subset** (map edge, playground/editor/solo/server, UISequence) as core; treat music-mania context flags as optional extended module; do not require Bosslike game mode code. |
| **Wire-up exemplar** | bosslike `src/OpenplanetCallbacks.as` calls `TM_State::RenderEarly()` from `RenderEarly`. |

#### P-031 — GI / GameInfo accessor namespace (historical sibling)

| Field | Value |
|-------|--------|
| **Gist** | `GI::` helpers: typed `CTrackMania`, network, playground, score mgr, controlled player. Older than TM_State; more “getter soup,” less edge detection. |
| **Scores** | Recency L–M · Repetition M · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **historical** (prefer TM_State for monitoring; GI snippets only if needed for one-off accessors) |
| **Repo** | [XertroV/tm-cotd-hud](https://github.com/XertroV/tm-cotd-hud) `src/GameInfo.as` (`8a1850e`, 16 commits); also Unlicense copies in menu-bg-chooser / never-give-up |
| **License** | Unlicense |
| **Validation** | N/A for promotion; if cited, null-safe playground access. |

#### P-032 — VehicleState dependency usage

| Field | Value |
|-------|--------|
| **Gist** | `dependencies = ["VehicleState"]`; `VehicleState::GetVis` / `ViewingPlayerState` / RPM/wheels helpers. |
| **Scores** | Recency H · Repetition H (~13+ dep lines; dashboard+race HUDs) · Settled H · Portability M · Deps ecosystem · Testability H |
| **Tier** | **ecosystem-dep** + **extended-v1** usage recipe |
| **Repo** | consumers: e.g. `tm-cotd-buffer-time` `src/GameHelpers.as`, `tm-ak-hints`; upstream VehicleState is Openplanet site plugin (not Max) |
| **License** | Max consumer code mostly Unlicense; **do not vendor VehicleState** |
| **Validation** | With VehicleState installed, vis non-null in race; plugin disables cleanly if missing (if optional). |

#### P-033 — Camera dependency usage

| Field | Value |
|-------|--------|
| **Gist** | `Camera::GetCurrent`, `GetCurrentPosition`, `ToScreen` for projections. |
| **Scores** | Recency H · Repetition M–H · Settled H · Portability M · Deps ecosystem · Testability M |
| **Tier** | **ecosystem-dep** + **extended-v1** |
| **Repo** | `tm-camera-coords`, dips++ `nvg.as` (visual-coord for draw), cotd-buffer-time notes GPS camera bug |
| **License** | consumer Unlicense |
| **Validation** | Document known `GetCurrentPosition` GPS glitch; test ToScreen in stadium. |
| **Notes** | Camera math for agents may reference `tm-agent`/`tm-control-mcp` research docs but those repos lack LICENSE — process only. |

#### P-034 — MLFeed race data consumption

| Field | Value |
|-------|--------|
| **Gist** | Depend on `MLFeedRaceData` (+ MLHook); consume shared exports rather than injecting ML per plugin when feed suffices. |
| **Scores** | Recency H · Repetition H · Settled H · Portability M · Deps ecosystem · Testability H |
| **Tier** | **ecosystem-dep** (strongly preferred over re-injecting race ML) |
| **Repo** | [XertroV/tm-mlfeed-race-data](https://github.com/XertroV/tm-mlfeed-race-data) |
| **Files** | `info.toml` (exports/module), `src/Main.as` |
| **Commit** | Main tip `6280ba1` (2026-01-26); release `3d11c8c` 0.6.4 |
| **License** | Unlicense |
| **Validation** | Feed updates CP/race times in TA; unload unregisters hooks (`OnDisabled` → `MLHook::UnregisterMLHooksAndRemoveInjectedML`). |

#### P-035 — Permissions gate at startup

| Field | Value |
|-------|--------|
| **Gist** | Check `Permissions::*` (club/replay/map upload); notify and idle-loop if missing. |
| **Scores** | Recency M · Repetition M · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** for features that need club/replay rights |
| **Repo** | `tm-autosave-ghosts` `src/Main.as`; BRM maps helpers |
| **License** | Unlicense |
| **Validation** | Non-club account sees warning and no risky API calls. |

---

### 6.E Callbacks, coroutines, lifecycle

#### P-040 — Main boots background coroutines

| Field | Value |
|-------|--------|
| **Gist** | `void Main() { startnew(InitCoro); startnew(ClearTaskCoro); … }` — Main stays thin. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | widespread; bosslike `src/Main.as`; BRM; archivist; mlfeed |
| **License** | Unlicense exemplars |
| **Validation** | Coroutines run after load; no work on Main after kickoff except setup. |

#### P-041 — `yield` / `yield(n)` polling loops

| Field | Value |
|-------|--------|
| **Gist** | Wait for tasks/HTTP/auth with `while (!done) yield();`; paced loops use `yield(5)` etc. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** |
| **Repo** | ClearTasks, Http helpers, GameVersionCompat |
| **License** | Unlicense |
| **Validation** | No busy-spin frame drops; task completion observed. |

#### P-042 — `Meta::RunContext` scheduling

| Field | Value |
|-------|--------|
| **Gist** | `startnew(…).WithRunContext(…)` or `Meta::StartWithRunContext` for BeforeScripts/AfterScripts/GameLoop/etc. |
| **Scores** | Recency H · Repetition M · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **extended-v1** |
| **Repo** | mlfeed `Main.as`; music-mania `Main_Music.as`; E++; ghosts-pp |
| **Observed contexts** | AfterScripts, BeforeScripts, GameLoop, AfterMainLoop, UpdateSceneEngine, MainLoop, NetworkAfterMainLoop, Main |
| **License** | Unlicense |
| **Validation** | Behavior differs correctly vs default context (e.g. music instantiation only on GameLoop). |

#### P-043 — Canceller token for cooperative cancel

| Field | Value |
|-------|--------|
| **Gist** | Tiny `Canceller` class with `Cancel`/`IsCancelled` for long coroutines. |
| **Scores** | Recency M · Repetition L–M · Settled M · Portability H · Deps H · Testability H |
| **Tier** | **extended-v1** |
| **Repo** | bosslike `src/Canceller.as` |
| **Commit** | `fdf7b22` (2024-12-15) |
| **License** | Unlicense |
| **Validation** | Cancel mid-wait stops work at next check. |

#### P-044 — Symmetric unload (`OnDisabled`/`OnDestroyed` → `_Unload`)

| Field | Value |
|-------|--------|
| **Gist** | Both teardown callbacks call one `_Unload` that unregisters hooks, removes injected ML, clears patches. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps depends · Testability H |
| **Tier** | **core-v1** whenever hooks/ML/patches exist |
| **Repo** | mlfeed, autosave-ghosts, archivist, better-totd, cgf-library, … |
| **License** | Unlicense |
| **Validation** | Disable plugin → no leftover ML/hooks; re-enable clean. |

#### P-045 — Callback router file (`OpenplanetCallbacks.as`)

| Field | Value |
|-------|--------|
| **Gist** | Single file owns Update/RenderEarly/Render/RenderMenu and delegates to game modules. |
| **Scores** | Recency H · Repetition M · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **extended-v1** (medium+ plugins) |
| **Repo** | bosslike `src/OpenplanetCallbacks.as` |
| **Commit** | `8789101` (2025-01-11), 9 commits |
| **License** | Unlicense |
| **Validation** | State monitor + game render order stable. |

---

### 6.F Dependencies and exports

#### P-050 — `info.toml` dependency declaration patterns

| Field | Value |
|-------|--------|
| **Gist** | `dependencies`, `optional_dependencies`, `export_dependencies`, `exports` / `shared_exports`, `module`. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps n/a · Testability H |
| **Tier** | **core-v1** |
| **Repo** | mlfeed `info.toml`; template commented examples; bosslike deps BRM+MLFeed |
| **Commit** | mlfeed release `3d11c8c` |
| **License** | Unlicense |
| **Validation** | Missing required dep fails clearly; optional dep soft-checks. |

#### P-051 — Optional plugin feature detection

| Field | Value |
|-------|--------|
| **Gist** | `Meta::GetPluginFromID("…")` null/Enabled checks before calling into peers (ChampionMedals, ManiaExchange, MLHook, …). |
| **Scores** | Recency H · Repetition M–H · Settled H · Portability H · Deps optional · Testability H |
| **Tier** | **core-v1** |
| **Repo** | map-info, ghosts-pp, better-totd, magic-spectator, … |
| **License** | Unlicense consumers |
| **Validation** | With peer disabled, UI hides integration; no throw. |

#### P-052 — Shared exports authoring (library plugins)

| Field | Value |
|-------|--------|
| **Gist** | `exports` + `shared_exports` + `module`; `shared` types/functions for dependents. |
| **Scores** | Recency H · Repetition M · Settled H · Portability M · Deps H · Testability M |
| **Tier** | **extended-v1** (authors of libraries); default apps stay monolithic (issue 1) |
| **Repo** | mlfeed, E++, dips++, ghosts-pp, better-room-manager, … |
| **License** | Unlicense |
| **Validation** | Dependent compiles against exports; shared types match. |
| **Notes** | Cross-link Hermes `shared-export-audit` wisdom; skillpack should warn about dep costs. |

#### P-053 — Mature dependency shortlist (prefer over reimplementation)

| Dependency | Role | Max consumer signal |
|------------|------|---------------------|
| **MLHook** | ML inject/hooks | Very high |
| **MLFeedRaceData** | Race/KO/ghost feeds | High |
| **VehicleState** | Vehicle vis/state | High |
| **Camera** | Camera APIs | Medium–high |
| **NadeoServices** | Live/Meet APIs | High |
| **BetterRoomManager** | Room/map admin helpers | Medium (bosslike depends) |
| **ghosts-pp** | Ghost tooling peer | optional_dep pattern |

Tier: **ecosystem-dep** documentation recipe (install/declare/use), not vendoring.

---

### 6.G Logging, errors, runtime checks

#### P-060 — Standard log functions + dev_trace

| Field | Value |
|-------|--------|
| **Gist** | Prefer `trace`/`warn`/`error`/`print`; wrap noisy logs in `dev_trace` (`#if DEV` or `SIG_DEVELOPER`). |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | template Utils; bosslike DevLog |
| **Commit** | template `78ac9dc` |
| **License** | Unlicense |
| **Validation** | Dev vs release log volume differs; errors show in Openplanet log window. |

#### P-061 — Leveled logging helper

| Field | Value |
|-------|--------|
| **Gist** | `LogLevel` enum + `log_info/warn/error/trace/debug` gated by setting. |
| **Scores** | Recency M · Repetition M (~15 Logging.as) · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **extended-v1** |
| **Repo** | ghosts-pp `src/Logging.as` (`07b1580` 2023-10-02); copies in map-info, music-mania, … |
| **License** | Unlicense |
| **Validation** | Raising/lowering S_LogLevel changes output. |

#### P-062 — `warn_every_60_s` rate limit

| Field | Value |
|-------|--------|
| **Gist** | Dictionary-timed warning throttle for hot paths (hooks). |
| **Scores** | Recency M · Repetition M · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **extended-v1** / **advanced-dev** companion |
| **Repo** | template `advanced_dev/HookHelper.as` (copied from E++) |
| **License** | Unlicense |
| **Validation** | Spam path emits ≤1 warn/60s. |

#### P-063 — Game version compatibility gate

| Field | Value |
|-------|--------|
| **Gist** | Known-safe exe versions + optional openplanet.dev config JSON + user override setting; disable risky features on unknown builds. |
| **Scores** | Recency H · Repetition M (~8 GameVersionCompat files) · Settled H (27 commits ghosts-pp) · Portability M (network) · Deps H · Testability H |
| **Tier** | **extended-v1** for mempatch/hook plugins; not needed for pure UI |
| **Repo** | ghosts-pp `src/GameVersionCompat.as` tip `6269fe4` (2025-12-21) |
| **License** | Unlicense |
| **Validation** | Unknown version → warning + inactive; known version → active; settings tab override works. |

#### P-064 — throw + try/catch discipline

| Field | Value |
|-------|--------|
| **Gist** | `throw` for invariant violations (bad API paths, double-parent tabs); try/catch around fragile engine walks; **non-empty catch bodies** (LSP/game parser footgun). |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** (guidance) |
| **Repo** | BRM Http `AssertGoodPath`; E++ tabs; workspace `CLAUDE.md` empty-catch note |
| **License** | n/a (practice) |
| **Validation** | Checker/compile clean; catch contains token comment minimally. |

---

### 6.H Network, Nadeo, tasks, reusable helpers

#### P-070 — ClearTasks (Nadeo task result lifetime)

| Field | Value |
|-------|--------|
| **Gist** | Wait until `task.IsProcessing` false, queue `ClearTask`, background coro releases via appropriate manager. |
| **Scores** | Recency H · Repetition H (~13 copies) · Settled H (since BRM init) · Portability H · Deps H · Testability M |
| **Tier** | **core-v1** for any Nadeo task usage |
| **Repo** | bosslike / BRM / map-info / ghosts-pp `src/API/ClearTasks.as` |
| **Commit** | bosslike `edcd48d` (2024-12-23); BRM introduced `3444b5e` |
| **License** | Unlicense |
| **Validation** | No task-handle leaks after burst of API calls; coro stays alive. |

#### P-071 — NadeoServices Live/Meet HTTP helpers

| Field | Value |
|-------|--------|
| **Gist** | Audience add + auth wait; `NadeoServices::Get/Post`; path assert; User-Agent identifying plugin. |
| **Scores** | Recency H · Repetition H (~12 Http.as API copies) · Settled H · Portability M · Deps NadeoServices · Testability H |
| **Tier** | **extended-v1** + **ecosystem-dep** |
| **Repo** | BRM `src/API/Http.as` |
| **Commit** | present through BRM 0.3.6 (`9d643c2` 2026-01) |
| **License** | Unlicense |
| **Validation** | Authenticated GET returns JSON; bad path throws; UA visible in traces. |

#### P-072 — Openplanet Auth token cache (when needed)

| Field | Value |
|-------|--------|
| **Gist** | `Auth::GetToken` wait loop; cache ~55 minutes; single-flight update. |
| **Scores** | Recency M · Repetition M · Settled H · Portability M · Deps H · Testability M |
| **Tier** | **extended-v1** |
| **Repo** | map-info `src/API/Auth.as` (pattern; some copies commented if unused) |
| **License** | Unlicense |
| **Validation** | Token refresh; concurrent callers don’t double-fetch. |

#### P-073 — Plugin-identified `Net::HttpRequest` wrappers

| Field | Value |
|-------|--------|
| **Gist** | `PluginGetRequest`/`PluginPostRequest` set method + UA. |
| **Scores** | Recency H · Repetition H · Settled H · Portability H · Deps H · Testability H |
| **Tier** | **core-v1** |
| **Repo** | BRM Http.as (same as P-071) |
| **License** | Unlicense |
| **Validation** | External HTTP works offline-fail gracefully. |

#### P-074 — DTexture + TextureCache (async texture load)

| Field | Value |
|-------|--------|
| **Gist** | Storage-path texture waiter; URL cache helper; UI + nvg accessors. |
| **Scores** | Recency H · Repetition M · Settled M–H · Portability H · Deps H · Testability H |
| **Tier** | **extended-v1**; drawing bits **visual-coord** |
| **Repo** | template `src/Textures/DTexture.as`, `TexCache.as` (explicit PD source comment) |
| **Commit** | `78ac9dc` / tip `891025b` |
| **License** | Unlicense |
| **Validation** | File appears later → texture loads; URL fetch caches to storage. |

#### P-075 — MapMonitor API client (Max infra — optional)

| Field | Value |
|-------|--------|
| **Gist** | Client for `map-monitor.xk.io` nb_players/TMX next; local dev root switch. |
| **Scores** | Recency M · Repetition M · Settled H · Portability L · Deps private service · Testability M |
| **Tier** | **extended-v1** only as optional capability; **not** core portable |
| **Repo** | map-info `src/API/MapMonitor.as` |
| **License** | Unlicense client; service availability not guaranteed |
| **Validation** | Prod URL responds; S_LocalDev points to local. |

---

### 6.I Advanced-dev (gated)

#### P-080 — HookHelper (safe Dev::Hook wrapper)

| Field | Value |
|-------|--------|
| **Gist** | Pattern find + hook apply/unapply; destructor cleanup; warn throttle. |
| **Scores** | Recency H · Repetition M · Settled H · Portability L–M · Deps H · Testability M |
| **Tier** | **advanced-dev** |
| **Repo** | template `advanced_dev/HookHelper.as`; E++; ghosts-pp; dips++ |
| **License** | Unlicense |
| **Validation** | Requires P-063 version gate; apply/unapply on disable; game version matrix documented. |

#### P-081 — MemPatcher

| Field | Value |
|-------|--------|
| **Gist** | Multi-pattern mem patch with expected bytes and unapply on destroy. |
| **Scores** | Recency H · Repetition M · Settled H · Portability L · Deps H · Testability M |
| **Tier** | **advanced-dev** |
| **Repo** | template `advanced_dev/MemPatch.as`; E++; ghosts-pp |
| **License** | Unlicense |
| **Validation** | Same as hooks; never default recipe path. |

#### P-082 — RawBuffer / codegen memory helpers

| Field | Value |
|-------|--------|
| **Gist** | Low-level buffer helpers for explorers/timelines. |
| **Scores** | Recency M · Repetition L–M · Settled M · Portability L · Deps H · Testability L |
| **Tier** | **advanced-dev** / mostly **historical** for skillpack v1 |
| **Repo** | skids-magician, memory-timeline, draw-tests codegen |
| **License** | Unlicense where present |
| **Validation** | Out of v1 scope unless a dedicated reverse-engineering skill is approved later. |

---

### 6.J Visual-coord only (do not promote here)

| ID | Topic | Lead exemplars | Owner |
|----|-------|----------------|-------|
| V-001 | Theme-respecting default ImGui | template DemoWindow; avoid agent brand skin as default | Issue 3 |
| V-002 | NVG text/stroke/helpers | dips++ `nvg.as`; bosslike `Game/Draw/*` | Issue 3 |
| V-003 | Animation managers / sprites | bosslike `Game/Anim/*`, `SpriteSheet.as`; dips++ lightning | Issue 3 |
| V-004 | Screenshot review loop | `tm-agent` skill doc (license missing — process citation only) | Issue 3 |
| V-005 | Font load patterns | green-timer `LoadFonts`; bosslike nvg fonts | Issue 3 (+ structural LoadFonts coro ok as P-040 example) |

---

## 7. Ranked promotion shortlist (v1 recipe library candidates)

Ordered for skillpack usefulness × readiness (not pure popularity):

| Rank | ID | Candidate | Tier |
|------|----|-----------|------|
| 1 | P-001 | Plugin skeleton | core-v1 |
| 2 | P-010/011/012 | Settings patterns | core-v1 |
| 3 | P-022/020/021 | Menu + window callback split | core-v1 |
| 4 | P-026/060 | Notify + logging | core-v1 |
| 5 | P-030 | **TM_State monitor** | core-v1 |
| 6 | P-040/041/044 | Coroutines + unload | core-v1 |
| 7 | P-004/005 | Frame globals + identity | core-v1 |
| 8 | P-050/051/053 | Deps declare + optional detect + shortlist | core-v1 / ecosystem |
| 9 | P-027 | Tooltip/disabled button | core-v1 |
| 10 | P-025 | HUD window shell | core-v1 |
| 11 | P-070/071/073 | ClearTasks + Nadeo/HTTP | core/extended |
| 12 | P-023 | Simple tabs | extended-v1 |
| 13 | P-032/033/034 | VehicleState/Camera/MLFeed usage | ecosystem |
| 14 | P-042/043 | RunContext + Canceller | extended-v1 |
| 15 | P-063 | Game version gate | extended-v1 |
| 16 | P-024 | TabGroup hierarchy | extended-v1 |
| 17 | P-074 | DTexture/cache | extended-v1 |
| 18 | P-002/003 | Build scripts + defines | extended / core defines |
| 19 | P-052 | Shared exports authoring | extended-v1 |
| 20 | P-080/081 | Hook/MemPatch | advanced-dev only |

**Explicitly not shortlisted for v1 recipes:** P-031 (historical GI), P-075 (private MapMonitor as default), P-082, Dashboard/BetterChat internals, unlicensed agent/MCP code as copy sources.

---

## 8. Historical vs experimental summary

### Historical (cite, don’t promote as default)

- **GI/GameInfo accessor piles** (P-031) — superseded for monitoring by TM_State.
- **Early BRM Tab** remains valid but simpler than E++ TabGroup; both kept with different tiers.
- **cgf-library** (2023–2024) — rich but older monorepo-style; cherry-pick only if still unique.
- **Empty-catch and outdated IndexOf overloads** — anti-patterns documented in workspace notes.

### Experimental / license-blocked (watchlist)

| Item | Why blocked |
|------|-------------|
| `tm-agent` UI/camera agent loops | No LICENSE file; brand styling anti-default |
| `tm-control-mcp` / `tm-mcptm` | No LICENSE; lifecycle bridge owned elsewhere (issue 6) |
| Bosslike full game mode / room automation | Product-specific; only TM_State + callbacks generalized |
| Music-mania audio pack system | Valid TM_State consumer; audio domain out of core skillpack |
| MapMonitor service | Non-portable infra |
| Dashboard widget architecture | Upstream MIT (Miss), not Max Unlicense |

---

## 9. Suggested recipe packaging (for later implementation tickets)

Not implemented now — packaging hypothesis for issue 2 / implementation:

| Recipe cluster | Candidates | Disclosure |
|----------------|------------|------------|
| `op-plugin-skeleton` | P-001,005,010,022 | SKILL top |
| `op-settings` | P-010–013 | SKILL + ref |
| `op-ui-shell` | P-020–023,025–027 | SKILL; visual ref → issue 3 skill |
| `op-tm-state` | P-030,035 | SKILL (TM required) |
| `op-async-lifecycle` | P-040–045,070 | SKILL |
| `op-deps-and-feeds` | P-050–053,032–034 | SKILL |
| `op-nadeo-http` | P-071–073 | reference |
| `op-logging` | P-060–062 | reference |
| `op-version-gate` | P-063 | reference (hook plugins) |
| `op-advanced-hook` | P-080–081 | gated advanced skill |

---

## 10. Validation matrix (minimum live gates before recipe freeze)

| Gate | Applies to |
|------|------------|
| `openplanet-lsp check` clean (when available) | all code recipes |
| Load/reload: `Loaded plugin` without compile error | all |
| Disable/enable without residual hooks/ML | P-044,034,080,081 |
| Settings persist + menu parity | P-010–012,022 |
| Map enter/leave edges | P-030 |
| Overlay hidden vs shown behavior | P-020/021/025 |
| Toast + log line | P-026/060 |
| Dependency missing soft-fail | P-051,032–034 |
| Screenshot gate | **only** visual recipes (issue 3) |

---

## 11. Open follow-ons (out of scope for this ticket)

1. Final stability-tier names and versioning policy (map “Not yet specified”).
2. Whether TM_State ships as copy-paste recipe, submodule, or tiny companion library plugin.
3. License pass on `tm-agent` / control bridges before citing code.
4. Issue 3 visual catalog cross-links once that research lands.
5. Issue 6 capability ladder wiring for P-002 RemoteBuild detection.
6. Deduplicating the many forked copies of ClearTasks/Http/UIHelpers into one canonical recipe text (implementation chore).

---

## 12. Evidence index (quick paths)

| Topic | Best Unlicense exemplar | Tip / file commit |
|-------|-------------------------|-------------------|
| Skeleton | `tm-openplanet-plugin-template` | `891025b` / `78ac9dc` |
| TM_State | `tm-bosslike/src/TM_State.as` | `79c1949` |
| TM_State extended | `tm-music-mania/src/TM_State.as` | `1fe675c` / tip `9a18918` |
| Callbacks router | `tm-bosslike/src/OpenplanetCallbacks.as` | `8789101` |
| Simple tabs | `tm-better-room-manager/src/Tabs/Tab.as` | `61d29be` |
| Big tabs | `tm-editor-plus-plus/src/UI/UI_Tab*.as` | `34ec600` |
| HUD shell | `tm-green-timer/src/Main.as` | `0ce5b2e` |
| ClearTasks | `tm-bosslike/src/API/ClearTasks.as` | `edcd48d` |
| Nadeo HTTP | `tm-better-room-manager/src/API/Http.as` | BRM `9d643c2` tree |
| Version gate | `tm-ghosts-plus-plus/src/GameVersionCompat.as` | `6269fe4` |
| MLFeed library | `tm-mlfeed-race-data` | `6280ba1` / `3d11c8c` |
| Notify/utils | template `src/Utils.as` | `78ac9dc` |
| Hooks/patches | template `advanced_dev/*` | `891025b` |

---

## 13. Resolution gist (for human map comment later)

> Across ~140 Max Openplanet plugins, v1 recipe promotion should center on the template skeleton, settings/menu/window shells, Notify/logging, coroutine+unload lifecycle, Nadeo ClearTasks/HTTP, ecosystem deps (VehicleState/Camera/MLHook/MLFeed), and **Bosslike’s `TM_State` as the required game-state monitoring lead** (with music-mania extensions optional). Hierarchical Editor++ tabs, version gates, and hook/mempatch stay extended/advanced. Visual NVG/animation/screenshot patterns defer to issue 3. Dashboard/BetterChat/unlicensed agent-MCP code stay out of copy-paste provenance. Full ranked catalog with repo/file/commit/license/validation: this document.

---

*End of research asset for issue 4. No recipes implemented; issue left open for human resolution.*
