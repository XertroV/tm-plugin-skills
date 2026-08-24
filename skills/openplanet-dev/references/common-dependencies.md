# Common Openplanet dependencies

Usually depend on a listed library when it covers the job. The user can
overrule. Read the live `Export.as` / README for signatures; this page is a
routing catalog.

| Need | Depend on | Module |
| --- | --- | --- |
| Vehicle vis, RPM, wheels, turbo, viewed car | `VehicleState` | `VehicleState` |
| Project world ↔ screen, current camera, editor orbital | `Camera` | `Camera` |
| Colored ImGui tags / frames | `Controls` | `Controls` |
| Nadeo Live/Meet/Core HTTP, login ↔ account ID | `NadeoServices` | `NadeoServices` |
| Race/KO/MM/ghost/player/CP/respawn feeds | `MLFeedRaceData` | `MLFeed` |
| Inject ML, ML events, code during manialink exec | `MLHook` | `MLHook` |
| Advanced map/item editor callbacks and helpers | `Editor` | `Editor` |
| Character vis by entity ID | `tm-char-vis` | `CharVis` |
| Player vis → vehicle/char IDs, `CSmPlayer` | `tm-sm-player-vis` | `SmPlayerVis` |
| Club room administration, join links, mode settings, map precache | `BetterRoomManager` | `BRM` |

Plugin ID (`info.toml` / `.op` / `DEPENDENCY_*`) is not the display name and
is not always the module (`import … from "Module"`).

## Declaring

```toml
[script]
dependencies = ["VehicleState"]
optional_dependencies = ["tm-sm-player-vis"]
```

- **Required** (`dependencies`): plugin must be installed or this plugin will
  not load.
- **Optional**: plugin still loads when the peer is missing. Openplanet defines
  `DEPENDENCY_<ID>` (ID uppercased, non-alphanumerics → `_`) only when that
  peer was present at compile. Keep every use of that module inside
  `#if DEPENDENCY_<ID>`.
- **`export_dependencies`:** a library that exposes another plugin's types
  lists that plugin here so *its* dependents inherit those exports. Consumers
  list the leaf library only. `MLFeedRaceData` already re-exports `MLHook`.
- Bundled `essential` libraries (`VehicleState`, `Camera`, `Controls`,
  `NadeoServices`) ship with Openplanet. Still declare them.

`Meta::GetPluginFromID(id)` + `.Enabled` is for **live process**: hooks,
injected ML, updating feeds, registered editor callbacks, cached club/room
state, running coroutines. Thin accessors that only read the current scene
can be tried without that check. If calls are unbound or data is stale,
enable the plugin (Openplanet UI, or `ControlPlugin` `action=enable` when a
control bridge is available).

On unload, pair every hook/ML injection with teardown (`OnDisabled` /
`OnDestroyed`). Reload the exporter before dependents.

## Bundled with Openplanet

Source: game install `Openplanet/Plugins/<Id>/Export.as`.

### VehicleState

Use when you need the viewed or any car's vis/state: position/dir, RPM,
wheels, turbo, vehicle type, or a `CSmPlayer` → vis lookup.

- `ViewingPlayerState()` — viewed car; can be valid when `GetViewingPlayer()`
  is null (editor test).
- `GetVis(scene, player)` — player → `CSceneVehicleVis@`.
- `GetVisFromId` / `GetSingularVis` / `GetAllVis`.
- `GetRPM`, `GetSideSpeed`, `GetWheelDirt`, `GetLastTurboLevel`,
  `GetVehicleType`, `GetCruiseDisplaySpeed`.

Entity ID is `Dev::GetOffsetUint32(vis, 0)` on the **vis**, not
`AsyncState`. `CSceneVehicleVis@` vs `CSceneVehicleVisState@`
(`vis.AsyncState`). `GetSideSpeed` is school-gated (`#if SIG_SCHOOL`).

### Camera

