# Exit a map

Use this to leave a playground (or editor session) and get back to a title
control that can `PlayMap` / join again.

## Sequence

1. If the in-game/pause menu is up, close it with **Quit**.
2. Call `BackToMainMenu()`.
3. Yield until `ManiaTitleControlScriptAPI.IsReady`.

```angelscript
void ReturnToMenu(bool yieldTillReady = true) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    if (app.Network !is null
        && app.Network.PlaygroundClientScriptAPI !is null
        && app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed
        && app.Network.PlaygroundInterfaceScriptHandler !is null) {
        app.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(
            CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit);
    }
    app.BackToMainMenu();
    while (yieldTillReady && !app.ManiaTitleControlScriptAPI.IsReady) yield();
}
```

`EInGameMenuResult::Quit` leaves the map. `Resume` only closes the pause menu.

## Call site

Run this from a coroutine. `BackToMainMenu` during `Render` can crash if ghosts
are paused (game applies the leave on the main loop). If you must detect a
leave from a render path, queue `startnew(ReturnToMenu)`.

Before `PlayMap` / `EditMap` / join, also wait until the menu module is on the
switcher — see [play-a-map.md](play-a-map.md).

In-map check used with this flow:

```angelscript
bool CurrentlyInMap() {
    return GetApp().RootMap !is null && GetApp().CurrentPlayground !is null;
}
```

Title control also has `Quit()` (leave the title). That is not “back to menu.”

See [pause-menu.md](pause-menu.md) for detecting pause and extra menu frames.

## Sources

- `ReturnToMenu` + `CloseInGameMenu(Quit)` — [tm-archivist](https://github.com/XertroV/tm-archivist) `src/Maps.as`; [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Maps.as`
- `BackToMainMenu` during render / paused ghosts — [tm-ghosts-plus-plus](https://github.com/XertroV/tm-ghosts-plus-plus) `src/Main.as`
