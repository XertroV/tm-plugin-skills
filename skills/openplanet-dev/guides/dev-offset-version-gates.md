# Version-gating `Dev::` offsets

Offset reads/writes (`Dev::GetOffset*`, `SetOffset`) are bound to a game
build. Gate them on `SystemPlatform.ExeVersion` before the first poke.

```angelscript
bool GameVersionSafe = false;

const string[] KnownSafeVersions = {
    "2024-06-28_13_46",
    "2024-06-20_19_53",
    // add the ExeVersion you actually tested
};

void Main() {
    startnew(CheckGameVersion);
}

void CheckGameVersion() {
    string ver = GetApp().SystemPlatform.ExeVersion;
    GameVersionSafe = KnownSafeVersions.Find(ver) >= 0;
    if (!GameVersionSafe) {
        warn("Untested game version " + ver + "; offset features disabled");
    }
}

CGameUserProfile@ TryProfile() {
    if (!GameVersionSafe) return null;
    // Dev:: chain only after the gate
    return GetSpecialUserProfile(GetApp());
}
```

`Find` returns `-1` when missing — use `>= 0`, not `> -1` vs `0` mix-ups
(index `0` is a valid known version).

## Optional remote allow-list

Some plugins also GET
`https://openplanet.dev/plugin/<id>/config/version-compat` and treat a JSON
key `{ "<pluginVersion>": { "<ExeVersion>": … } }` as safe. Use that as an
*addition* to a local list, not the only gate, and fail closed on HTTP/JSON
errors.

## Override

A settings-tab “run anyway” button that sets `GameVersionSafe = true` is
fine for the author. Default remains off on unknown builds.

## Habit

- Record the `ExeVersion` you tested next to every new offset.
- One `GameVersionSafe` flag for the whole offset surface; call sites
  `return` / skip when false.
- Script properties (`CGameUserProfileWrapper.Online_DefaultOpponentVisibility`,
  bundled `Camera` / `VehicleState`) do not need this gate.

See [game-and-profile-settings.md](game-and-profile-settings.md) for the
profile/camera offsets this protects.

## Sources

- `ExeVersion` allow-list + Openplanet config + override tab — [tm-camera-toggle](https://github.com/XertroV/tm-camera-toggle) `src/GameVersionCompat.as`
