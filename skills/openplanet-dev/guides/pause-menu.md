# Pause menu

## Is the pause menu open?

```angelscript
bool IsPauseMenuOpen() {
    auto net = GetApp().Network;
    if (net is null || net.PlaygroundClientScriptAPI is null) return false;
    return net.PlaygroundClientScriptAPI.IsInGameMenuDisplayed;
}
```

That flag is the in-game/pause menu. It does not tell you which submenu is
showing.

## Submenus and extra frames

The title also stacks `app.ActiveMenus`. The last entry’s `CurrentFrame` is
the top overlay (settings, confirm-quit, …):

```angelscript
string TopMenuFrameId() {
    auto app = cast<CTrackMania>(GetApp());
    if (app.ActiveMenus.Length == 0) return "";
    auto frame = app.ActiveMenus[app.ActiveMenus.Length - 1].CurrentFrame;
    return frame is null ? "" : string(frame.IdName);
}
```

Example: `DialogConfirmClose` is the “quit Trackmania?” dialog. Treat
`ActiveMenus` as “something modal is up” even when
`IsInGameMenuDisplayed` is false.

## Return to menu safely

```angelscript
void ReturnToMenu() {
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
}
```

- `Quit` — leave the playground.
- `Resume` — close pause and stay in the map.

Call from a coroutine. `BackToMainMenu` from `Render` can crash if ghosts are
paused. Full leave/play sequence: [exit-a-map.md](exit-a-map.md),
[play-a-map.md](play-a-map.md).

## Sources

- `IsInGameMenuDisplayed` — [tm-ghosts-plus-plus](https://github.com/XertroV/tm-ghosts-plus-plus) `src/Scrubber.as` (`IsPauseMenuOpen`)
- `ActiveMenus` / `DialogConfirmClose` — same plugin, `Scrubber.as` `Update`
- Close + `BackToMainMenu` — [tm-archivist](https://github.com/XertroV/tm-archivist) `src/Maps.as`