Use when drawing in world space, picking on screen, or driving the editor
orbital camera.

- `ToScreen` / `ToScreenSpace` / `IsBehind` — behind the camera when
  `ToScreen(pos).z > 0`.
- `GetCurrent` / `GetCurrentPosition` / `GetProjectionMatrix` — last
  `RenderEarly` cache. Prefer these over `FindCurrent()` (live walk).
- `SetEditorOrbitalTarget(pos)` — editor orbital only.

### Controls

Use when you want the stock colored tag/frame widgets (status chips, labeled
groups) instead of hand-rolled draw-list chrome.

- `Tag` / `TagPrimary` / `TagInfo` / `TagSuccess` / `TagWarning` / `TagDanger`
- `BeginFrame*` / `EndFrame` / `Frame*`
- `DrawTag` for explicit placement

### NadeoServices

Use for authenticated Nadeo HTTP and ID conversion. Yield while waiting.

```angelscript
NadeoServices::AddAudience("NadeoLiveServices");
while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
auto req = NadeoServices::Get("NadeoLiveServices", url);
req.Start();
while (!req.Finished()) yield();
```

- Audiences: `NadeoServices`, `NadeoLiveServices` (and Meet via Live).
- `BaseURLCore` / `BaseURLLive` / `BaseURLMeet`
- `Get` / `Post` / `Put` / `Patch` / `Delete` / `Request` — throw if that
  audience is not authenticated yet.
- `GetAccountID`, `LoginToAccountId`, `AccountIdToLogin`
- `GetDisplayNameAsync` / `GetDisplayNamesAsync` — yieldable

## Manialink and race data

### MLFeedRaceData

Use for scores, sorted players, checkpoints, respawns, KO/COTD, teams/MM,
and loaded ghosts. Depend on **`MLFeedRaceData` only** — it requires and
re-exports `MLHook`. Call `MLHook::` yourself only when you are injecting ML
or handling events the feed does not cover.

Needs the plugin **enabled** so feeds stay current.

```toml
dependencies = ["MLFeedRaceData"]
```

- `MLFeed::GetRaceData_V4()` — players, CPs, spawn, respawns, ranks
- `GetKoData()` — COTD/KO alive/DNF, rounds, KO count
- `GetTeamsMMData_V1()` — clan scores, MVP, points limit, warmup, finish order
- `GetGhostData()` — loaded ghosts and their CP times
- `MLFeed::LocalPlayersName`; `raceData.GetPlayer_V4(name)`
- Sorted lists: `SortedPlayers_TimeAttack`, `SortedPlayers_Race`,
  `SortedPlayers_Race_Respawns`

Per player (V4): `CpCount`, `LastCpTime`, `CpTimes`, `BestTime`,
`BestRaceTimes`, `SpawnStatus`, `NbRespawnsRequested`,
`TimeLostToRespawnByCp`, `CurrentLap`, `RoundPoints`, `Points`, `TeamNum`,
`IsMVP`, `WebServicesUserId`, `Login`.

Live docs: plugin README / `MLFeed_Export.as` + `MLFeed_ExportShared.as`.

### MLHook

Use when you need the **manialink execution context** (different from normal
Openplanet callbacks): inject a page, queue playground/menu/editor custom
events, or receive ML events. For race/mode/player data, use MLFeed first.

Needs the plugin **enabled**. Unregister hooks and remove injected pages on
unload (`MLHook::UnregisterMLHooksAndRemoveInjectedML()`).

- `InjectManialinkToPlayground` / `Menu` / `Editor` (+ matching `Remove*`)
- `Queue_SH_SendCustomEvent`, `Queue_PG_SendCustomEvent`,
  `Queue_Menu_SendCustomEvent`, `Queue_Editor_SendCustomEvent`
- `Queue_MessageManialinkPlayground` / `Menu` / `Editor` (and `*Server`)
- `RegisterMLHook(HookMLEventsByType@, type)` /
  `UnregisterMLHookFromAll`
