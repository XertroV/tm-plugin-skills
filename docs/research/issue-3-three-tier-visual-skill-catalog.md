# Research: Theme-respecting three-tier visual design skill

**Ticket:** [Curate the theme-respecting three-tier visual design skill](https://github.com/XertroV/tm-plugin-skills/issues/3)
**Map:** [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1)
**Date:** 2026-08-11
**Branch:** `research/issue-3`
**Scope:** Research and catalog only. No skill implementation. No issue close/edit.
**Corpus root:** `~/src/openplanet/my-plugins/` (and local clones under `~/src/openplanet/`).

---

## 1. Question answered

What exact structure, recipes, examples, and verification gates should define a non-prescriptive Openplanet visual-design skill with three major paths?

Required product direction (from the ticket and map Notes):

1. **Default:** standard Openplanet ImGui, preserve the active user-installed Openplanet theme, no fixed palette assumptions.
2. **NVG:** compact, provenance-cleared copyable helpers (text stroke/shadow, labels, scissors, shapes, overlays).
3. **Advanced:** full ImGui style/color variables and layout, tables, draw lists, gradients, pulsing, clipping, custom shapes, advanced NVG, reusable animation libraries.

Required exemplars: `tm-agent` (2026-04-20 screenshot/review loop; separate forced brand styling from defaults), Dips++ (NVG helpers, animation system, Deep Dip 2 intro lightning), Bosslike (newer animation manager, sprite/draw-list patterns).

---

## 2. Method and evidence discipline

- Inspected **current source** and **git history** (not names alone) in the three required plugins plus repeated helpers across Max's plugin corpus.
- Every candidate below records: **plugin**, **path**, **relevant commit(s)**, **HEAD inspected**, **license / provenance status**.
- Prefer **settled, repeated patterns** over one-off experiments.
- **Do not promote** code with unresolved license, third-party font restrictions incompatible with `CC0-1.0 OR Unlicense`, or brand-forced palettes into the default tier.
- Primary sources only: local plugin trees, their `LICENSE` files, and Openplanet API archive under `~/.llm-general/website-archives/openplanet/root/docs/api/`.

### HEADs inspected (2026-08-11)

| Plugin | Path | HEAD | Remote / license |
|--------|------|------|------------------|
| tm-agent | `my-plugins/tm-agent` | `f407a8d1c704058f1c5623a61f4a52e82c79374a` | **No remote configured; no LICENSE file** → code provenance **unresolved** for redistribution |
| tm-dips-plus-plus | `my-plugins/tm-dips-plus-plus` | `99b3114fcecce45f0255d592db0de5eea48b5772` | github.com/XertroV/tm-dips-plus-plus · **Unlicense** |
| tm-bosslike | `my-plugins/tm-bosslike` | `79c19495605619c985e276d4d73916f43be1a500` | github.com/XertroV/tm-bosslike · **Unlicense** (fonts separate) |
| tm-editor-plus-plus | `my-plugins/tm-editor-plus-plus` | `45853d91c5e007aa76181b3b3d00b336562a3813` | github.com/XertroV/tm-editor-plus-plus · **Unlicense** |
| tm-map-together | `my-plugins/tm-map-together` | `e56ae038d47dfc112989fc02f0382a2d3ff32f12` | github.com/XertroV/tm-map-together · **Unlicense** |
| tm-ghosts-plus-plus | `my-plugins/tm-ghosts-plus-plus` | (local tree) | github.com/XertroV/tm-ghosts-plus-plus · **Unlicense** |
| tm-green-timer | `my-plugins/tm-green-timer` | `b6b4b108328cf146745bc38d6dc79f20b63c5445` | github.com/XertroV/tm-green-timer · **Unlicense** |
| tm-map-info | `my-plugins/tm-map-info` | (local tree) | github.com/XertroV/tm-map-info · **Unlicense** |
| tm-openplanet-plugin-template | `my-plugins/tm-openplanet-plugin-template` | (local tree) | github.com/XertroV/tm-openplanet-plugin-template · **Unlicense** |
| tm-buffer-time | `my-plugins/tm-buffer-time` | (local tree) | github.com/XertroV/tm-buffer-time · **Unlicense** |
| tm-view-profile-demo | `my-plugins/tm-view-profile-demo` | (local tree) | github.com/XertroV/tm-view-profile-demo · **Unlicense** |
| tm-cgf-library | `my-plugins/tm-cgf-library` | (local tree) | github.com/XertroV/tm-cgf-library · **Unlicense** (fonts excluded in LICENSE note) |
| tm-item-placement-toolbox | `my-plugins/tm-item-placement-toolbox` | (local tree) | github.com/XertroV/tm-item-placement-toolbox · **Unlicense** |
| tm-freecam-show-cp | `my-plugins/tm-freecam-show-cp` | (local tree) | github.com/XertroV/tm-freecam-show-cp · **Unlicense** |
| tm-magic-spectator | `my-plugins/tm-magic-spectator` | (local tree) | github.com/XertroV/tm-magic-spectator · **Unlicense** |
| tm-draw-tests | `my-plugins/tm-draw-tests` | (local tree) | github.com/XertroV/tm-draw-tests · **Unlicense** |

---

## 3. Decisive answer (skill structure)

### 3.1 Skill packaging (recommended)

Ship **one skill entry point** with progressive disclosure into three tiers — not three disconnected skills. Agents need a single trigger for "visual UI work" and an explicit depth choice.

| Layer | Artifact | Purpose |
|-------|----------|---------|
| Entry | `visual-openplanet/SKILL.md` (name provisional; naming ticket owns final id) | Route by intent; enforce theme-respect default; point to screenshot gate |
| Tier 1 | `references/tier-1-default-imgui.md` | Theme-preserving ImGui recipes only |
| Tier 2 | `references/tier-2-nvg-recipes.md` + optional `scripts/` or `snippets/` of **cleared** helpers | Copyable NVG helpers |
| Tier 3 | `references/tier-3-advanced.md` | Full styling, tables, draw lists, animations, sprites — by reference + selected cleared recipes |
| Gate | `references/visual-completion-gate.md` | Screenshot loop; always required for visual changes |

**Progressive disclosure rule:** load Tier 1 always for ImGui window work; load Tier 2 only when the user/agent chooses world-space or freeform canvas drawing; load Tier 3 only when branding, custom chrome, tables at scale, or animation is requested.

### 3.2 Non-negotiable product rules (bind into the skill frontmatter + body)

1. **Default path never sets a full window palette.** No `PushTheme()` that paints `WindowBg`/`TitleBg`/`Button`/`Text` with fixed RGB. Use stock `UI::*` widgets so the user's Openplanet theme applies.
2. **Semantic color only when data demands it** (error/warn/ok, medal colors), preferably as *modulation of* `UI::GetStyleColor(...)` alpha/lerp — not a house brand.
3. **NVG and full custom ImGui styling are opt-in depths**, announced when chosen.
4. **Screenshot-based completion gate** is mandatory before declaring any visual change done (map Notes + ticket).
5. **tm-agent brand UI is an Advanced exemplar of forced styling, not the default.** The 2026-04-20 loop and API gotchas are portable; the amber slate palette is not.
6. **Public snippets require cleared provenance** compatible with this repo's `CC0-1.0 OR Unlicense`. Prefer Unlicense/public-domain Max plugins. Never vendor third-party fonts into snippets without separate license handling.

### 3.3 Tier routing table (agent decision)

| User / task signal | Tier |
|--------------------|------|
| Settings window, tabs, buttons, tables of data, "make a window" | **1 Default** |
| HUD overlay text, world labels, minimap markers, stroked titles | **2 NVG** |
| Branded plugin chrome, animated borders, spritesheets, intro FX, pulsing headers, custom shapes | **3 Advanced** |
| Any of the above after a visual edit | **+ Gate** |

---

## 4. Tier 1 — Default Openplanet ImGui (theme-preserving)

### 4.1 Intent

Build usable plugin UI that **inherits** the active Openplanet ImGui theme. Layout, hierarchy, and accessibility matter; palette does not.

### 4.2 Canonical patterns (promote)

#### T1-A — Minimal window shell (no style push)

- **Source:** `tm-openplanet-plugin-template/src/DemoWindow.as`
- **What:** `UI::SetNextWindowSize` + `UI::Begin(title, openFlag)` + inner function + `UI::End()`. Separates begin/end from content so early `return` cannot unbalance stack.
- **History:** template is the standing scaffold in Max's ecosystem (Unlicense).
- **License:** Unlicense · **cleared**
- **Skill guidance:** This is the default skeleton. Do not add `PushStyleColor` for chrome.

#### T1-B — Read theme metrics instead of hardcoding padding

- **Sources (repeated):**
  - `tm-ghosts-plus-plus/src/Scrubber.as` — `UI::GetStyleVarVec2(ItemSpacing|FramePadding)`, `UI::GetStyleColor(WindowBg|FrameBg|...)` then *only* multiply alpha for translucency.
  - `tm-green-timer/src/Main.as` — `UI::GetStyleVarVec2(WindowPadding)`
  - `tm-editor-plus-plus/src/Components/ToolbarTab.as` — FramePadding for toolbar geometry
  - Many others (map-monitor, better-room-manager, unbeaten-ats, memory-explorer) use the same idiom.
- **API:** Openplanet `UI::GetStyleColor`, `UI::GetStyleVarVec2`, `UI::GetStyleVarFloat` (archive: `docs/api/UI/GetStyleColor.md`, `GetStyleVarVec2.md`).
- **License:** Unlicense across cited plugins · **cleared**
- **Skill guidance:** Prefer `GetStyle*` for spacing and for any background tint that must match the theme. Scrubber's alpha-multiply pattern is the gold standard for "semi-transparent but still themed."

#### T1-C — Standard widgets and hierarchy without custom fonts

- **Sources:** template `DemoWindow.as` (`UI::TextWrapped`, `UI::SeparatorText`, `Icons::*`, `UI::Image`); widespread `UI::BeginTabBar` / `BeginTabItem` in Dips++ `MainUI/Window.as` (tabs themselves are fine in Tier 1; Dips window content is ordinary ImGui).
- **From tm-agent skill (portable gotcha, not brand):** built-in `UI::Font::DefaultBold` / `DefaultMono` before `UI::LoadFont` — documented in `tm-agent/SKILL-iterative-ui-screenshot-loop.md` (commit `7cde07c`, 2026-04-20).
- **License note:** agent skill file has **unresolved repo license** (no LICENSE on tm-agent). **Re-express the gotchas in skillpack voice** rather than copying the file verbatim until tm-agent license is fixed. Gotchas are factual API observations, not creative brand work.
- **Skill guidance:** hierarchy via bold built-in font, `SeparatorText`, tabs, collapsing headers — **without** recoloring Header/WindowBg.

#### T1-D — Disabled controls, tooltips, small helpers (no palette)

- **Source:** `tm-view-profile-demo/src/UIHelpers.as` (and near-duplicates in `tm-autosave-ghosts/src/UIHelpers.as`)
- **What:** `AddSimpleTooltip`, `DisabledButton` / `MDisabledButton` via `UI::BeginDisabled` — no colors.
- **License:** Unlicense · **cleared**
- **Skill guidance:** promote these as the default micro-helpers. Do **not** promote commented-out colored `ButtonVariant` blocks as default.

#### T1-E — Tables for structured data (theme default cells)

- **Sources:**
  - `tm-buffer-time/src/KoBufferDisplay.as` — `UI::BeginTable` + selective `PushStyleColor(Text, col)` only for **semantic** row status colors
  - `tm-ghosts-plus-plus/src/Interface.as` — tables + `UI::ListClipper` for long lists
  - `tm-dips-plus-plus/src/MainUI/Window.as` — `BeginTable` + `ListClipper` on spectators/donors/LB
- **License:** Unlicense · **cleared**
- **Skill guidance:** tables are Tier 1. Cell text color overrides are allowed only for semantic meaning (faster/slower, error), not brand. Prefer Openplanet string colors (`\\$f80`) only when already the project convention for in-text status — still not a window theme.

### 4.3 Explicit Tier-1 anti-patterns (do not teach as default)

| Anti-pattern | Evidence | Why banned from Tier 1 |
|--------------|----------|------------------------|
| Full `PushTheme()` chrome palette | `tm-agent/src/ChatUI.as` `PushTheme`/`PopTheme` — 22× `PushStyleColor` + 7× `PushStyleVar`, fixed dark slate + amber | Overrides user Openplanet theme entirely |
| Forced brand empty-state | `ChatUI.as` `DrawNotInEditor` amber badge/ornament (commit `7cde07c`) | Brand path; belongs in Tier 3 as *optional* branded empty state |
| Magenta header "fix" as default | Agent skill red-flag table pushes styled headers | Fine for brand polish; default should leave Header to theme |
| Assuming dark backgrounds | Agent skill "WindowBg alpha = 1.0" and neon-on-dark advice | Assumes dark theme; Tier 1 must not |

### 4.4 Tier-1 completion expectations

- Window renders under at least one non-default Openplanet theme without unreadable contrast *caused by plugin overrides* (if the user theme itself is poor, that is out of scope).
- No plugin-wide fixed `WindowBg`/`Text` RGB.
- Screenshot gate still required (see §7).

---

## 5. Tier 2 — NVG copyable recipes

### 5.1 Intent

Compact NanoVG helpers for HUDs, overlays, and world-anchored drawing. Recipes must be **small, copyable, and license-cleared**.

### 5.2 Canonical helper family (stroke / shadow / scissors / shapes)

Corpus scan found **≥15** near-copies of the same NVG helper file under names `nvg.as` / `Nvg.as` / `NvgHelpers.as`. Treat this as one family with a **canonical source** and known forks.

#### T2-A — Canonical full helper set (Dips++)

- **File:** `tm-dips-plus-plus/src/nvg.as` (261 lines at HEAD `99b3114`)
- **First substantial appearance:** commit `fbbe7aec307de9f9b732fe0691cb88b58510c7d0` (2024-02-20) "add code and changes to titles.txt"; scissors present from title-screen era `aaed2cab0ce7a0b3d6bc823ff1770c777e9c3910` (2024-02-23)
- **License:** Unlicense · **cleared for code**
- **Contents to promote as recipes (not necessarily one giant dump):**

| Recipe id | Symbols | Role |
|-----------|---------|------|
| T2-A1 | `DrawTextWithStroke`, `DrawTextWithShadow`, `DrawText`, `nTextStrokeCopies=12`, `TAU` | Stroked/shadowed NVG text via angular copies + `FontBlur` |
| T2-A2 | `scissorStack`, `PushScissor`, `PopScissor`, `nvg_Reset` | Nested scissor stack with restore; reset clears stack |
| T2-A3 | `nvgDrawPointCircle`, `nvgDrawPointCross` | Debug/marker shapes |
| T2-A4 | `drawLabelBackgroundTagLines`, `drawLabelBackgroundTagLinesRev` | Speech-tag / label chrome paths |
| T2-A5 | `nvgWorldPos*`, `nvgToWorldPos`, `nvgMoveToWorldPos` | Camera-projected world lines |
| T2-A6 | `nvgDrawBlockBox` | Oriented block AABB wireframe |
| T2-A7 | named `c*` color constants + `LightenV4Col` | Convenience palette for **NVG overlays** (opt-in depth; not ImGui theme) |

**Skill packaging recommendation:** ship **T2-A1 + T2-A2 + T2-A3** as the default copyable core. Gate T2-A5/A6 behind "editor/world overlay" subsection. Present `c*` constants as optional overlay palette, clearly **not** for ImGui theme override.

#### T2-B — Compact stroke-only variants (cleared forks)

| Plugin | File | Notes | License |
|--------|------|-------|---------|
| tm-green-timer | `src/nvg.as` | Stroke + shadow subset | Unlicense |
| tm-magic-spectator | `src/nvg.as` | Same family | Unlicense |
| tm-ghosts-plus-plus | `src/Nvg.as` | Minimal `DrawTextWithStroke` | Unlicense |
| tm-map-together | `src/nvg.as` | Near-full incl. scissors + label tags | Unlicense |
| tm-dipspp-editor / tm-draw-tests | `src/nvg.as` | Thin `nvgDrawTextWithStroke` | Unlicense |
| tm-alt-tab-freeze-warning | `src/nvg.as` | Stroke only | Unlicense |
| tm-bosslike | `src/Game/Draw/NvgHelpers.as` | Stroke/shadow + blur param + `TextInfo` overload | Unlicense |
| tm-editor-plus-plus | `src/nvg/NvgHelpers.as` | World pos + block box + stroke; no scissor stack | Unlicense · first in init `95527e6` (2023-05-03) |
| tm-item-placement-toolbox | `src/NvgHelpers.as` | World pos + block box | Unlicense |
| tm-freecam-targeter | `src/nvg.as` | World pos only | Unlicense |

**Canonical choice for skill snippets:** **Dips++ `nvg.as`** (most complete settled set used in a shipping flagship plugin) with Bosslike's `blur` parameter noted as a useful micro-diff.

#### T2-C — Simple scissor fill (inline, not stack)

- **Source:** `tm-dips-plus-plus/src/Inputs.as` (~lines 127–134) — `nvg::Scissor` / `ResetScissor` around partial key fill.
- **License:** Unlicense · **cleared**
- **Skill guidance:** teach raw scissor for single-level clips; teach **T2-A2 stack** when nesting is possible.

#### T2-D — NVG text box overlay card

- **Source:** `tm-dips-plus-plus/src/Anims/TextOverlayAnim.as` — `nvg::TextBoxBounds`, rounded rect background, `GlobalAlpha`, custom font face.
- **License:** Unlicense code · **fonts separate (see §8)**
- **Skill guidance:** promote the **layout recipe** (measure → pad → rounded rect → text box). Do not bundle Exo/Oswald font files until font provenance is resolved.

#### T2-E — Texture pattern draw (template)

- **Source:** `tm-openplanet-plugin-template/src/Textures/DTexture.as` — `NvgDrawImage`, `UI_AddImage` on window draw list.
- **License:** Unlicense · **cleared**
- **Skill guidance:** standard way to draw plugin textures in both UI and NVG spaces.

### 5.3 Tier-2 completion expectations

- Helpers call `nvg::Reset` or restore scissor/transform on exit paths where they change global NVG state.
- Overlay text remains legible on varied game backgrounds (stroke/shadow recipe addresses this without touching ImGui theme).
- Screenshot gate for any on-screen overlay change.

---

## 6. Tier 3 — Advanced (full styling, tables at scale, draw lists, NVG FX, animation, sprites)

### 6.1 Intent

Opt-in depth for branded tools, cinematic overlays, game-mode HUDs, and animation systems. Still **non-prescriptive**: show mechanisms and exemplars; do not mandate the amber-slate house look.

### 6.2 Subsections and candidates

#### T3-A — Full ImGui style stacks (brand chrome) — exemplar, not default

- **Source:** `tm-agent/src/ChatUI.as` — `PushTheme` / `PopTheme`, `AccentCollapsingHeader`, muted progress bar colors, drawlist accent line (`AddRectFilledMultiColor`), icon badge empty state.
- **Commits (2026-04-20 review loop day):**
  - `0d2e36564c88a36534966f45c9df508250570788` — stats bar redesign
  - `7cde07cc9e042551baa97fd45a65f0ac218c3009` — brand palette, drawlist centering, skill file, capture crop
  - `f407a8d1c704058f1c5623a61f4a52e82c79374a` — camera focus + further UI analysis tools (`capture_ui.py`, `BorderEffect`, `TextEffect`)
- **License:** **UNRESOLVED** (no LICENSE, no git remote on local tm-agent tree)
- **Skill guidance:**
  - Cite as **reference architecture** for balanced push/pop, drawlist chrome, and empty states.
  - **Do not copy code into the skillpack** until license/provenance is fixed (add Unlicense/CC0 to tm-agent, or reimplement patterns from cleared plugins).
  - Teach the *rule*: brand chrome is Tier 3 and must be explicitly requested.

#### T3-B — Draw-list borders, gradients, clip rects

- **Source (cleared patterns once re-expressed):** concepts demonstrated in tm-agent `BorderEffect.as`:
  - `UI::GetWindowDrawList()`
  - `PushClipRect` expanded to full window (content clip eats titlebar edges)
  - `AddRectFilledMultiColor` for gradient edge swirl
  - pixel-snapped coordinates (`Math::Floor`) for even border thickness
  - pair with `WindowBorderSize = 0` when replacing stock border
- **Also:** `tm-dips-plus-plus/src/LoadingScreens.as` — `UI::GetBackgroundDrawList()` + fullscreen `AddRectFilled` for loading takeover.
- **License:** LoadingScreens Unlicense · **cleared**; BorderEffect tied to tm-agent · **unresolved for verbatim copy**
- **Skill guidance:** document the API pattern; implement skillpack snippet from Dips background drawlist + independently written border helper, or wait for tm-agent license.

#### T3-C — Per-glyph draw-list text effects (pulse / wave)

- **Source:** `tm-agent/src/TextEffect.as` — char-by-char `UI::MeasureString` + `dl.AddText`, wave weights, dual-wave blend.
- **Commit:** added `f407a8d` (2026-04-20)
- **License:** tm-agent · **unresolved for verbatim copy**
- **Skill guidance:** Tier 3 recipe description; reimplementation allowed from description once desired; no vendoring until license cleared.

#### T3-D — Tables + ListClipper at scale

- **Sources (cleared):** Dips++ `MainUI/Window.as`; Ghosts++ `Interface.as`; Buffer-time `KoBufferDisplay.as`; Better Room Manager room maps table (uses `GetStyleVar` for layout).
- **License:** Unlicense · **cleared**
- **Skill guidance:** promote clipper + `ScrollY` + `SizingStretchProp` flags. This is the settled large-list pattern across Max's UI-heavy plugins.

#### T3-E — Animation base class + managers

| Variant | Path | Shape | First / key commits | License |
|---------|------|-------|---------------------|---------|
| Dips++ `Animation` | `tm-dips-plus-plus/src/Animation.as` | `Update() -> bool` + `Draw() -> vec2`; parallel arrays for subtitle/status/title anims; `ReplaceStatusAnimation` | Title era 2024-02 (`aaed2cab` / `fbbe7aec`) | Unlicense · **cleared** |
| Bosslike `Game::Animation` + `AnimMgr` + pool | `tm-bosslike/src/Game/Anim/Animation.as`, `Draw.as` | abstract Animation; `AnimMgr` QuadOut/EaseInBack; free-list pool in `Animations::AddAnimation` | `8789101` (2025-01-11 text), `1c3603a` (2025-01-21 "a bunch of animation and graphical stuff") | Local Unlicense evidence, but public upstream currently unavailable; **blocked for public snippet promotion** until vendored with provenance or linked to an accessible source |
| Shared `AnimMgr` only | `tm-map-info/src/AnimMgr.as` (added `d810788` 2023-01-29); `tm-freecam-show-cp/src/AnimManager.as`; editor-camera-hotkeys | open/close t∈[0,1] with QuadOut | 2023+ copies | Unlicense · **cleared** |

**Canonical advanced animation library for skillpack:** **Bosslike** (`Game::Animation` + `AnimMgr` + free-list `RenderAnimations`) — newer, namespaced, includes easing helpers, and pairs with sprite/text anims. Cite Dips++ as the earlier flagship multi-queue design (separate queues per anim kind).

#### T3-F — Deep Dip 2 intro lightning (custom NVG shape + timeline)

- **Source:** `tm-dips-plus-plus/src/Anims/SubtitlesAnim.as`
  - `class DeepDip2LogoAnim : Animation` (line ~382)
  - `lightningSegments` normalized polyline (line ~612)
  - `DrawBoltsMain` / `DrawBoltsExtra` / fill wedges between offset polylines
  - flash → bolt → bg move → fade timeline in `DrawMainLogoAnim`
  - audio `lightning2.mp3` via `AudioChain`
- **History:**
  - `44427c65afd79180e40ba8a43c3fb09138b2d914` (2024-04-25) "add dd2 anim start"
  - `73a17db9b8899d39b6bcf5758404e3a1b5380034` (2024-04-25) "nice title screen..." (lightningSegments introduced in blame/history of that day)
- **License:** Unlicense code · **cleared**; audio/font assets need separate check before bundling binaries
- **Skill guidance:** promote as **Tier-3 cinematic NVG case study** (segment polyline, dual-offset stroke, timed phases, `GlobalAlpha`). Prefer linking/referencing over pasting all 400 lines into the skill; optional condensed recipe for "polyline lightning bolt."

#### T3-G — Spritesheets (UI draw list + NVG)

- **Source:** `tm-bosslike/src/SpriteSheet.as`
  - `SpriteSheet` / `Sprite` / `SpriteFrame` / `SpriteGroup`
  - `UI_AddImage` via `dl.AddImage` with UV rect + flip
  - `nvgDrawSprite` via `nvg::TexturePattern` + transform scale for facing
- **History:** `56e7a193059765a4b231252da6c132ccd07861c9` (2024-11-22) "test sprites"; groups `e9bd1bb` (2024-11-28); ongoing through `1c3603a`
- **License:** Unlicense code · **cleared**; sprite **art assets** not verified here — skill teaches code patterns only unless asset licenses audited
- **Skill guidance:** canonical sprite pipeline for plugins that need frame animation.

#### T3-H — Procedural NVG shapes (flames / beziers)

- **Source:** `tm-bosslike/src/Animations/Flames.as` — `Draw_Test_Flames` bezier flame tongues, time-scrolled control points.
- **Commit:** present with animation bundle (`1c3603a` era; file in tree at HEAD)
- **License:** Unlicense · **cleared**
- **Skill guidance:** Tier-3 custom shape recipe (BezierTo, PathWinding, timed phase).

#### T3-I — Text anim + status box (Bosslike draw layer)

- **Sources:** `tm-bosslike/src/Game/Anim/TextAnim.as`, `LifeLost.as`, `Game/Draw/Text.as`, `NvgStatusBox.as`, `Fonts.as`
- **License:** code Unlicense · **fonts NOT cleared for bundling** (see §8)
- **Skill guidance:** animation + HUD text composition patterns; load fonts via Openplanet built-ins in examples unless font licenses are handled.

#### T3-J — Openplanet string gradients (text markup, not ImGui style)

- **Source:** `tm-cotd-hud/src/UIGradientWindow.as` — gradient text utilities in settings UI.
- **License:** Unlicense · **cleared**
- **Skill guidance:** optional advanced text flair; orthogonal to ImGui theme colors.

### 6.3 Tier-3 completion expectations

- Explicit user/agent choice of brand or cinematic depth.
- Push/pop balance on every path (agent skill's strongest portable lesson).
- Screenshot gate with fresh visual critique when polish is the goal; independent/subagent critique is recommended for advanced work but is not a universal topology requirement (see §7).
- No accidental leakage of Tier-3 chrome into plugins that asked for Tier 1.

---

## 7. Screenshot-based completion gate (verified 2026-04-20 tm-agent loop)

### 7.1 Verification: the loop exists and is dated 2026-04-20

| Artifact | Path | Commit | Date (author) |
|----------|------|--------|---------------|
| Skill doc | `tm-agent/SKILL-iterative-ui-screenshot-loop.md` | `7cde07cc9e042551baa97fd45a65f0ac218c3009` | 2026-04-20 03:19:39 +1000 |
| Capture (bash crop) | `tm-agent/capture_ui.sh` | evolved `4353f62` → `7cde07c` → later | 2026-04-20 |
| Capture (python + live dims) | `tm-agent/capture_ui.py` | `f407a8d1c704058f1c5623a61f4a52e82c79374a` | 2026-04-20 07:10:40 +1000 |
| Analyze helper | `tm-agent/analyze_ui.sh` | `4353f62` / `7cde07c` | 2026-04-20 |
| Brand polish using the loop | `ChatUI.as` large diff in `7cde07c` | same | 2026-04-20 |
| Sample screenshot | `tm-agent/tm_agent_ui.png` | `7cde07c` | 2026-04-20 |

**Conclusion:** The iterative screenshot/review loop is real, landed 2026-04-20, and was used to drive the ChatUI brand polish. It is the right **gate mechanism** for the skillpack. Its **brand aesthetic goals** ("stylish branded not generic dark theme", fixed palette) must be **rewritten for theme-respect** in Tier 1.

### 7.2 Gate procedure to encode in the skillpack

Portable steps (rephrase; do not require tm-agent scripts as the only capture path):

1. State the visual critique **before** the next code change.
2. One focused visual change per iteration.
3. Build/reload plugin; capture screenshot; **confirm PNG mtime**.
4. Prefer a **crop to the plugin window** (pin size/pos with `UI::Cond::Always` only while iterating; mark `// TEMP (dev only)`).
5. Agent describes what it **sees**, not what it intended.
6. Every 2–3 iterations **and** before "done": fresh critique with a blunt prompt; for advanced polish, prefer an independent subagent or external reviewer when available.
7. Layout disputes: draw expected rects via draw list (magenta/green asserts), then remove.

**Capability detection (map-aligned):** screenshot tooling is optional enhancement — `xdotool`+ImageMagick, Playwright, Control-MCP, or user-provided PNG all satisfy the gate if the image is fresh and shows the plugin UI. If no capture path exists, the agent must say the visual gate is blocked rather than claim completion.

### 7.3 Gate prompt variants by tier

| Tier | Critique goal line |
|------|--------------------|
| 1 Default | "Theme-respecting ImGui: no forced palette; hierarchy and spacing clear; legible under user theme." |
| 2 NVG | "Overlay legible on game scene; stroke/shadow adequate; no leaked scissor/transform." |
| 3 Advanced | "Intentional brand/cinematic polish; push/pop safe; motion/readability; not accidental stock ImGui tells *unless tier 1 was requested*." |

### 7.4 Separation: loop vs brand (ticket requirement)

| Keep for skillpack | Leave as Tier-3 optional exemplar only |
|--------------------|----------------------------------------|
| code→build→screenshot→critique loop | amber/slate fixed palette |
| subagent ruthlessness / anti-normalization | "not a generic dark theme" as universal goal |
| API gotchas table (`MeasureString`, drawlist `vec4(pos,size)`, font built-ins, push/pop balance) | full `PushTheme` chrome |
| drawlist layout asserts | TM AGENT empty-state ornament as default empty state |
| crop + mtime discipline | Cond::Always pins left in shipping code |

---

## 8. Provenance registry (candidates)

Status key: **cleared** = Unlicense/public-domain code OK to adapt into `CC0-1.0 OR Unlicense` skillpack · **unresolved** = do not copy until fixed · **asset-restricted** = code OK, binary/font not for blind vendoring.

| ID | Candidate | Path | Key commits / history | Provenance |
|----|-----------|------|----------------------|------------|
| T1-A | Minimal ImGui window | `tm-openplanet-plugin-template/src/DemoWindow.as` | template baseline | cleared (Unlicense) |
| T1-B | GetStyleColor/Var layout | `tm-ghosts-plus-plus/src/Scrubber.as` (+ many) | shipping ghosts++ | cleared |
| T1-C | Built-in fonts / icons | Openplanet API + agent skill gotchas | skill `7cde07c` | API public; skill text re-express (agent license unresolved) |
| T1-D | Tooltip / disabled button | `tm-view-profile-demo/src/UIHelpers.as` | demo helpers | cleared |
| T1-E | Tables + clipper | Dips `MainUI/Window.as`, Ghosts `Interface.as`, Buffer-time | multi-year | cleared |
| T2-A | Full NVG helpers | `tm-dips-plus-plus/src/nvg.as` | `fbbe7aec`, `aaed2cab`, HEAD `99b3114` | cleared (code) |
| T2-B | NVG helper forks | green-timer, map-together, e++, bosslike, … | see §5.2 | cleared (code) |
| T2-C | Inline scissor fill | Dips `Inputs.as` | shipping | cleared |
| T2-D | Text overlay card | Dips `Anims/TextOverlayAnim.as` | shipping | cleared code; fonts asset-restricted |
| T2-E | DTexture NVG/UI | template `Textures/DTexture.as` | template | cleared |
| T3-A | Brand PushTheme chrome | `tm-agent/src/ChatUI.as` | `7cde07c`, `0d2e365`, `f407a8d` | **unresolved** |
| T3-B | BorderEffect swirl | `tm-agent/src/BorderEffect.as` | `f407a8d` | **unresolved** |
| T3-B2 | Background drawlist wash | Dips `LoadingScreens.as` | shipping | cleared |
| T3-C | TextEffect waves | `tm-agent/src/TextEffect.as` | `f407a8d` | **unresolved** |
| T3-D | Large tables | same as T1-E depth | — | cleared |
| T3-E1 | Dips Animation queues | `tm-dips-plus-plus/src/Animation.as` | 2024-02+ | cleared |
| T3-E2 | Bosslike Anim + pool | `tm-bosslike/src/Game/Anim/*` | `8789101`, `1c3603a` | cleared |
| T3-E3 | AnimMgr open/close | map-info, freecam-show-cp | `d810788` (map-info) | cleared |
| T3-F | DD2 lightning | Dips `Anims/SubtitlesAnim.as` `DeepDip2LogoAnim` | `44427c65`, `73a17db` | cleared code; audio asset check before bundle |
| T3-G | SpriteSheet | `tm-bosslike/src/SpriteSheet.as` | `56e7a19`… | cleared code; art assets unchecked |
| T3-H | Flames bezier | `tm-bosslike/src/Animations/Flames.as` | anim bundle | cleared |
| T3-I | Bosslike HUD text/fonts | `Game/Draw/Text.as`, `Fonts.as` | `bf7c6b4` fonts | code cleared; **fonts asset-restricted** |
| T3-J | Text gradient tool | `tm-cotd-hud/src/UIGradientWindow.as` | shipping | cleared |
| GATE | Screenshot loop skill | `tm-agent/SKILL-iterative-ui-screenshot-loop.md` + scripts | `7cde07c`, `f407a8d` | **re-express**; agent license unresolved for verbatim file copy |

### 8.1 Font / binary assets (not cleared for skillpack vendoring)

| Asset | Location | License signal |
|-------|----------|----------------|
| Exo-LightItalic, Oswald-LightItalic | Dips++ repo root `*.ttf` | **No license file beside fonts**; do not vendor |
| Alagard | `tm-bosslike/src/fonts/alagard/license.txt` | CC BY 3.0 — attribution required; **not** CC0/Unlicense |
| Kelunia | `.../kelunia/license.txt` | CC BY-NC-ND 3.0 — **incompatible** with skillpack public-domain stance for bundled fonts |
| Golian | `.../golian/license.txt` | CC BY-ND 3.0 — attribution + no derivatives |
| Tengwar Pixel | `.../tengwar/license.txt` | CC0 — OK if attribution optional |
| lightning2.mp3 / voice lines | Dips++ audio | Not audited in this pass — reference only |
| Bosslike sprite textures | bosslike assets | Not audited — teach code only |

**Skill rule:** examples use `UI::Font::Default` / `DefaultBold` / `DefaultMono` or `nvg` default font unless the user already has fonts in their plugin.

### 8.2 tm-agent special case

Local tree has **author history (Max Kaye)**, intentional public-domain direction for Max's plugins generally, but **no LICENSE file and no `git remote`**. For research confidence:

- **Facts and procedures** (loop steps, API gotchas) → restate in skillpack.
- **Verbatim source** (ChatUI theme block, BorderEffect, TextEffect, skill markdown, capture scripts) → **blocked** until LICENSE added or code reimplemented under this repo's license.

---

## 9. Recommended skill body outline (implementation handoff)

```
visual-openplanet/SKILL.md
  - When to use / when not
  - Choose tier (table §3.3)
  - Always: theme-respect default + completion gate
  - Links to references/*

references/tier-1-default-imgui.md
  - Window shell, GetStyle*, widgets, tables basics
  - Anti-patterns: full PushTheme, fixed WindowBg

references/tier-2-nvg-recipes.md
  - Stroke/shadow text, scissor stack, markers
  - Optional: world pos, block box, overlay card
  - Snippet source: Dips nvg.as (cite path+commit+Unlicense)

references/tier-3-advanced.md
  - Brand chrome (describe; link tm-agent once licensed)
  - DrawList borders/gradients/clip
  - Animation: Bosslike canonical + Dips queues + AnimMgr
  - Sprites: Bosslike SpriteSheet
  - Cinematic: DD2 lightning case study
  - Tables+clipper at scale

references/visual-completion-gate.md
  - Loop steps, tier-specific critique prompts
  - Capture capability detection
  - API gotchas (rewritten)

snippets/ (only cleared, compact AS)
  - nvg_text_stroke.as
  - nvg_scissor_stack.as
  - imgui_disabled_tooltip.as
  - anim_mgr_quadout.as
  - (no fonts, no tm-agent verbatim until licensed)
```

---

## 10. Decisions locked by this research

1. **One skill, three progressive tiers**, not three unrelated skills.
2. **Tier 1 is strictly theme-preserving**; Scrubber-style `GetStyleColor` alpha modulation is the model for any translucency.
3. **Tier 2 canonical helper source is Dips++ `src/nvg.as`** (Unlicense), with Bosslike blur/`TextInfo` as documented deltas.
4. **Tier 3 animation design exemplar is Bosslike** (`Game::Animation` + `AnimMgr` + free-list), but public snippet promotion is blocked until its source is accessible or vendored with provenance; Dips++ remains the publicly accessible multi-queue and lightning cinematic exemplar.
5. **DD2 lightning is verified** in `SubtitlesAnim.as` (`DeepDip2LogoAnim`, commits `44427c65` / `73a17db`, Unlicense code).
6. **tm-agent 2026-04-20 loop is verified** (`7cde07c`, `f407a8d`) and becomes the completion gate; **brand palette is Tier 3 only** and not default.
7. **Verbatim tm-agent code is not copyable yet** (license/remote unresolved); patterns must be re-expressed or wait.
8. **Fonts and most binary assets are out of snippet bundles** pending per-file licenses; Tengwar is the rare CC0 font among Bosslike set.
9. **Screenshot gate is mandatory** for visual completion claims; capture mechanism is capability-detected, not hard-wired to one script. Catalog entries are candidates only until the gallery prototype live-validates them.
10. **Public snippets cite** `plugin/path`, commit SHA when stable, and license.

---

## 11. Explicit non-goals (this ticket)

- Implementing skill files or snippets in the skillpack repo.
- Closing or editing GitHub issue #3 / map #1.
- Live runtime validation inside Trackmania (static source+history research only).
- Auditing every plugin in `my-plugins/` — corpus scan focused on repeated visual helpers and required exemplars.
- Choosing final skill **names** / marketplace packaging (other map tickets).

---

## 12. Residual risks / follow-ups for other tickets

| Item | Why later |
|------|-----------|
| Add LICENSE (+ remote) to tm-agent | Unblocks BorderEffect/TextEffect/ChatUI snippet promotion |
| Font policy for skillpack | Packaging ticket; keep Default* fonts until then |
| Live screenshot of Tier 1 under 2+ Openplanet themes | Prototype ticket if fidelity required before impl |
| Whether snippets live in-repo vs. link-only to upstream SHAs | Distribution / recipe-catalog ticket on the map |
| Deduplicating NVG helpers into a tiny shared module vs. copy-paste recipes | Implementation choice; research favors **copy-paste recipes** for portable single-plugin default |

---

## 13. Source index (quick paths)

```
# Required exemplars
~/src/openplanet/my-plugins/tm-agent/SKILL-iterative-ui-screenshot-loop.md
~/src/openplanet/my-plugins/tm-agent/capture_ui.sh
~/src/openplanet/my-plugins/tm-agent/capture_ui.py
~/src/openplanet/my-plugins/tm-agent/analyze_ui.sh
~/src/openplanet/my-plugins/tm-agent/src/ChatUI.as
~/src/openplanet/my-plugins/tm-agent/src/BorderEffect.as
~/src/openplanet/my-plugins/tm-agent/src/TextEffect.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/nvg.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/Animation.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/Anims/SubtitlesAnim.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/Anims/TextOverlayAnim.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/Anims/MainTitleScreen.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/Inputs.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/LoadingScreens.as
~/src/openplanet/my-plugins/tm-dips-plus-plus/src/MainUI/Window.as
~/src/openplanet/my-plugins/tm-bosslike/src/Game/Anim/Animation.as
~/src/openplanet/my-plugins/tm-bosslike/src/Game/Anim/Draw.as
~/src/openplanet/my-plugins/tm-bosslike/src/Game/Draw/NvgHelpers.as
~/src/openplanet/my-plugins/tm-bosslike/src/SpriteSheet.as
~/src/openplanet/my-plugins/tm-bosslike/src/Animations/Flames.as

# Theme-respect & helpers
~/src/openplanet/my-plugins/tm-ghosts-plus-plus/src/Scrubber.as
~/src/openplanet/my-plugins/tm-openplanet-plugin-template/src/DemoWindow.as
~/src/openplanet/my-plugins/tm-view-profile-demo/src/UIHelpers.as
~/src/openplanet/my-plugins/tm-map-info/src/AnimMgr.as
~/src/openplanet/my-plugins/tm-editor-plus-plus/src/nvg/NvgHelpers.as
```

---

*End of research asset for [Curate the theme-respecting three-tier visual design skill](https://github.com/XertroV/tm-plugin-skills/issues/3).*
