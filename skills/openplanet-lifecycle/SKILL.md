---
name: openplanet-lifecycle
description: Use when loading, reloading, unloading, or diagnosing an Openplanet plugin and proving the exact staged bytes are running.
license: CC0-1.0 OR Unlicense
compatibility: Requires plugin source and filesystem access. A running Openplanet instance is required for runtime proof; optional lifecycle or RemoteBuild tools only tighten the loop.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet lifecycle

## Purpose

Stage, load, reload, unload, and diagnose an Openplanet plugin without confusing a successful copy, checker run, socket response, or stale log line with runtime success. Finish with a fresh post-action transcript for the exact staged bytes and observable behavior evidence when behavior changed.

## When to use

Use for first loads, reloads after source changes, unloads, compile diagnosis, dependent restoration, stuck RemoteBuild recovery, and proof that a change reached the game. Development and visual skills should finish behavior-affecting increments through this lifecycle gate.

## Workflow

1. **Resolve plugin identity and topology.** Locate the plugin folder rooted at `info.toml`; record module ID, canonical source, generated outputs, actual staging destination, required and optional dependencies, ordinary/shared exports, and whether the target is already the live folder. Detect project instructions and build/staging scripts before choosing commands. Completion: source, staged destination, module ID, and reverse-dependent risk are explicit rather than inferred from display name.

2. **Detect the capability ladder.** Probe the readable `Openplanet.log`, then available L1 lifecycle bridge, L2 RemoteBuild socket/CLI, and L3 control bridge. Choose the best lifecycle-capable rung: L1 for a provider or a target with loaded dependents; L2 for a leaf with an empty closure when L1 is absent; otherwise L0 manual UI. L3 is for post-load state, behavior, or screenshots, not lifecycle ownership. Keep L0 instructions available even when automation works. Load [capability ladder and dependent closure](references/capability-ladder-and-dependent-closure.md) when selecting or recovering a rung. Completion: selected rung, probes, log path, and fallback are recorded.

3. **Freeze the exact staged bytes.** Run the project build/generator if present, stage to the path Openplanet will load, and compare canonical/generated output to that destination byte-for-byte (`cmp` or an equivalent content comparison). Record a digest or equivalent source identity for every staged file in scope. Run repository checks and `openplanet-lsp` against those same bytes, not an unstaged sibling tree. Preserve every diagnostic, including warnings and deprecations. Completion: the checked bytes and loadable bytes are identical and traceable, or staging is a named blocker.

4. **Open a fresh log window.** Before mutation, record the log path and byte offset/file size (plus timestamp for readability). Read evidence only from bytes appended after that mark; if the log rotates or truncates, reopen it and record the replacement boundary. Do not reuse an earlier `Loaded plugin` line. Completion: the action has a unique, reproducible fresh post-action log window.

5. **Mutate lifecycle with closure safety.** For a provider or target with loaded reverse dependents, snapshot the currently loaded transitive closure before unload. Prefer L1 closure-aware reload. For an empty-closure leaf, use L2 when healthy. At L0, tell the human exactly which Scripts/Plugins UI action to perform and retain the dependent list for manual restoration. Openplanet queues unload/reload and invalidates plugin handles on the next frame; re-resolve by ID after yielding rather than retaining handles. Completion: the target mutation occurred and the prior loaded set is preserved for restoration.

6. **Read the fresh transcript before restoring dependents.** Require a fresh target `Loaded plugin '<id>'` event (including the applicable folder/zip/legacy variant) and no later attributable `Script compilation failed`, `:  ERR :`, or equivalent compile failure before the next intentional unload. Capture game diagnostics with reason, location, severity, warnings, and deprecations; compare them with LSP rather than collapsing either side to pass/fail. A socket `ok`, copied files, or a surviving old plugin instance is insufficient. Completion: target health is established from the fresh log, or failure is diagnosed from that same window.

7. **Restore only the retained closure.** After target health is confirmed, restore previously loaded dependents in topological load order—providers before consumers—and verify each from the fresh log. If target compilation fails, retain the original snapshot and restore none. On retry, reuse that snapshot; never replace it with the now-empty live closure. Record partial dependent failures and retry them after their prerequisites, without enabling unrelated, disabled, unloaded, or merely possible optional consumers. Completion: each snapshot member is restored and evidenced, or listed with its failure and next retry.

8. **Exercise behavior.** When behavior changed, perform a behavior-specific smoke through the available rung: manual interaction, deterministic `[Test]`, visible state, screenshot, or control probe. Observe the result rather than accepting command delivery. For unload-only work, verify the unload and expected dependent state. Completion: requested behavior is observed, or the exact unavailable probe and next action are recorded.

9. **Report evidence and parity.** Report staged identity/digests, selected rung and fallback, mutation command/UI action, fresh log range, target/dependent outcomes, full LSP-versus-game diagnostic parity (acceptance, reasons, locations, severities, warnings, deprecations), behavior evidence, tested Openplanet/game version when known, and gaps. Use **Static**, **Compiled**, **Exercised**, and **Observed** labels accurately. Completion: another person can distinguish what ran, what was observed, and what remains untested.

Load [evidence and log diagnosis](references/evidence-and-log-diagnosis.md) whenever compilation, staging identity, stale logs, RemoteBuild, or evidence claims are in question.

## Manual fallback (L0)

When no lifecycle automation is usable:

1. Stage and byte-compare the target as above; record the fresh log offset.
2. Ask the human to open Openplanet’s Scripts/Plugins UI and load, reload, unload, or enable the exact module ID.
3. Read only the appended `Openplanet.log` window.
4. If the target unloaded dependents, restore the retained list manually in provider-before-consumer order after target success.
5. Exercise the changed behavior manually and record what was observed.

Human interaction is a valid portable rung. If no human can operate the running game, state that runtime proof is blocked; do not replace it with static success.

## Hard recovery rules

- A false `shared class definition changed` refusal requires a full game restart. Surface the log text and stop automated reload loops.
- RemoteBuild listener-up plus TCP-connect success plus response-header timeout after a script timeout means “stuck,” not confirmed dead. Reload RemoteBuild through L0/L1, retry once, then fall back. Staging success remains separate from running-code proof.
- With dual `Plugins/` candidates, compare staged bytes against both and identify the path that produced the fresh load event.
- With no readable log, a lifecycle socket response cannot prove compilation. Report an evidence blocker.

## Missing-tool contract

Missing tools lower the claim, never the standard:

- no `openplanet-lsp`: game compile may be evidenced; static parity is blocked;
- no running Openplanet/game: only candidate/static evidence is possible;
- no lifecycle/RemoteBuild/control bridge: use L0 manual UI; automated control is unproven;
- no human available for L0: state the exact required UI action and report runtime proof blocked;
- no behavior probe or `[Test]` invocation: compilation is not a behavior/test pass.

A truthful blocker names the unavailable probe, observed cause, supported lower claim, and concrete next action.

## Completion checklist

- [ ] Checked source and staged source are byte-identical and identified.
- [ ] The lifecycle action has a fresh log byte window.
- [ ] Target load/unload result comes from that window, not a stale line or socket alone.
- [ ] LSP/game acceptance and all warnings/deprecations are preserved and compared.
- [ ] The prior loaded dependent closure is restored in safe order or retained for retry.
- [ ] Changed behavior is observed through a real smoke.
- [ ] Every missing probe is a blocker or evidence gap, never silently promoted to pass.
