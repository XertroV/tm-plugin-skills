# Capability ladder and dependent closure

## Select a rung

| Rung | Capability | Use |
| --- | --- | --- |
| L0 | Manual Scripts/Plugins UI + filesystem `Openplanet.log` | Portable fallback and recovery path |
| L1 | Lifecycle-only bridge, normally `127.0.0.1:30007` | Preferred for providers and targets with loaded dependents |
| L2 | RemoteBuild, normally port `30000`, plus CLI/log tail when installed | Leaf load/reload/unload when reverse-dependent closure is empty |
| L3 | Control bridge, commonly `tm-control-mcp` on `30006` | Post-load state, behavior, and screenshots; never owner of its dependency chain |

Probe in stable order: readable log/data-dir candidates; optional game process; L1 `status` (`ok:true`, role `lifecycle`); L2 status and `tm-remote-build` CLI; L3 status; installed plugin files last. Files on disk are install hints, not live sockets.

Pick the best lifecycle-capable rung, not merely the highest numbered rung. Always retain L0. L3 can disappear when a provider such as `Editor` unloads; that is expected until the closure restores.

## Closure invariant

Before mutating target `T`:

1. From currently loaded plugins, build reverse edges from each plugin’s required dependencies. Include only loaded optional consumers as recorded candidates; do not claim cascade/restore semantics for them without live proof.
2. Compute the transitive loaded reverse-dependent closure, excluding `T`.
3. Store each member’s ID and live reload descriptor (`SourcePath`, source, type, version). Store `T`’s descriptor too.
4. If an unrestored snapshot already exists after a failed attempt, reuse it. A retry must not overwrite it with the now-empty live closure.
5. Let Openplanet cascade unload. Reload `T`, yield, re-resolve by ID, and wait for external fresh-log health evidence.
6. If `T` fails, retain the snapshot and load no dependents.
7. If `T` succeeds, topologically sort the retained members by forward dependencies and load providers before consumers. Verify each from the fresh log.
8. Clear snapshot memory only after successful restoration or explicit replacement.

Restore only the prior loaded set. Never auto-enable unrelated plugins, disabled/unloaded consumers, all folders listing the dependency, or optional consumers that were not running.

## Failure and fallback matrix

| Failure | Response |
| --- | --- |
| L1 timeout/refusal | L2 only for empty closure; otherwise L0 with manual retained-list restore |
| L2 header timeout while listener accepts | Reload RemoteBuild via L0/L1, retry once, then L0 |
| L2 refused | L0 |
| Target compile failure | Preserve original snapshot; print fresh log; fix and retry |
| Dependent partial failure | Keep per-ID result; retry after prerequisites, provider first |
| `shared class definition changed` | Stop loops; request full game restart |
| L3 absent after provider reload | Restore closure, then re-probe L3 |
| No readable log | Compilation evidence incomplete; socket success is not a pass |
| Dual plugin paths | Byte-compare both against staged source and correlate fresh log identity |

Openplanet lifecycle operations are queued and plugin handles become invalid next frame. Yield and resolve by ID after mutation.
