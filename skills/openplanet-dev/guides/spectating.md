# Spectating a player

Two different jobs: spectate a **live server player**, or spectate a
**ghost** in solo. Check which playground you are in first
([game-state.md](game-state.md)).

## Live player (server)

Needs `Network.PlaygroundClientScriptAPI` and a login.

```angelscript
void SpectateLogin(const string &in login) {
    auto net = GetApp().Network;
    auto api = net.PlaygroundClientScriptAPI;
    auto client = net.ClientManiaAppPlayground;
    if (api is null || client is null) return;
    if (!api.IsSpectator) api.RequestSpectatorClient(true);
    api.SetSpectateTarget(login);
    client.ClientUI.Spectator_SetForcedTarget_Clear();
    api.SetWantedSpectatorCameraType(CGamePlaygroundClientScriptAPI::ESpectatorCameraType::Follow);
}

void StopSpectating() {
    auto api = GetApp().Network.PlaygroundClientScriptAPI;
    if (api is null || !api.IsSpectator) return;
    api.RequestSpectatorClient(false);
}

bool IsSpectator() {
    return GetApp().Network.Spectator;
}
```

`SetSpectateTarget` takes the player **login**, not display name. Clear the
forced UI target so the wanted camera type applies.

## Ghost (solo / records)

ML custom events, usually via MLHook:

```angelscript
MLHook::Queue_PG_SendCustomEvent("TMGame_Record_Spectate", {wsid}); // empty wsid = stop
MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {wsid});
```

`PlaygroundScript.UIManager.UIAll.ForceSpectator` is true while spectating a
ghost. `SpectatorForceCameraType` forces cam 1/2/3 while in that mode.

## Who am I looking at?

`VehicleState::GetViewingPlayer()` is the viewed `CSmPlayer` (local or
spectated). Compare its score/login to the local player to see if you are
driving.

## Sources

- `SetSpectateTarget` / `RequestSpectatorClient` — [tm-magic-spectator](https://github.com/XertroV/tm-magic-spectator) `src/MagicSpectate.as` (`Spectate` namespace)
- Ghost spectate events — [tm-ghosts-plus-plus](https://github.com/XertroV/tm-ghosts-plus-plus) `src/Main.as` (`TMGame_Record_Spectate`)
