# Onboarding and clone-local state

Use this reference while completing an initialization brief and detecting local
capabilities. The split is based on portability: decisions that another clone
must inherit are tracked; facts specific to this checkout stay clone-local.

## Tracked initialization state

Track the completed initialization brief in the plugin repository. It records:

- purpose, identity, target/tested games, and publication intent;
- source/provenance and truthful AI-use assumptions;
- paid-feature permissions and policy assumptions;
- module topology, dependencies, exports, and durable ownership boundaries;
- canonical source plus deterministic build/staging design;
- expected callbacks and validation plan; and
- the smallest observable first-load gate.

The brief is mandatory even for a one-file, temporary, or local-only plugin.
Local-only status is a publication choice, not an exception to safety, rights,
integrity, provenance truthfulness, or non-deception.

## Clone-local capability receipt

In a Git checkout, choose a repository-relative private path such as
`.openplanet/local-state.md`. Add the exact path to this checkout's
`.git/info/exclude` before writing the receipt:

```text
# Openplanet initialization capability receipt
.openplanet/local-state.md
```

Verify the path is ignored with:

```sh
git check-ignore -v .openplanet/local-state.md
```

If the plugin folder has no `.git/` metadata, do not add an ignored file inside
the public/live plugin folder. Store the receipt in external private state under
the user's agent/config data directory, keyed by a stable digest of the plugin's
absolute root path. Record only the external receipt's logical identifier in the
report, not a machine-local path in tracked docs. If neither a Git-local exclude
nor a private external store is available, omit the receipt and report that
capability persistence is unavailable; initialization can still proceed from the
tracked brief and fresh runtime evidence.

A useful receipt may contain:

```markdown
# Openplanet local capability receipt

- Observed at: <timestamp>
- Plugin folder: <machine-local path>
- Live Plugins tree: <machine-local path or unavailable>
- Canonical/staged topology: <relationship and comparison command>
- Build command: <command or unavailable>
- openplanet-lsp: <version/path/result or unavailable>
- Lifecycle rung: <manual / bridge / RemoteBuild / control>
- Openplanet.log: <path or unavailable>
- Detected game/Openplanet version: <observed value or unknown>
- First-load receipt: <fresh log offsets/timestamp and observable result>
- Blocker: <attempt, exact cause, next step; omit if none>
```

A receipt is evidence only for this checkout and observation time. Refresh it
when paths, installed tools, game state, or Openplanet versions change. Never
promote a detected local path or capability into a portable requirement unless
that architectural decision is intentionally made and documented.

## Secret boundary

Never write secrets to the tracked brief or clone-local receipt. This includes
passwords, API keys, cookies, bearer/session tokens, private keys, credentials,
and tokenized action URLs. Record only the name of the approved secret-store or
runtime injection mechanism and whether it is available. If none exists, record
an authentication blocker without soliciting or copying the secret into project
artifacts, logs, prompts, or commits.

## Capability ladder

Detect before choosing:

1. manual Openplanet UI plus `Openplanet.log`;
2. a minimal project-local lifecycle bridge;
3. RemoteBuild staging/load support; and
4. an optional project-local control bridge.

Use the highest available rung, but keep the manual path as recovery. Record
commands, paths, versions, ports, log windows, byte comparisons, and runtime
receipts locally. A missing higher rung lowers the evidence available; it does
not make initialization fail if a lower rung proves the same loadable identity.

## First-load evidence

A successful receipt identifies the exact plugin and records a fresh
post-action `Loaded plugin` event, confirms that no later compilation error for
that plugin appears in the inspected window, and captures the initialization
brief's observable gate. Static diagnostics, an old load line, copied files, or
a tool's success exit alone do not prove the running bytes.

When live proof cannot be obtained, write an explicit runtime blocker containing:

- the rung and action attempted;
- the exact unavailable capability or observed failure;
- any static/exact-bytes evidence that did succeed, without calling it runtime
  proof; and
- one concrete next action that could obtain first-load evidence.

Stop after identity proof or blocker capture. Feature behavior, visual design,
control infrastructure, and speculative module boundaries belong to their own
workflows.
