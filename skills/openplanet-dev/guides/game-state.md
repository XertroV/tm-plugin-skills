# Game state

Use one monitor updated once per frame (typically `RenderEarly`) instead of
re-deriving menu / playground / editor / map identity at every call site.

## Module stack

`app.Switcher.ModuleStack` is the live UI/game module stack. Index `0` is the
base. `cast<CTrackManiaMenus>(stack[0])` is the main menu. Editor and
playground modules appear when those modes are active. Walk the stack when you
need to know *which* overlay is up, not only whether a playground exists.

## Cheap identity: `map.Id.Value`

`CGameCtnChallenge.Id.Value` is a `uint` MwId. Compare that, not the UID
string, to detect map changes:

```angelscript
uint currMapId;

void CheckMap(CGameCtnChallenge@ map) {
    if (map is null) {
        if (currMapId != 0) { currMapId = 0; /* left map */ }
        return;
    }
    if (map.Id.Value != currMapId) {
        currMapId = map.Id.Value;
        string uid = map.IdName; // only when it actually changed
        // new map
    }
}
```

`IdName` is the UID string. Reading it every frame is wasted work.

## Global monitor (TM_State pattern)

Bosslike’s `TM_State` is the reference. Snapshot once from `RenderEarly`:

```angelscript
namespace GameState {
    bool IsMapNull, WasMapNull, DidMapChange;
    bool IsInPlayground, IsInEditor, IsInSolo, IsInServer;
    uint CurrMapId;
    string CurrMapUid;
    int UiSeq, LastUiSeq;
    bool UiSeqChanged, InGameMenuDisplayed;

    void RenderEarly() {
        auto app = cast<CTrackMania>(GetApp());
        auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
        string login = si !is null ? string(si.ServerLogin) : "";

        WasMapNull = IsMapNull;
        IsMapNull = app.RootMap is null;
        IsInEditor = app.Editor !is null;
        IsInPlayground = app.CurrentPlayground !is null;
        IsInSolo = IsInPlayground && app.PlaygroundScript !is null && login.Length == 0;
        IsInServer = IsInPlayground && app.PlaygroundScript is null && login.Length > 0;

        DidMapChange = false;
        if (IsMapNull) {
            if (!WasMapNull) { CurrMapId = 0; CurrMapUid = ""; DidMapChange = true; }
        } else if (app.RootMap.Id.Value != CurrMapId) {
            CurrMapId = app.RootMap.Id.Value;
            CurrMapUid = app.RootMap.IdName;
            DidMapChange = true;
        }

        auto pg = cast<CSmArenaClient>(app.CurrentPlayground);
        LastUiSeq = UiSeq;
        if (pg is null || pg.GameTerminals.Length == 0) {
            UiSeq = 0;
        } else {
            UiSeq = int(pg.GameTerminals[0].UISequence_Current);
            auto api = app.Network.PlaygroundClientScriptAPI;
            InGameMenuDisplayed = api !is null && api.IsInGameMenuDisplayed;
        }
        UiSeqChanged = UiSeq != LastUiSeq;
    }

    bool InPlaying() { return UiSeq == int(SGamePlaygroundUIConfig::EUISequence::Playing); }
    bool InFinish()  { return UiSeq == int(SGamePlaygroundUIConfig::EUISequence::Finish); }
    bool InPodium()  { return UiSeq == int(SGamePlaygroundUIConfig::EUISequence::Podium); }
    bool InIntro()   { return UiSeq == int(SGamePlaygroundUIConfig::EUISequence::Intro); }
    bool InEndRound(){ return UiSeq == int(SGamePlaygroundUIConfig::EUISequence::EndRound); }
}
```

Solo vs server: playground script present + empty `ServerLogin` is local;
no playground script + a login is a dedicated server.

UI sequence also includes `UIInteraction` (end-of-round KO / TA menus).

Call sites then read `GameState::IsInPlayground` / `DidMapChange` / `InPlaying()`.
See [pause-menu.md](pause-menu.md) for the pause flag.

## Sources

- Monitor + `map.Id.Value` + UI sequence — [tm-bosslike](https://github.com/XertroV/tm-bosslike) `src/TM_State.as`
