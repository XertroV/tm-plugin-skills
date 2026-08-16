# Openplanet API JSON type dumps

Openplanet continuously exports machine-readable AngelScript type information to
two JSON files in its install directory (e.g. `~/OpenplanetNext/`). They are the
authoritative source for what the AngelScript API exposes — both Openplanet's own
scripting API and the game classes it reflects into scripts. Read these instead of
guessing signatures, member offsets, or whether a class/method exists.

| File | Top-level keys | What it covers |
|------|----------------|----------------|
| `OpenplanetCore.json` | `op`, `functions`, `classes`, `enums`, `funcdefs`, `props` | **Openplanet's scripting API** — global/namespace functions, script classes, enums, funcdefs, and exposed constants/props (the `UI::`, `Math::`, `Time::`, `Json::`, `Net::`, … surface). |
| `OpenplanetNext.json` | `mp`, `op`, `ns` | **Game classes reflected into AngelScript** — 20 namespaces (`Game`, `TrackMania`, `Scene`, `Hms`, `Control`, `Plug`, …) of engine types with their members and offsets. `mp` is the game build, `op` the Openplanet version. |

The Turbo / MP4 variants have their own dumps (`OpenplanetTurbo.json`,
`Openplanet4.json`) with the same `ns` shape as `OpenplanetNext.json`.

## `OpenplanetNext.json` (game classes) — compact encoding

`ns` maps namespace → class name → class descriptor. Field names are single-letter
to keep the (multi-MB) file small:

```jsonc
{
  "mp": "2026-02-03 03:51:19",   // game build timestamp
  "op": "1.29.5",                 // Openplanet version
  "ns": {
    "Hms": {
      "CHmsPortal": {
        "p": "CMwNod",            // base class name
        "c": 1,                   // instantiable (1) or abstract/nod-only (0)
        "i": 6006000,             // class ID (engine type id)
        "sz": 312,                // OPTIONAL struct size in bytes (see "size field" below)
        "m": [                    // members
          { "o": 48, "t": "bool", "i": 0, "n": "IsActive" },
          { "t": "float", "i": 8, "n": "PeriodSmoothing", "r": [0, 1] }
          // o = member offset in bytes (present on plain fields; absent on
          //   methods/accessors), t = AngelScript type, i = member index,
          //   n = member name. Optional member fields: r = clamp/valid range,
          //   a = accessor flag, c = const flag, e = enum backing, m = method.
        ],
        "e": [],                  // nested enums (optional)
        "d": "...",               // doc string (optional)
        "f": "..."                // file-extension hint (optional)
      }
    }
  }
}
```

## `OpenplanetCore.json` (scripting API) — verbose encoding

Long-form, with full type declarations and doc strings:

- `functions[]`: `{ns, name, returntypeid, returntypename, returntypedecl, args:[{typename, typedecl, name}], desc, flags, …}` — global + namespace functions.
- `classes[]`: `{id, name, behaviors, methods, desc, …}` — script-visible classes (handles, value types).
- `enums[]`: `{ns, id, name, group, desc, values:{Name:{v}}}` — enum types and their values.
- `funcdefs[]`: callback signatures (e.g. `less_nonconst` used by `SortNonConst`).
- `props[]`: exposed constants, e.g. `{ns:"Math", name:"PI", typedecl:"float"}`.

## The `sz` (size) field is NOT always present

The `sz` member-size field on game classes is an **extra that `op-tm-api-docs`
adds to its customized copies** (`*_with_offsets.json`). The live
`~/OpenplanetNext/OpenplanetNext.json` does **not** currently include it. Any
tooling must treat `sz` as optional (`cls.get("sz")` → `None`/`-1` when absent)
rather than assuming it exists.

## Tooling

- `scripts/op-api.py` — search both dumps for classes, members, functions, enums,
  and constants. See `scripts/op-api.py --help`.
- `scripts/op-api-diff.py` — diff two game-class dumps to see what changed between
  Openplanet/game builds (added/removed/changed classes and members). Adapted from
  `op-tm-api-docs/diff-json.py`.

Both auto-detect the live dumps under `~/OpenplanetNext/` and accept explicit
paths (e.g. an `op-tm-api-docs/op-*.json` snapshot for a specific version).

## Reference implementation

`../openplanet/my-plugins/op-tm-api-docs/` is the full browser UI over these files
(Vue 3 + Vite). Its `src/opJson.ts` builds the search indexes (class registry,
member→class lookup, enum→class, return-type→usage) and is the reference for how
to parse and cross-link the `ns` encoding. It consumes customized copies with the
extra `sz` size field (see above) and ships per-version snapshots (`op-*.json`)
plus a `diff-json.py` for build-to-build comparison.

## Related

- `docs/openplanet-deprecations.md` — when a class/member disappears from a newer
  dump, log the `Old` → `New` mapping there.
- `docs/openplanet-gotchas.md` — experienced defaults that these dumps confirm.
