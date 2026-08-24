# Join a server

Use this to put the local client on a club room or other join-link server.

## Prefer BetterRoomManager

Plugin ID `BetterRoomManager`, module `BRM`. Needs the plugin enabled.

```toml
dependencies = ["BetterRoomManager"]
```

```angelscript
if (!Permissions::PlayPublicClubRoom()) {
    UI::ShowNotification("Need club-room play permission");
    return;
}
BRM::JoinServer(clubId, roomId, password); // password optional
```

`JoinServer` waits until the room's join-link is ready (room not still
`starting`), appends `:<password>` when given, returns to the menu, then opens
the link. It can throw if no server is up after ~20s.

Current server: `BRM::IsInAServer(app)` and
`BRM::GetCurrentServerInfo(app)` (yields while club/room IDs load).

## Manual join-link

Same permission. Get a `#join` / `#qjoin` URL from the Live club-room API
(`joinLink`), then:

```angelscript
void JoinFromLink(const string &in joinLink, const string &in password = "") {
    if (!Permissions::PlayPublicClubRoom()) return;
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

    string link = joinLink.Replace("#join", "#qjoin");
    if (password.Length > 0) link += ":" + password;
    app.ManiaPlanetScriptAPI.OpenLink(link, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
}
```

`#qjoin` queues the join through the menu. Call this from a coroutine, not
`Render`. See [exit-a-map.md](exit-a-map.md) for the pause-menu / `IsReady`
sequence.

## Sources

- `BRM::JoinServer` — [tm-better-room-manager](https://github.com/XertroV/tm-better-room-manager) `src/BRM_Exports/Impl.as`
- Return-to-menu + `OpenLink` — [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Maps.as`; [tm-archivist](https://github.com/XertroV/tm-archivist) `src/Maps.as`
