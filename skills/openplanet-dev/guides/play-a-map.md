# Play a map

Use `CGameManiaTitleControlScriptAPI.PlayMap` to start a map from a URL, local
path, or resolved UID. This is the title-control call, not the Play Map plugin.

## Permission and ready

```angelscript
if (!Permissions::PlayLocalMap()) {
    UI::ShowNotification("Standard or Club access required to play a local map");
    return;
}
```

`PlayMap` only works when the title control is ready and the menu module is on
the switcher. Leave any current playground first (see
[exit-a-map.md](exit-a-map.md)).

```angelscript
void PlayMapNow(const string &in map, const string &in mode = "TrackMania/TM_PlayMap_Local", const string &in settingsXml = "") {
    if (!Permissions::PlayLocalMap()) return;
    auto app = cast<CGameManiaPlanet>(GetApp());
    if (app.Network !is null
        && app.Network.PlaygroundClientScriptAPI !is null
        && app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed
        && app.Network.PlaygroundInterfaceScriptHandler !is null) {
        app.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(
            CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit);
    }
    app.BackToMainMenu();
    while (!app.ManiaTitleControlScriptAPI.IsReady) yield();
    while (app.Switcher.ModuleStack.Length < 1
        || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null) yield();
    yield();
    app.ManiaTitleControlScriptAPI.PlayMap(map, mode, settingsXml);
}
```

Signature: `PlayMap(wstring Map, wstring Mode, string SettingsXml)`.

Returning to the menu first avoids a main-menu 3D-scene redraw bug that can
script-error into a recovery restart.

## Map argument

`Map` is a file URL or a path the title can load:

- HTTPS `.Map.Gbx` (TMX download, Nadeo `FileUrl`, …)
- Filename or relative path under the user’s **Maps** folder

Live-tested local form (control MCP `PlayMap`): `"SkinUrlDemo3.Map.Gbx"` —
that file lives at
`Documents/Trackmania/Maps/SkinUrlDemo3.Map.Gbx`. After load:
`curGameModeStr == TM_PlayMap_Local`, map name `SkinUrlDemo3`.

Same folder via helper:

```angelscript
string local = IO::FromUserGameFolder("Maps/SkinUrlDemo3.Map.Gbx");
// or a subfolder: IO::FromUserGameFolder("Maps/My Maps/Unnamed.Map.Gbx")
PlayMapNow(local);
```

UID → URL via `DataFileMgr.Map_NadeoServices_GetFromUid` (yield, then
`WaitAndClearTaskLater` — see [nadeo-tasks.md](nadeo-tasks.md)). Do not keep
the `CNadeoServicesMap@` handle.

## Mode

Common local modes:

- `TrackMania/TM_PlayMap_Local`
- `TrackMania/TM_Campaign_Local`
- `TrackMania/TM_Platform_Local`
- `TrackMania/TM_RoyalTimeAttack_Local`
- custom: `MyMode.Script.txt` under `Documents/Trackmania/Scripts/Modes/`

`SettingsXml` is the mode settings payload (empty is fine).

## PlayMapList

`PlayMapList(MwFastBuffer<wstring>& maps, mode, settingsXml)` starts several
maps. The **mode** must support a map list (campaign-style) or you will not
get Next / playlist UI. Prefer `PlayMap` unless you have a concrete reason
to use a list. Anything on `PlayMapList` needs a thorough live test of next
map, end of list, and leaving.

## EditMap

Same ready/menu wait as `PlayMap`. Permission:
`Permissions::OpenAdvancedMapEditor()`.

tm-play-map and the control bridge both call the 3-arg form:

```angelscript
app.ManiaTitleControlScriptAPI.EditMap(url, "", "");
// EditMap(wstring Map, wstring EditorPluginScript, string EditorPluginArgument)
```

`EditMap2`–`EditMap5` add decoration, mod, player model, and forced editor
plugins. Use those only when you need those arguments.

Call from `startnew`, never from `Render`.

## Sources

- `PlayMap` / `EditMap(url, "", "")` / menu wait — [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Maps.as`
- Pause close before leave — [tm-archivist](https://github.com/XertroV/tm-archivist) `src/Maps.as`
- Local basename `SkinUrlDemo3.Map.Gbx` live-tested via [tm-control-mcp](https://github.com/clankercode/tm-control-mcp) `PlayMap`
- Title API — [CGameManiaTitleControlScriptAPI.PlayMap](https://next.openplanet.dev/Game/CGameManiaTitleControlScriptAPI)
