# Game and profile settings

Three layers: your plugin’s `[Setting]`s, the user’s `CGameUserProfile` /
wrapper, and a few hidden camera fields on the game terminal.

## Plugin settings

```angelscript
[Setting category="General" name="Enabled"]
bool S_Enabled = true;
```

Openplanet persists these. `OnSettingsChanged()` runs after the user edits
the settings panel. Hidden keys (`[Setting hidden]`) store state without a
row in the UI.

## User profile (script surface)

When you have a `CGameUserProfileWrapper@` (often
`ManiaPlanetScriptAPI.UserMgr.Users[0].Config` — try that before offsets):

```angelscript
auto wrap = cast<CGameManiaPlanet>(GetApp()).ManiaPlanetScriptAPI.UserMgr.Users[0].Config;
wrap.Online_DefaultOpponentVisibility = CGameUserProfileWrapper::EPlayerVisibility::Opaque;
```

Opponent visibility, similar online defaults, and other wrapper fields are
the supported profile knobs. Copy out values you need; do not assume the
handle survives a yield without re-getting it.

Some plugins reach a “special” profile via `Dev::` offsets from `RootMap`
for ghost visibility / name tags when the script property is missing. Those
offsets move between game builds — see
[dev-offset-version-gates.md](dev-offset-version-gates.md).

## Hidden camera type

The active cam is not a `[Setting]`. On the first game terminal:

```angelscript
CGameTerminal@ Term() {
    auto pg = GetApp().CurrentPlayground;
    if (pg is null || pg.GameTerminals.Length == 0) return null;
    return pg.GameTerminals[0];
}

// read (offsets observed on TMNEXT; re-check after a game update)
uint CurrCam() {
    auto gt = Term();
    return gt is null ? 0 : Dev::GetOffsetUint32(gt, 0x34);
}

void SetCam(uint cam) {
    auto gt = Term();
    if (gt is null) return;
    auto nod = Dev::GetOffsetNod(gt, 0x50);
    Dev::SetOffset(nod, 0x4, cam);
}
```

Observed `cam` values include `0x12` Cam1, `0x13` Cam2, `0x14` Cam3,
`0x15` backwards, `0x2` / `0x11` freecam. Alt-cam and “can drive freecam”
are neighboring uints on the same terminal. Do not write `0x8`, `0x9`, or
`>= 0x1e` — those have crashed.

For projection / current render camera (not the gameplay cam preset), use
the bundled `Camera` plugin — see
[common-dependencies](../references/common-dependencies.md).

## Sources

- Profile wrapper `Online_DefaultOpponentVisibility` — [tm-autohide-opponents](https://github.com/XertroV/tm-autohide-opponents) `src/Impl.as`
- Terminal cam offsets — [tm-camera-randomizer](https://github.com/XertroV/tm-camera-randomizer) `src/Camera.as`
