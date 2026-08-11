# Issue 6 — Capability ladder and dependency-aware lifecycle bridge

**Ticket:** [Specify the capability ladder and dependency-aware lifecycle bridge](https://github.com/XertroV/tm-plugin-skills/issues/6)
**Map:** [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1)
**Kind:** Wayfinder research (decision asset; not implementation)
**Date:** 2026-08-11
**Openplanet probed:** 1.29.5 (next, Public, `1234ad9e`) via live `OpenplanetNext` install
**Status:** Research complete — decisions below are ready for map resolution when the ticket is closed by a human/session that owns map updates

---

## 1. Decision summary

Version one of the skillpack shall treat runtime control as a **four-rung capability ladder**. Skills always preserve lower rungs as recovery paths; optional tools never become the only way to finish a lifecycle loop.

| Rung | Capability | Role in v1 |
|------|------------|------------|
| **L0** | Manual Openplanet UI + filesystem `Openplanet.log` | Portable default; always valid completion path when a human can operate the UI |
| **L1** | Minimal socket-only **lifecycle bridge** (new companion plugin) | Dependency-aware load/unload/reload with **prior dependent-closure memory** |
| **L2** | **RemoteBuild** (third-party plugin + CLI) | Simple single-plugin load/unload + external log tail when present |
| **L3** | **`tm-control-mcp`** (optional Control MCP) | Editor/game interaction, screenshots, state probes — **not** the lifecycle owner |

**Hard boundaries**

1. The minimal bridge is **lifecycle-only** (list/status/load/unload/reload + closure snapshot/restore). It must not grow into a general MCP/HTTP game-control surface.
2. Control MCP stays the interaction/screenshot rung. Upstream extensions may **delegate** lifecycle to L1 or expose thin read-only plugin inventory helpers; they must not re-implement a second general bridge.
3. RemoteBuild remains an **external** detected tool (store plugin + `tm-remote-build` CLI / XertroV fork). Skills may use it for simple reloads; they must not assume it restores dependents.
4. **Logs are primarily an external filesystem concern.** There is no first-class in-script streaming log API. Evidence gates read `Openplanet.log` (or RemoteBuild’s tail helper), not an invented in-game log RPC unless Control MCP later adds a thin path helper.

**Dependent-closure rule (normative for L1)**

Before mutating a target plugin that may unload dependents:

1. Snapshot the **currently loaded reverse-dependent closure** of the target (transitive; only plugins that are loaded now).
2. Perform unload/reload/load of the target (Openplanet itself cascades dependent unloads).
3. On **successful** target compilation/load, restore **only** that snapshot (topological load order), not every plugin that *could* depend on the target.
4. Remember the snapshot across **failed** attempts so a later successful compile still restores the same prior closure.
5. Never auto-enable unloaded-but-disabled plugins, optional deps that were not loaded, or “everything in `Plugins/` that lists this dependency.”

---

## 2. Evidence sources

| Source | Path / ref | Used for |
|--------|------------|----------|
| Live Openplanet install | `~/OpenplanetNext/` — version line in `Openplanet.log` | Runtime truth 1.29.5 |
| Live type DB | `~/OpenplanetNext/OpenplanetCore.json` | `Meta::ReloadPlugin`, `PluginIndex`, `Plugin` surface |
| Stale workspace type DB | `~/src/openplanet/my-plugins/tm-scripts/OpenplanetCore.json` | Drift warning (missing `ReloadPlugin`) |
| Docs archive | `~/.llm-general/website-archives/openplanet/root/docs/api/Meta*` | Documented lifecycle APIs |
| RemoteBuild (XertroV fork) | `~/src/tm-remote-build/` (= `my-plugins/tm-remote-build`) | Protocol, ports, log tail |
| Control MCP | `~/src/openplanet/my-plugins/tm-control-mcp/` | Framing, tools, screenshots |
| Agent workspace notes | `~/src/openplanet/README_FOR_AGENTS.md`, Hermes `openplanet-plugins` skill | Ladder sketch, reload reality |
| Live log cascade | `~/OpenplanetNext/Openplanet.log` @ 22:15:50 / 22:21:06 (2026-08-11) | Dependent unload + partial restore |
| E++ build script | `tm-editor-plus-plus/build.sh` | Hard-coded MCP reload only |
| Template / MCP build | `tm-openplanet-plugin-template/build.sh`, `tm-control-mcp/build.sh` | Detection patterns |

Recent openplanet.dev news checked (`news/2026/`) covers site API URL migration, not Meta lifecycle changes. Lifecycle conclusions are grounded in the live 1.29.5 type dump + docs archive + runtime log, not release-blog speculation.

---

## 3. Current Openplanet lifecycle APIs

### 3.1 Load / unload / reload

From live `OpenplanetCore.json` (1.29.5) and docs archive:

```text
Plugin@  Meta::LoadPlugin(const string&in path, PluginSource source, PluginType type)
void     Meta::UnloadPlugin(Plugin@ plugin)   // queued; handle invalid next frame
void     Meta::ReloadPlugin(Plugin@ plugin)   // queued; handle invalid next frame
Plugin@  Meta::GetPluginFromID(const string&in id)
Plugin@  Meta::GetPluginFromSiteID(int siteID)
Plugin@[]@ Meta::AllPlugins()
UnloadedPluginInfo[]@ Meta::UnloadedPlugins() // documented as possibly slow
Plugin@  Meta::ExecutingPlugin()
```

`PluginSource`: `Unknown`, `ApplicationFolder`, `UserFolder`
`PluginType`: `Unknown`, `Legacy`, `Folder`, `Zip`

**Semantics that matter for agents**

- `UnloadPlugin` / `ReloadPlugin` are **queued** and invalidate the `Plugin@` handle on the next frame. Bridges must `yield` and re-resolve by ID.
- `LoadPlugin` takes an **absolute path** plus source/type enums (RemoteBuild builds `IO::FromDataFolder("Plugins/") + id + "/"` for folders).
- `LoadPlugin` returning null is treated by RemoteBuild as failure (`"Plugin not loaded"`); compile diagnostics still appear in `Openplanet.log`.
- Setting `plugin.Enabled` exists (`set_Enabled`); prefer it over deprecated `Enable()` / `Disable()`.

### 3.2 Dependency graph APIs

`Meta::Plugin` exposes:

- `string[]@ Dependencies`
- `string[]@ OptionalDependencies`
- `string SourcePath`, `PluginSource Source`, `PluginType Type`, `string ID`, `string Version`, …

`Meta::PluginIndex` (live 1.29.5):

```text
PluginIndex@ PluginIndex()
void AddTree(Plugin@ plugin)
void Add(Plugin@ plugin)
void Remove(const string&in id)
void RemoveBlocked()
PluginIndexItem[]@ TopologicalSort()
```

Each `PluginIndexItem` carries `ID`, `Path`, `Type`, `Source` — enough to reload from disk after unload.

**Note:** Workspace copy `tm-scripts/OpenplanetCore.json` is **stale** (no `ReloadPlugin`; `PluginIndex` methods differ: `DependencySort` / `GetItem` / `GetCount`). Skills and bridges must prefer the game’s dumped JSON or docs archive over outdated vendor copies.

### 3.3 Cascade unload is engine behavior

Live log when RemoteBuild unloaded `Editor` (module id for Editor++):

```text
Unloading plugin 'Editor'
Unloading dependent plugin "tm-control-mcp" of "Editor"
Unloading plugin 'tm-control-mcp'
Unloading dependent plugin "mcp-tm" of "Editor"
Unloading plugin 'mcp-tm'
Unloading dependent plugin "tm-agent" of "mcp-tm"
Unloading plugin 'tm-agent'
```

Implications:

1. Callers do **not** need to manually unload direct dependents for correctness of unload — Openplanet walks the dependent graph.
2. Callers **do** need to remember who was loaded if they want the graph restored after reload.
3. Cascade is transitive (`tm-agent` via `mcp-tm`).
4. RemoteBuild / E++ `build.sh` only reloaded `tm-control-mcp` afterward — **`mcp-tm` and `tm-agent` were left unloaded**. This is the concrete hole L1 closes.

### 3.4 Log / evidence APIs

| Mechanism | Exists? | Notes |
|-----------|---------|-------|
| In-script structured log stream | **No** | Plugins write with `print` / `trace` / `warn` / `error`; no consumer API for the global log buffer |
| Filesystem `Openplanet.log` | **Yes** | Under data folder (`IO::FromDataFolder("")` → `…/OpenplanetNext/Openplanet.log`) |
| RemoteBuild external tail | **Yes** | Python `OpenplanetLog` class seeks by byte offset, filters `ScriptEngine` + target plugin id |
| Control MCP log tools | **No** | No GetLog / TailLog tool today |
| Screenshot API (game) | **Yes** | `app.Viewport.ScreenShotDoCaptureJpg/Webp/Tga/DDS` via Control MCP `TakeScreenshot` |

**Log line shape (observed)**

```text
[    ScriptEngine] [ TRAC] [22:12:58.963]  Loaded plugin 'Camera' (version 1.0)
[    ScriptEngine] [ERROR] [22:13:05.687]  Script compilation failed!
[    ScriptEngine] [ WARN] [22:15:50.748]  Unloading dependent plugin "tm-control-mcp" of "Editor"
[   ScriptRuntime] [ TRAC] [23:27:05.920] [tm-control-mcp]  TM Control MCP response: {...}
```

Bracket fields: source, level, timestamp, optional plugin id, then text. RemoteBuild’s parser expects this shape.

**Runtime evidence gate (aligns with CONTEXT.md)**

A post-change success requires:

1. A `Loaded plugin '<id>'` (or zipped/legacy variant) **after** the reload command, and
2. No later `Script compilation failed` / `:  ERR :` attributable to that plugin before the next intentional unload, and
3. When behavior changed: an observable behavior check (manual, screenshot, or Control MCP probe).

False “shared class definition changed” refusals require **full game restart**, not diff thrash (`README_FOR_AGENTS.md` / Hermes skill). That is outside L1’s repair power; L1 should surface the log text and stop.

---

## 4. Existing tools on the ladder

### 4.1 L0 — Manual UI

Openplanet Scripts / Plugins UI: load, unload, reload, enable/disable, open log window.
Works with zero agent tooling. Skills must document exact human steps when L1–L3 are absent.

### 4.2 L2 — RemoteBuild (today)

| Piece | Detail |
|-------|--------|
| In-game plugin | `RemoteBuild` / siteid 347, v1.1.0 (`info.toml`); installed as `Plugins/RemoteBuild.op` |
| Author | skybaks upstream; XertroV fork at `~/src/tm-remote-build` with socket/log fixes |
| Listen | Default host empty→localhost; ports **30000** Next, **30001** MP4, **30002** Turbo |
| Routes | `get_status`, `get_data_folder`, `get_app_folder`, `load_plugin`, `unload_plugin` |
| Payload | JSON `{"route":"…","data":{…}}` over TCP; persistent client loop in plugin |
| Client framing | Python expects **4-byte little-endian length prefix** on responses; plugin `Main.as` writes raw JSON via `client.Write(response)` without an explicit length header — fragile; “Error receiving header bytes” is a known stuck mode after script timeout |
| Load algorithm | `GetPluginFromID` → `UnloadPlugin` + `yield` → `LoadPlugin(path, source, type)` — **no dependent snapshot/restore** |
| Logs | External tail of `Openplanet.log`; `getlogs` subcommand; success fallback if socket response missing but log shows Loaded |

**Stuck vs dead** (Hermes `remotebuild-stuck.md`): listener up + connect OK + no length header after `Script execution timeout exceeded` on `RemoteBuild.op` ⇒ reload RemoteBuild itself; staging via rsync still works.

### 4.3 L3 — Control MCP (today)

| Piece | Detail |
|-------|--------|
| Plugin | `tm-control-mcp`, module `TmMcp`, deps `Editor`, `MLHook` |
| Listen | **`127.0.0.1:30006`** default |
| Framing | One TCP connection → one newline-terminated JSON request → one newline-terminated JSON response → close |
| Envelope | `{ok, id, route, error, data}` |
| Routes | `status`, `tools`, `call`, or tool name as route |
| Lifecycle tools | **None** |
| Screenshot | `TakeScreenshot` → viewport capture + folder hints (async file on disk) |
| Process guard | `tools/call.py` checks real `Trackmania.exe` before connect |

Control MCP is correctly scoped as **editor/game automation**. It depends on `Editor`, so unloading Editor kills MCP — MCP cannot be the durable lifecycle daemon for Editor reloads.

### 4.4 Build-script glue (not a rung)

`./build.sh dev` patterns:

- Detect `tm-remote-build` on `PATH`
- Detect host listening on `:30000` (`ss -ltn`)
- Pass `-d` Openplanet data dir for log path
- E++ optionally reloads **only** `tm-control-mcp` via `EPP_RELOAD_CONTROL_MCP` — incomplete vs full cascade

This is project-local orchestration on top of L2, not a substitute for L1.

---

## 5. Capability ladder (normative)

```text
L0 Manual UI + Openplanet.log
 └─ always available when game + human present
L1 Lifecycle bridge (socket, dependency-aware)
 └─ detect by TCP status + plugin id; optional install with skillpack
L2 RemoteBuild
 └─ detect by TCP :30000 (or settings port) + `tm-remote-build` CLI
L3 Control MCP
 └─ detect by TCP :30006 status + optional `tools/call.py`
```

### 5.1 Selection rules

1. **Detect deepest available rung**, but execute lifecycle mutations with the **best lifecycle-capable** rung:
   - Prefer **L1** for any reload of a plugin that currently has loaded dependents, or any library/export provider (`shared_exports` / known hub modules like `Editor`).
   - Prefer **L2** for single leaf plugins with empty reverse-dependent closure when L1 is absent.
   - Use **L0** when L1/L2 absent or stuck.
   - Use **L3** only for post-load interaction/screenshots/state — never as the sole reload path for its own dependency chain.
2. **Fallback is mandatory.** If L3 is down after an Editor reload, that is expected until dependents restore; do not claim “game broken.”
3. **Never require L2/L3** for skillpack v1 portable path. L0 must complete the lifecycle loop with human steps + log file read.
4. Stronger rungs may tighten feedback (colored compile errors, screenshots) but must not redefine “done.”

### 5.2 Capability detection procedure

Skills should run a cheap probe sequence (order fixed for stable diagnostics):

| Step | Probe | Positive signal |
|------|-------|-----------------|
| D0 | Data dir candidates (`$HOME/OpenplanetNext`, `$HOME/win/OpenplanetNext`, Wine path maps) | `Openplanet.log` readable |
| D1 | Optional: game process (`Trackmania.exe` under Proton/Wine) | Process present (Control MCP style) |
| D2 | TCP connect L1 default port **30007** (see §6), send `{"route":"status"}\n` | `ok:true`, `data.role=="lifecycle"` |
| D3 | TCP connect RemoteBuild port **30000** (or env override), `get_status` | `data == "Alive"` **or** log-based confirmation path works |
| D4 | `command -v tm-remote-build` | CLI present |
| D5 | TCP connect **30006**, `{"route":"status"}\n` | `alive:true`, plugin name/version |
| D6 | Plugin folders / `.op` presence under `Plugins/` | Install hints only — not proof the socket is live |

Record a structured capability map in agent-facing output, e.g.:

```json
{
  "log_path": "/home/…/OpenplanetNext/Openplanet.log",
  "lifecycle_bridge": {"available": true, "host": "127.0.0.1", "port": 30007},
  "remote_build": {"available": true, "host": "10.x.x.x", "port": 30000, "cli": true},
  "control_mcp": {"available": false, "port": 30006},
  "selected_lifecycle_rung": "L1"
}
```

### 5.3 Fallback behavior matrix

| Situation | Action |
|-----------|--------|
| L1 timeout / refuse | Fall to L2 if reverse-dependent closure empty; else L0 and warn that dependents may need manual restore |
| L2 stuck (header timeout, listener up) | Reload RemoteBuild via L0/L1; retry once; stage files still OK |
| L2 connection refused | L0; document Scripts UI reload |
| Target compile failure | Keep last good **closure snapshot**; do not invent dependents; print log slice; leave target unloaded/failed as engine did |
| `shared class definition changed` | Stop automated reload loops; request full game restart |
| L3 dead after library reload | Expected until closure restore; run L1 restore or L2 scripted dependent reload; then re-probe L3 |
| No log file | Cannot claim compile success from socket alone; say evidence incomplete |
| Dual Plugins paths | `cmp` staged tree vs both candidates before blaming compiler |

---

## 6. Minimal lifecycle bridge (L1) specification

### 6.1 Purpose

Close the gap between:

- engine cascade unload (automatic), and
- incomplete restore (today’s RemoteBuild + ad-hoc `build.sh` lists).

Provide a **durable, low-dependency** in-game socket service that agents and build scripts can call without pulling editor automation.

### 6.2 Distribution / ownership

| Concern | Decision |
|---------|----------|
| **Where it lives** | Companion plugin **sources shipped in this skillpack repository** under `plugins/lifecycle-bridge/` (final folder name bikeshed OK at implementation; plugin **ID** stable, recommend `op-lifecycle-bridge`) |
| **Why not only upstream RemoteBuild** | RB is third-party; dep-closure is a skillpack product requirement; RB framing is fragile; ownership of restore semantics should not block on skybaks merge |
| **Why not inside Control MCP** | MCP depends on `Editor`/`MLHook` and dies when those unload; also violates “don’t duplicate a general bridge” by overloading MCP with daemon duties |
| **Why not a pure external tool** | Dependent graph and `LoadPlugin` path/source/type are authoritative **inside** the game; external tools can orchestrate but still need an in-game actor |
| **Packaging** | Optional folder plugin; skillpack install docs offer “copy/symlink into `Plugins/`”. Not required for portable L0 path |
| **Dependencies** | **Zero script dependencies** (`info.toml` dependencies empty). Category `Development`. `timeout = 0` |
| **License** | Same as skillpack (`CC0-1.0 OR Unlicense`) |
| **CLI** | Tiny Python/bash client may live under `plugins/lifecycle-bridge/tools/` or `scripts/`; not a PyPI product in v1 |
| **RemoteBuild relationship** | Complementary. L1 does not replace RB store listing. Build scripts may prefer L1 when available, else RB |
| **Control MCP relationship** | Optional thin tools may call L1 over localhost or reimplement read-only inventory via `Meta::*` without owning restore |

### 6.3 Transport and protocol

**Align framing with Control MCP, not RemoteBuild.**

| Field | Value |
|-------|--------|
| Default host | `127.0.0.1` (setting-overridable; empty host discouraged under Wine) |
| Default port | **30007** (Next). Reserve 30008/30009 if multi-title ever needed; do not reuse 30000–30006 |
| Session | One request → one response → close (stateless TCP) |
| Framing | UTF-8 JSON object + `\n` both ways |
| Envelope | `{ "ok": bool, "id": any, "route": string, "error": string, "data": object\|null }` |

**Routes (v1)**

| Route | Purpose |
|-------|---------|
| `status` | Liveness, port, plugin version, Openplanet version string, protocol version |
| `list_plugins` | Loaded plugins: id, version, source, type, path, deps, optional_deps, enabled |
| `list_unloaded` | Optional; warn slow — wrap `Meta::UnloadedPlugins` |
| `snapshot_closure` | Compute reverse-dependent closure for `id` among **currently loaded** plugins; return ordered ids + per-plugin reload descriptors |
| `reload` | Dependency-aware reload of `id` (see algorithm) |
| `load` | Load by id/type/source or absolute path; optional `restore_closure_from` snapshot id |
| `unload` | Unload by id (engine cascades dependents); still snapshot first if `remember=true` |
| `restore_closure` | Load only the remembered/provided closure (after target is healthy) |
| `get_last_snapshot` | Return last snapshot for `id` (survives failed reloads in plugin memory) |

Protocol version field: `data.protocol = 1`.

**Non-goals for v1 routes:** screenshots, editor mutation, HTTP, MCP tool catalog, arbitrary code exec, log streaming RPC.

### 6.4 Dependent-closure algorithm

Definitions:

- **Forward deps** of P: `P.Dependencies` ∪ (optional: loaded-only members of `P.OptionalDependencies`).
- **Reverse edge** Q→P if P’s forward deps contain Q’s ID (or module id as used by `GetPluginFromID`).
- **Loaded reverse-dependent closure** of target T: all loaded plugins reachable from T by reverse edges, **excluding T**, transitively.

Snapshot entry per plugin:

```json
{
  "id": "tm-control-mcp",
  "path": "C:/users/…/Plugins/tm-control-mcp/",
  "source": "user",
  "type": "folder",
  "version": "0.1.0"
}
```

Prefer `SourcePath` + `Source` + `Type` from the live `Plugin@` at snapshot time so restore does not guess.

**`reload` sequence**

1. Resolve T; if missing, error.
2. `snapshot = closure(T)`; store as `last_snapshot[T.id]`.
3. Capture T’s own reload descriptor.
4. Byte-mark or timestamp-mark log (optional client-side) before mutation.
5. `Meta::UnloadPlugin(T)` (engine unloads dependents); yield until T gone from `AllPlugins`.
6. Re-load T via `Meta::LoadPlugin` using descriptor (prefer explicit load over `ReloadPlugin` when path/type known — matches RemoteBuild and allows failed-compile detection via null handle + log).
7. If T failed:
   - Retain `last_snapshot[T.id]`.
   - Do **not** attempt to load dependents (they cannot bind).
   - Optionally attempt one reload of **previous on-disk** T only if client passes `rollback_target:true` **and** staging did not overwrite — default **false** (agents usually already overwrote sources).
   - Return `ok:false` with `data.snapshot` echoed + `data.phase="target_load_failed"`.
8. If T succeeded:
   - Topologically order `snapshot` using forward deps among the snapshot set (Kahn / `PluginIndex` if helpful).
   - Load each missing id; collect per-id results.
   - Return `ok` only if T ok; dependent failures are partial (`data.dependent_errors`).
9. Clients verify via `Openplanet.log` evidence gate regardless of `ok`.

**`PluginIndex` usage:** useful for ordering descriptors with path/source/type; **do not** assume `AddTree` alone yields reverse dependents — build reverse edges from `AllPlugins` + `Dependencies`.

**Optional deps:** include Q in closure only if Q was loaded **and** listed T (or intermediate) in `Dependencies` **or** in `OptionalDependencies`. Do not load optional consumers that were not running.

### 6.5 Failure memory

Bridge process memory holds:

```text
last_snapshot: map<target_id, ClosureSnapshot>
```

Survives failed reloads until:

- successful restore of that snapshot, or
- explicit `snapshot_closure` replace, or
- bridge plugin unload/game exit.

Persist to disk **out of scope for v1** (game restart loses memory — acceptable; L0/L2 still work).

### 6.6 Safety rails

- Refuse to unload/reload the lifecycle bridge itself via its own socket (return error; use L0).
- Refuse essential/system plugins if `Essential` is true.
- Max closure size guard (e.g. 64) to prevent foot-guns.
- Single-flight mutex: one mutating op at a time; concurrent requests get `error: "busy"`.
- Default bind localhost only.

### 6.7 Client evidence helper

Whether Python or bash, the L1 client should:

1. Record log file size before request.
2. Send mutating route.
3. Tail/parse new log lines (reuse RemoteBuild parser ideas or simplified needles).
4. Apply evidence gate for target + each restored dependent.

Do not trust socket `ok` alone when log path is known.

---

## 7. Upstream Control MCP extensions (without duplicating a bridge)

Propose as **optional upstream PRs** to `tm-control-mcp`, not as skillpack forks of the whole plugin.

| Tool / route | Priority | Behavior |
|--------------|----------|----------|
| `ListLoadedPlugins` | P1 | Read-only `Meta::AllPlugins` summary (id, version, deps) |
| `GetPlugin` | P1 | Single id inspect |
| `GetLifecycleCapability` | P1 | Probe localhost L1/L2 ports; return ladder map for agents already on MCP |
| `ReloadPluginViaLifecycleBridge` | P2 | HTTP-less localhost client to L1 `reload` — **delegate only** |
| `GetOpenplanetPaths` | P2 | `FromDataFolder`, log path hint, Screenshots folder (no log body) |
| `TakeScreenshot` | done | Keep; document async file pickup for visual gates |
| Log body streaming | **reject for MCP** | Keep on external filesystem / RB / L1-adjacent clients |

**Explicitly out of Control MCP scope:** implementing dependent-closure restore inside MCP; binding a second lifecycle protocol on 30006; becoming a RemoteBuild clone.

---

## 8. Skills implications (for later tickets — not implemented here)

When skill text is written (blocked on other map decisions):

- Lifecycle skills: detect ladder → choose L1/L2/L0 → always state evidence from log.
- Visual skills: require L3 screenshot **or** manual screenshot drop; never block compile iteration on L3.
- Library/export skills (E++ style): **require** closure-aware reload narrative; if only L2, warn about stripped dependents and list who was lost if log shows `Unloading dependent plugin`.
- Capability probe skill or shared preamble: emit the JSON capability map from §5.2.

---

## 9. Rejected alternatives

| Alternative | Why rejected |
|-------------|--------------|
| **RemoteBuild-only architecture** | No closure memory; live log shows dependents dropped; fragile length-prefix framing; third-party ownership of skillpack-critical semantics |
| **Fold lifecycle into Control MCP** | MCP unloads with `Editor`; wrong dependency tier; expands MCP into general bridge (ticket forbids) |
| **HTTP/SSE/WebSocket general control plane** | Overkill for v1; duplicates MCP direction; larger attack/bind surface |
| **Length-prefixed binary twin of RB protocol** | Inherits known client/plugin mismatch pain; agents already have working newline JSON with MCP |
| **Pure external orchestration without in-game plugin** | Cannot call `Meta::LoadPlugin` / read live dep graph authoritatively |
| **Always unload/reload entire `Plugins/` tree** | Slow; violates “only prior closure”; disrupts unrelated plugins |
| **Restore all info.toml reverse dependents on disk** | Loads plugins the user had disabled/unloaded; surprises; optional-dep explosions |
| **Rely on `Meta::ReloadPlugin` alone** | Still cascades unload of dependents without restore; handle invalidation; weaker path control than explicit Load |
| **In-game log ring buffer RPC as primary evidence** | No API today; filesystem log is durable and already used by RB; avoid inventing parallel truth |
| **Make L2/L3 mandatory in skillpack portable path** | Contradicts map notes and AGENTS.md capability-detection product direction |
| **Patch only E++ `build.sh` hard-coded list** | Fixes one repo, not the ecosystem skillpack; still misses transitive dependents beyond MCP |
| **Persist closure snapshots across game restarts (v1)** | Nice-to-have; not required to specify architecture; adds state/file policy decisions |

---

## 10. Open items deferred (not blocking this ticket’s architecture answer)

1. Exact skill names / progressive disclosure — other research/grilling tickets.
2. Whether L1 ships enabled-by-default in a monorepo Plugins install vs opt-in copy — packaging ticket ([Research official installation and packaging targets](https://github.com/XertroV/tm-plugin-skills/issues/7)).
3. Multi-game port matrix beyond Next for L1 (RB already has 30000–30002).
4. Whether to upstream closure restore into skybaks RemoteBuild **in addition to** L1 (friendly; not required).
5. Automated tests against a headless game — likely impossible; rely on protocol unit tests + live dogfood.

---

## 11. Concrete answers to the ticket question

> What runtime-control architecture and protocol should version one specify across manual Openplanet UI, a minimal project-local lifecycle bridge, RemoteBuild, and optional `tm-control-mcp`?

**Architecture:** four-rung ladder L0→L3 (§5).
**L1 protocol:** newline-delimited JSON on `127.0.0.1:30007`, MCP-like envelope, lifecycle routes only (§6.3).
**APIs:** `Meta::LoadPlugin` / `UnloadPlugin` / `ReloadPlugin` / `AllPlugins` / dep fields / `PluginIndex` for ordering; logs via filesystem `Openplanet.log` (§3).
**Detection / fallback:** ordered probes D0–D6 and matrix (§5.2–5.3).
**Closure rule:** snapshot loaded reverse dependents before mutation; restore only that set after successful target compile; remember across failures (§1, §6.4–6.5).
**Ownership:** L1 companion plugin in skillpack repo; RB external; MCP external with thin delegate extensions (§6.2, §7).
**Non-duplication:** L1 must not become general control; MCP must not become lifecycle daemon (§1, §9).

---

## 12. Appendix — key file references

```text
# RemoteBuild
~/src/tm-remote-build/src/openplanet/Main.as
~/src/tm-remote-build/src/openplanet/API.as
~/src/tm-remote-build/src/tm_remote_build/api.py
~/src/tm-remote-build/src/tm_remote_build/log.py
~/src/tm-remote-build/src/tm_remote_build/cli.py

# Control MCP
~/src/openplanet/my-plugins/tm-control-mcp/src/Server.as
~/src/openplanet/my-plugins/tm-control-mcp/src/Protocol.as
~/src/openplanet/my-plugins/tm-control-mcp/src/McpTools.as  # TakeScreenshot
~/src/openplanet/my-plugins/tm-control-mcp/tools/call.py

# Meta docs / types
~/.llm-general/website-archives/openplanet/root/docs/api/Meta.md
~/OpenplanetNext/OpenplanetCore.json

# Cascade evidence
~/OpenplanetNext/Openplanet.log  # 2026-08-11 ~22:15:50 Editor unload
```

### Appendix — example L1 messages

Request:

```json
{"route":"reload","id":"agent-1","data":{"id":"Editor"}}
```

Success response (abridged):

```json
{
  "ok": true,
  "id": "agent-1",
  "route": "reload",
  "error": "",
  "data": {
    "protocol": 1,
    "target": {"id": "Editor", "loaded": true, "version": "0.8.999999999"},
    "snapshot": {
      "target": "Editor",
      "dependents": [
        {"id": "tm-control-mcp", "type": "folder", "source": "user"},
        {"id": "mcp-tm", "type": "folder", "source": "user"},
        {"id": "tm-agent", "type": "folder", "source": "user"}
      ]
    },
    "restored": ["tm-control-mcp", "mcp-tm", "tm-agent"],
    "dependent_errors": []
  }
}
```

Failure after bad compile (dependents remembered, not restored):

```json
{
  "ok": false,
  "id": "agent-1",
  "route": "reload",
  "error": "target_load_failed",
  "data": {
    "protocol": 1,
    "phase": "target_load_failed",
    "snapshot": { "target": "Editor", "dependents": ["tm-control-mcp", "mcp-tm", "tm-agent"] },
    "hint": "Fix compile errors; retry reload to restore the same dependent closure"
  }
}
```
