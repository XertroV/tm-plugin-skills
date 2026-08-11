# Evidence and log diagnosis

## Exact-byte gate

1. Identify canonical source, generated output, and actual load destination.
2. Run the project’s generator/build/stager if provided.
3. Compare each in-scope staged file byte-for-byte with the artifact checked by repository tooling and `openplanet-lsp`.
4. Record digests or an equivalent deterministic identity plus the staging path.
5. If generated artifacts are involved, record the canonical manifest/source that produced them.

A build command exit, copy success, or digest of a different tree does not establish which bytes Openplanet loaded.

## Fresh log window

Immediately before the lifecycle action, record `Openplanet.log` path and byte size/offset. Parse only appended bytes. If size shrinks or the file rotates, record a new boundary and explain it. Preserve the raw slice or its path.

Target load success requires all of:

1. a fresh `Loaded plugin '<id>'` event (or applicable zip/legacy variant) after the action;
2. no later attributable `Script compilation failed`, `:  ERR :`, or equivalent compile failure before the next intentional unload; and
3. for changed behavior, an observed smoke result.

For unload, require a fresh unload event and inspect dependent cascade lines. A socket response is action-delivery evidence, not compilation evidence.

## Diagnostic parity

Compare LSP and game output as structured observations, not booleans:

| Field | Preserve |
| --- | --- |
| Acceptance | accepted/rejected by each checker |
| Reason | exact diagnostic text or normalized category plus raw text |
| Location | file, line, column when available |
| Severity | error, warning, trace/info |
| Warnings | all warnings, including successful-load windows |
| Deprecations | API and compiler deprecation text |

Report mismatches explicitly. A clean LSP with an in-game error is a parity failure and should produce a minimal LSP repro when practical. Missing LSP means parity is blocked, not clean.

## Common diagnoses

- **Fresh load then later compile error:** failure; the later attributable error wins.
- **Old load line before action:** stale evidence; ignore it.
- **Shared-class refusal despite unchanged definitions:** preserve exact text and require full game restart; avoid speculative source churn.
- **RemoteBuild listener connects but client times out reading a response header after script timeout/abort:** reload RemoteBuild, retry once, then use L0. Do not call it successful or necessarily dead.
- **Staging works while reload is stuck:** bytes are staged, not proven running.
- **Two possible `Plugins/` roots:** compare exact bytes at both; correlate the fresh load event with the actual source path/identity.
- **Target succeeds, dependent fails:** target may be compiled; report dependent partial failure separately and retain retry ordering.

## Behavior evidence

Choose a probe tied to the change: deterministic `[Test]`, manual interaction with observed result, state read, fresh screenshot, or control-tool response plus state observation. Record initial state, action, resulting state, and Openplanet/game version/channel when known. Command acceptance alone is not behavior evidence.

## Truthful blocker format

```text
Unavailable probe: <tool/action/evidence>
Observed cause: <missing binary, refused socket, no game/human, unreadable log, ...>
Supported claim: <Static | Compiled | other bounded claim>
Forbidden stronger claim: <parity/runtime/behavior/test/visual proof>
Next action: <specific command, UI action, restart, or required human step>
```

Evidence labels: **Static** for repository/LSP; **Compiled** for a fresh game transcript of exact staged bytes; **Exercised** for behavior or `[Test]`; **Observed** for fresh log/state/screenshot evidence. Never translate tool absence or static success into a runtime pass.
