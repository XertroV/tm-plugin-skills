# Openplanet API deprecations and migrations

Concise running log of Openplanet API deprecations, removals, and breaking
changes, grouped by the version that introduced them. Format: one line per
entry — `Old` → `New` — plus a second line only when there is a subtlety worth
knowing. Add entries as they are learned (changelogs, DEPRECATED log lines,
compile errors); keep newest versions at the top.

**Changelog source of truth:** per-build changelogs live at
`https://openplanet.dev/download/version/<id>`. Build listings per game and
branch: `openplanet.dev/download/next` (Trackmania default), `/download/next/beta`,
`/download/next/edge` (also `mp4`, `turbo`, `v4` paths for other games). The
listing shows the ~5 most recent builds per branch; older build IDs are
sequential, so any version's changelog is reachable by probing
`/download/version/<id>` (IDs span all games/branches). News posts
(`openplanet.dev/news`) only cover selected releases.

Where a version number is unconfirmed, the entry records the evidence date
instead.

**Detecting changes mechanically:** the exported AngelScript type dumps
(`docs/openplanet-api-json.md`) are the ground truth for what a build exposes.
`scripts/op-api-diff.py OLD.json NEW.json` reports added/removed/changed classes
and members between two builds; `scripts/op-api.py` answers "does this
class/method/signature still exist" against the live dump. Use the diff to spot
a removal, then log the `Old` → `New` mapping here.

## 1.29.10 (2026-05, beta/edge)

- `string::Join` → `Text::Join`; `string::Repeat` → `Text::Repeat` (moved to
  the `Text` namespace).
- `Net::SecureSocket` → `Net::Socket` with `secure` set to true in `Connect()`.

## 1.29.0 (2026-01) — Draw namespace

- `Draw::GetWidth()` → `Display::GetWidth()`
- `Draw::GetHeight()` → `Display::GetHeight()`
- `Draw::MeasureString(...)` → `UI::MeasureString(...)`
  - Changelog: "Added new Display namespace (this deprecates the Draw
    namespace)"; the `Draw` namespace was later removed entirely — dips++
    migrated 2026-01 (commit "Remove deprecated Draw namespace"). Search
    corpus code for `Draw::` before copying an old example.

## 1.28.0 (2025-08) — dynamic fonts

- `UI::LoadFont(font, size, ranges, fallback...)` → `UI::LoadFont(font, size)`
  simpler overload (ranges/fallback parameters deprecated; a "legacy size"
  still acts as the fallback size for `UI::PushFont` without an explicit
  size).
- Prefer `UI::PushFont`/`UI::PushFontSize` over loading many sizes of one
  font; fonts resize dynamically, ranges no longer needed, fallbacks come from
  system fonts automatically. UI scaling is dynamic and limits are removed.
- New: `UI::LoadSystemFont("comic.ttf")` loads from `C:\Windows\Fonts`.
- Also fixed in this line: an Angelscript issue with shared namespaced classes
  across different plugin modules.

## 1.27.13 (2025-07, beta)

- `UI::LoadFont` ranges/fallback overload deprecated here in beta; shipped in
  1.28.0 (see above).

## 1.27.9 (2025-06, beta)

- `Meta::PluginCoroutine` → `awaitable@` (`startnew` now returns `awaitable@`;
  BRM migrated to `awaitable@[]`).
- `Meta::PluginCoroutine::WithRunContext` → `Meta::StartWithRunContext`.

## 1.27.7 (2025-05, beta)

- Script array initializers no longer allow trailing empty elements:
  `{1,2,3,}` is now 3 elements, not 4 — audit initializers relying on the
  trailing default slot.
- `Settings.ini` options renamed (potentially conflicting option names).

## 1.26.x (2024) — global text-function API

- Global `ColoredString(s)` → `Text::OpenplanetFormatCodes(s)` (BetterChat
  migration 2024-05, commit "Fixes for upcoming global function API
  deprecation"; global form is gone from the current API reference).
- Global `StripFormatCodes(s)` → `Text::StripFormatCodes(s)`.
  - Global free-function forms deprecated in favor of the `Text::` namespace;
    old chat/UI code almost always pairs the two — migrate both together.

## 1.24.0 (2022)

- Long game enum names simplified, no compatibility layer:
  `CSystemConfigDisplay::ECSystemConfigDisplay__EZClip::_ZClip_Disable` →
  `CSystemConfigDisplay::EZClip::_ZClip_Disable` (pattern: drop the
  `EC...__` duplication level). Breaking at compile time — fix on sight.
- Resources API deprecation lands with a compatibility layer (see below).

## 1.22.4 (2022)

- Empty ImGui IDs are invalid: `UI::Checkbox("", foo)` →
  `UI::Checkbox("##Foo", foo)` (empty label asserts in notifications/logs;
  search regex `UI::.*\(""`).
- `string::split()` now returns the trailing empty element (`"a;b;c;"` gives
  4 items, not 3) — audit code that worked around the old behavior.
- New: `optional_dependencies` + `DEPENDENCY_<PLUGIN_ID>` preprocessor define.

## 1.2x (2022) — Resources API

- `Resources::GetFont()` → `UI::LoadFont()` or `nvg::LoadFont()` (UI and
  NanoVG fonts are now separate types; pick per use).
- `Resources::GetTexture()` → `UI::LoadTexture()` or `nvg::LoadTexture()`.
- `Resources::GetAudioSample()` → `Audio::LoadSample()`.
  - Compatibility layer was temporary; any remaining `Resources::` usage is
    overdue for migration.

## Unversioned / ongoing (verify before relying)

- `UI::Font::Default26` / `UI::Font::Default20` etc. were *added* in 1.27.12,
  then became less necessary with 1.28.0 dynamic fonts — E++ replaced the
  constants with `UI::LoadFont(path, size)` in 2025-07. Not formally
  deprecated; treat as "prefer LoadFont for new code".
- `meta.perms` (`free`/`paid`/`full`) → deprecated; use the Permissions API.
- `NadeoServices::BaseURLCompetition()` / `NadeoServices::BaseURLClub()` →
  `NadeoServices::BaseURLMeet()` (observed 2024; also `NadeoClubServices`
  audience calls folded into `NadeoLiveServices` for those routes).
- Web API base URLs moved to the `api.openplanet.dev` subdomain
  (2026-05 server migration): `openplanet.dev/api/auth/validate` →
  `api.openplanet.dev/auth/validate`; plugin config endpoint moves to
  `api.openplanet.dev/plugin/<id>/config/<name>` (old URLs kept working "for a
  good while" — update opportunistically).
