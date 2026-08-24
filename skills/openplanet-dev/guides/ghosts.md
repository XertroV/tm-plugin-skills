# Ghosts

Load, show, hide, and save ghosts from `PlaygroundScript` in **solo**
(`PlaygroundScript !is null`). Club access is required for local replays.

```angelscript
if (!Permissions::CreateLocalReplay()
    || !Permissions::PlayAgainstReplay()
    || !Permissions::PlayRecords()) {
    // idle — saving/playing ghosts will fail
}
```

## Load and add

```angelscript
void AddGhostFromUrl(const string &in filename, const string &in url) {
    auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
    if (ps is null) return;
    auto task = ps.DataFileMgr.Ghost_Download(filename, url);
    while (task.IsProcessing) yield(); // then TaskResult_Release later
    if (task.HasFailed || !task.HasSucceeded) {
        warn(task.ErrorDescription);
        return;
    }
    MwId inst = ps.GhostMgr.Ghost_Add(task.Ghost, true); // layer = true
    // keep inst.Value if you will remove this ghost later
}

void AddGhostsFromReplay(const string &in path) {
    auto ps = cast<CSmArenaRulesMode>(GetApp().PlaygroundScript);
    auto task = ps.DataFileMgr.Replay_Load(path);
    while (task.IsProcessing) yield();
    if (task.HasFailed || !task.HasSucceeded) return;
    for (uint i = 0; i < task.Ghosts.Length; i++) {
        ps.GhostMgr.Ghost_Add(task.Ghosts[i], true);
    }
}
```

`Ghost_AddWaypointSynced` adds a CP-synced twin. Clear Nadeo tasks after use
(`WaitAndClearTaskLater` / `dfm` owner).

## Unload

```angelscript
ps.GhostMgr.Ghost_Remove(instId);
ps.GhostMgr.Ghost_RemoveAll();
```

## Save

```angelscript
string rel = "AutosavedGhosts/" + mapName + "/" + nick + "-" + time + "ms.Replay.gbx";
ps.DataFileMgr.Replay_Save(rel, GetApp().RootMap, ghost);
```

`Replay_Save` paths are under the user’s **Replays** folder
(`IO::FromUserGameFolder("Replays")`).

## Where ghosts live

| Kind | Where |
| --- | --- |
| Saved replay / extracted ghost | `Documents/Trackmania/Replays/…` (and subfolders you pass to `Replay_Save`) |
| Game autosave PB | `Replays/Autosaves/<login>_<map>_PersonalBest_<mode>.Replay.Gbx` |
| Validation (editor test) | `PlaygroundScript.DataFileMgr.Ghosts` while still in the editor playground |
| Currently playing ghosts | `GhostMgr` instances (added with `Ghost_Add`) |
| Feed of loaded ghosts | `MLFeed::GetGhostData()` when MLFeed is enabled |

Editor validation ghosts appear on `DataFileMgr.Ghosts` as new entries; race
PB ghosts used by the mode are a different list than `GhostMgr` instances.

Do not call `BackToMainMenu` from `Render` while ghosts are paused — see
[exit-a-map.md](exit-a-map.md).

## Sources

- `Ghost_Download` / `Replay_Load` / `Ghost_Add` — [tm-ghosts-plus-plus](https://github.com/XertroV/tm-ghosts-plus-plus) `src/API/Core.as`
- `Replay_Save` + Replays path — [tm-autosave-ghosts](https://github.com/XertroV/tm-autosave-ghosts) `src/Main.as`
- Loaded-ghost feed — [tm-mlfeed-race-data](https://github.com/XertroV/tm-mlfeed-race-data) `MLFeed::GetGhostData`
