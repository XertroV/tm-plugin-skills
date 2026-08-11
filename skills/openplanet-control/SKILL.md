---
name: openplanet-control
description: Use when detecting or using Openplanet runtime-control capabilities, or designing a bounded DEV-only semantic action bridge for plugin testing.
license: CC0-1.0 OR Unlicense
compatibility: Requires an Openplanet plugin folder. Manual Openplanet UI is the portable baseline; optional lifecycle, RemoteBuild, or project-local control tools may be absent.
metadata:
  author: XertroV
  version: "0.1.0"
---

# Openplanet control

## Purpose

Choose the deepest available control capability without making it mandatory, and build only a narrow project-local DEV bridge when automation needs it. Report observed effects, not transport optimism.

## Capability ladder

Probe and preserve this recovery order:

1. **Manual Openplanet UI + `Openplanet.log`.** Portable baseline for load/reload/unload and human interaction.
2. **Minimal lifecycle bridge.** Dependency-closure-aware lifecycle only; no game automation. Snapshot currently loaded reverse dependents before mutation, retain that snapshot across failed target loads, and restore only it in topological order after target health is confirmed.
3. **RemoteBuild.** Use for simple leaf-plugin staging/reload when present. Do not assume it restores dependents; fall back when stuck or when a provider/library has a loaded reverse-dependent closure.
4. **Project-local control.** Optional semantic actions, state setup, assertions, and screenshots after a healthy load. It is not a lifecycle daemon and may disappear when its dependencies reload.

Select the highest useful rung for the operation, not merely the highest reachable socket. Preserve the rung below and print exact manual recovery. See [capability ladder](references/capability-ladder.md).

Do not collapse the two bridge protocols: the researched lifecycle-only L1 uses
newline-delimited JSON, while the optional semantic component-control router
below uses bounded length-prefixed JSON. They have different ownership and
failure contracts.

## Workflow

1. **Discover, do not assume.** Locate the plugin root, build/staging flow, readable `Openplanet.log`, game process if relevant, lifecycle bridge, RemoteBuild listener/CLI, and project control endpoint. Record a capability map and why each signal is or is not proof.
2. **Choose lifecycle separately from interaction.** Prefer the minimal bridge for libraries/providers or loaded dependents; RemoteBuild for a leaf when safe; manual UI otherwise. Use control only after load for state/actions/screenshots. Never ask control to reload the dependency chain that owns it.
3. **Stage exact bytes and mark the log.** Use project build flow when present. Record source identity/digest and log offset/time before mutation.
4. **Execute with fallback.** Bound each attempt. On timeout/refusal/stuck framing, close resources and descend one rung. A missing lower-rung human action is an explicit blocker, not success.
5. **Verify lifecycle truth.** Require a fresh post-action `Loaded plugin '<id>'`, no later attributable compile error, and restored previously loaded dependents where applicable. Socket `ok:true` is not compile proof. A shared-class-definition refusal requires a full game restart rather than an automated reload loop.
6. **Exercise and observe.** Invoke a narrow semantic action or state query, then verify visible/logged/state effect. A truthful response describes whether mutation was performed, rejected, forced, partial, or merely accepted for processing.
7. **Report evidence and fallback.** Include rung selected/attempted, request ID, exact bytes/version, log window, observed state, dependent restore result, unavailable probes, and one concrete next step.

## Optional project-local control bridge

Use it only when repeated semantic automation justifies maintenance. It is:

- compiled under `#if DEV`, disabled by default, explicitly opt-in, and excluded from public/release enablement;
- bound explicitly to `127.0.0.1` (never wildcard `Listen(port)` semantics without a loopback guard);
- one request/reply per connection using bounded **length-prefixed UTF-8 JSON**; live-probe and document integer wire byte order before freezing the client format;
- protected by maximum frame and response sizes, bounded accept/read/execution/write deadlines, exact frame consumption, and close-on-error;
- fixed-route and semantic only—no eval, arbitrary AngelScript, shell, file read/write, generic callback invocation, secrets, stack traces, or unbounded payloads;
- single-flight for unsafe mutation; concurrent mutation returns `busy`;
- owned by one runtime with generation/cancellation state, one complete-frame writer, explicit stop, socket/client closure, registry teardown, and unload/reload cleanup; and
- driven by a checked-in dependency-free CLI that performs exact reads, size/time limits, request-ID checks, macros/assertions, nonzero exits, and cleanup.

Default concrete bounds may be 64 KiB request/response frames with project-recorded deadlines; test zero/one/exact-limit/over-limit, fragmented header/body, malformed length/JSON, partial write, timeout, second client, active-client shutdown, and reload. See [transport and envelopes](references/transport-and-envelopes.md).

## Semantic component actions

Every controllable UI/NVG component registers a stable unique ID and narrow named actions (`click`, bounded `hover`, validated `mouse_button`, or domain-specific equivalents). Registration has an owner/generation and is removed on teardown.

Visibility means the hit target was actually submitted in the current **completed render epoch**, not that an `IsVisible` flag is true:

1. host begins an epoch;
2. component marks itself drawn only after submitting its hit target;
3. host seals the epoch; and
4. action lookup compares `last_drawn_epoch` with the sealed epoch.

`force` defaults to `false`. If not drawn, perform no mutation and return `not_drawn` with one open/render-and-retry step and an explicit `force=true` option. Forced invocation calls the registered semantic callback and returns `forced:true`; it never claims a physical click, hover, or cursor movement. Remote hover is bounded semantic state.

Use a real `startnew(...)` boundary for actions that can throw, yield, perform I/O, or mutate game state. Snapshot typed request data, enforce single-flight/generation checks, revalidate after yields, and report terminal cleanup.

## Completion gate

Complete when the requested action is observed, or when every available safe rung was attempted and the lower-rung blocker is explicit. Static protocol checks, a listening port, and `ok:true` alone are never behavioral or lifecycle proof.