- `RegisterPlaygroundMLExecutionPointCallback` — run at ML exec
- `ToMLScript` — wrap ManiaScript as an ML page

Encode injected script as a string in the plugin. Live surface:
`Exports/MLHook_Export.as`.

## Editor++

Plugin ID **`Editor`**, module **`Editor`**. Use for map/item editor work
beyond stock Openplanet: placement/cursor, inventory, item editor,
macroblocks, and editor-lifetime callbacks.

Needs the plugin **enabled** for callbacks and most helpers.

```toml
dependencies = ["Editor"]
# or optional_dependencies = ["Editor"]  +  #if DEPENDENCY_EDITOR
```

- `Editor::Callbacks::Exts::RegisterExtension(IEppExtension@)` — set the
  funcdefs you need (`onPlaceItem`, `onDeleteItem`, `onPlaceBlock`,
  `onDeleteBlock`, `onEditorLoad` / `Unload`, playground enter/leave,
  cursor updates, selection). Call `extension.kill()` from `OnDestroyed`.
- Placement/cursor: `SetAllCursorPos`, `SetPlacementMode` / `SetEditMode`,
  `IsIn*PlacementMode`, selected block/item/macroblock info
- `OpenItemEditor`, `SetEditorPickedNod` / `SetSelectedBlockInfo`
- Macroblock place/delete exports on the same module

Read `info.toml` `exports` / `shared_exports` and those files — the public
surface is only what is listed there.

## Character and player vis

Plugin IDs are the folder / `.op` names, not the display names.

### CharVis — `tm-char-vis` / `CharVis`

Use to walk `NSceneCharVis` and resolve a character vis by entity ID.

```toml
optional_dependencies = ["tm-char-vis"]
```

`#if DEPENDENCY_CHARVIS`: `CharVis::GetMgr(scene)`,
`GetCharVisByEntId(mgr, entId)`, `GetEntID` / `GetVisModel` / `GetAnimLink`.
`CharVis::Wrapper` is compiled into the dependent; do not pass it back.

### SmPlayerVis — `tm-sm-player-vis` / `SmPlayerVis`

Use to go from a player vis object to **vehicle entity ID**, char-vis IDs,
`CTrackManiaPlayerInfo`, and `CSmPlayer`. That vehicle-ID link is the usual
way to join a player to `VehicleState` vis.

```toml
optional_dependencies = ["tm-sm-player-vis"]
```

`#if DEPENDENCY_SMPLAYERVIS`: `SmPlayerVis::GetMgr(scene)`,
`GetPlayer(mgr, i)`, `GetVehicleVisEntId` / `GetVehicleVis`,
`GetCharVisEntId`, `GetPlayerInfo`, `GetSmPlayer`. Missing IDs are `0` or
`SmPlayerVis::NO_ENT_ID` (`0x0ff00000`); use `HasEntId`.

## BetterRoomManager

Plugin ID **`BetterRoomManager`**, module **`BRM`**. Use for club-room
admin: current server club/room IDs, join, mode/settings, map lists, and
precache.

Needs the plugin **enabled** for cached club/room state. Several calls
**yield**.

```toml
dependencies = ["BetterRoomManager"]
```

- `BRM::GetCurrentServerInfo(app, waitForClubId)` / `IsInAServer` / `JoinServer`
- `CreateRoomBuilder(clubId, roomId)` — `IRoomSettingsBuilder`: load/save
  settings, `SetMode` / `SetModeSetting`, `SetMaps` / `AddMaps`
- `GetMyClubs()`, `GetRoomInfoFromAPI`
- `PreCacheMap` / `PreCacheMapByUid_Async` / `PreCacheAsset`
- `BRM::GameMode` + `GameModeFromStr` / `GameModeToFullModeString`

Live surface: `BRM_Exports/Exports.as` + `Shared.as`.
