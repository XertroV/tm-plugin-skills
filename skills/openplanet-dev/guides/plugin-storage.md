# Plugin storage and paths

Openplanet gives three roots. Prefer **plugin storage** for your own files.

| Helper | Where |
| --- | --- |
| `IO::FromStorageFolder(rel)` | This plugin’s private storage (survives reload) |
| `IO::FromUserGameFolder(rel)` | User `Documents/Trackmania/…` (Maps, Replays, Scripts) |
| `IO::FromDataFolder(rel)` | Openplanet data folder (`~/OpenplanetNext/` or `%USERPROFILE%\OpenplanetNext\`) |

```angelscript
const string CachePath = IO::FromStorageFolder("cache.json");

void SaveJson(const string &in json) {
    IO::File f(CachePath, IO::FileMode::Write);
    f.Write(json);
    f.Close();
}

string LoadJson() {
    if (!IO::FileExists(CachePath)) return "{}";
    IO::File f(CachePath, IO::FileMode::Read);
    string s = f.ReadToEnd();
    f.Close();
    return s;
}

void EnsureImgDir() {
    string dir = IO::FromStorageFolder("img");
    if (!IO::FolderExists(dir)) IO::CreateFolder(dir, true);
}
```

The Openplanet log lives in the data folder:
`IO::FromDataFolder("Openplanet.log")` is `~/OpenplanetNext/Openplanet.log` or
`%USERPROFILE%\OpenplanetNext\Openplanet.log`. The previous session is
`Openplanet-Old.log`.

`IO::FileMode::Write` truncates. `Read` / `ReadToEnd` / `Write(MemoryBuffer@)`
cover text and binary. `IndexFolder(path, recursive)` lists names.

User-game examples:

```angelscript
IO::FromUserGameFolder("Maps/SkinUrlDemo3.Map.Gbx");
IO::FromUserGameFolder("Replays/Autosaves");
IO::FromUserGameFolder("Scripts/Modes/MyMode.Script.txt");
```

Packaged plugin files (`img/icon.png` next to scripts) are **not** storage —
load them with a relative path (`UI::LoadTexture("img/icon.png")`).

Do not write secrets into storage, `info.toml`, or logs. Machine-local
ports/paths for agents stay in clone-local excluded state, not here.

## Sources

- `IO::FromStorageFolder` — [tm-better-totd](https://github.com/XertroV/tm-better-totd) `src/TOTDs.as`; [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Main.as` (`MapLogFilePath`)
- `IO::FromUserGameFolder` — [tm-play-map](https://github.com/XertroV/tm-play-map) `CustomModePath`; [tm-http-server](https://github.com/XertroV/tm-http-server) Replays paths
