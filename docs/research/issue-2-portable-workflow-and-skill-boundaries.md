# Research: portable Openplanet workflow and skill boundaries

| Field | Value |
| --- | --- |
| Ticket | [Curate the portable Openplanet development workflow and skill boundaries](https://github.com/XertroV/tm-plugin-skills/issues/2) |
| Map | [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1) |
| Type | `wayfinder:research` (evidence asset; not an implementation) |
| Date | 2026-08-11 |
| Status | Proposed boundary map ready for resolution comment |

## Question (restated)

Which independently-triggerable skills and progressive-disclosure references best cover the portable Openplanet plugin lifecycle from initialization through implementation, checking, load/reload/unload, logs, runtime proof, and optional control?

Treat the five-workflow hypothesis (initialization, primary development, runtime/log lifecycle, visual design/review, optional external control) as a hypothesis to test against primary sources, not as a settled design.

## Method

Evidence discipline:

1. Prefer **primary sources** that own the claim (Openplanet docs, `info.toml` / callback / Meta APIs, real plugin trees, existing skill bodies).
2. Treat Max-local process notes (`README_FOR_AGENTS.md`, Hermes `openplanet-plugins`) as **high-trust practice evidence**, then separate portable product rules from machine-specific defaults.
3. Apply Matt Pocock skill ergonomics (invocation cuts, progressive disclosure, completion criteria, load tradeoffs) as the **skill-shape** lens, not as Openplanet domain truth.
4. Do **not** invent product choices reserved for other tickets (visual recipe catalog, control protocol ownership, init interview script, validation tier matrix, packaging targets).

---

## Sources consulted

### Product / map

| Source | Path or URL | Role |
| --- | --- | --- |
| Map issue | https://github.com/XertroV/tm-plugin-skills/issues/1 | Destination, notes, fog |
| This research ticket | https://github.com/XertroV/tm-plugin-skills/issues/2 | Question + hypothesis |
| Domain language | `CONTEXT.md` (repo root) | Portable terms: plugin folder, lifecycle loop, runtime evidence, capability detection, visual gate, control bridge |
| Agent rules | `AGENTS.md` (repo root) | Portable default, detect-not-assume tools, progressive disclosure |
| Repo intent | `README.md` (repo root) | Plugin-under-`Plugins/` default; composable skills |

### Official Openplanet docs (local archive)

Base: `~/.llm-general/website-archives/openplanet/root/docs/`

| Doc | Path | Claim owned |
| --- | --- | --- |
| Modern plugins | `…/tutorials/modern-plugins.md` | Plugin = folder under `Openplanet*/Plugins` with `info.toml`; load via Scripts UI; prove via log; `.op` = zip of folder contents |
| Entry points | `…/tutorials/entry-point-execution.md` | `Main()` is yieldable; reload + log is the feedback loop |
| `info.toml` | `…/reference/info-toml.md` | Manifest keys: meta, deps, exports, shared_exports, module, timeout, defines |
| Callbacks | `…/reference/plugin-callbacks.md` | Lifecycle hooks: Main, Render*, Update, OnEnabled/Disabled/Destroyed, settings, input |
| Settings | `…/reference/settings.md` | `[Setting]` / `[SettingsTab]` model |
| Meta load API | `…/api/Meta/LoadPlugin.md`, `ReloadPlugin.md`, `UnloadPlugin.md` | Programmatic load/reload/unload surface exists |

### Local agent / practice corpus

| Source | Path | Role |
| --- | --- | --- |
| Agent index | `~/src/openplanet/README_FOR_AGENTS.md` | Resource map, mental model, build/check/reload wisdom, control bridge pointer |
| Workspace notes | `~/src/openplanet/CLAUDE.md` | `openplanet-lsp check` discipline; game compiler as ground truth |
| Hermes skill | `~/.hermes/skills/software-development/openplanet-plugins/SKILL.md` | Current monolithic skill: portable build/reload start + Max-specific Editor++/dogfood mass |
| Pattern curation | `…/openplanet-plugins/references/public-pattern-curation.md` | Capability ladder; promotion gates; monolith-default |
| Theme visual | `…/openplanet-plugins/references/theme-respecting-visual-design.md` | Three visual depths + screenshot completion gate |
| RemoteBuild stuck | `…/openplanet-plugins/references/remotebuild-stuck.md` | Optional-tool recovery without claiming game is dead |
| Shared export audit | `…/openplanet-plugins/references/shared-export-audit.md` | Advanced export-surface checklist (progressive disclosure candidate) |
| Screenshot loop | `~/src/openplanet/my-plugins/tm-agent/SKILL-iterative-ui-screenshot-loop.md` | Visual iteration loop + independent critique cadence |
| Control MCP notes | `~/src/openplanet/my-plugins/tm-control-mcp/AGENTS.md` | Active control bridge practice |
| Plugin template | `~/src/openplanet/my-plugins/tm-openplanet-plugin-template/` | Staged-`src/` layout + `build.sh` packaging; README warns against putting the git checkout inside `Plugins/` |
| Standalone plugin | `~/src/openplanet/tm-green-timer/` | Representative small plugin: `info.toml` + `src/` + `build.sh` |
| Live install tree | `~/OpenplanetNext/Plugins/` | Observed staged folders + `.op` deps including `RemoteBuild.op` |

### Skill ergonomics

| Source | Path | Role |
| --- | --- | --- |
| Writing great skills | `~/.agents/skills/writing-great-skills/SKILL.md` | Invocation vs sequence cuts; progressive disclosure; completion criteria |
| Glossary | `~/.agents/skills/writing-great-skills/GLOSSARY.md` | Context load, cognitive load, leading words, premature completion |
| Wayfinder | `~/.agents/skills/wayfinder/SKILL.md` | Research ticket semantics; decisions live in tickets |
| Research | `~/.agents/skills/research/SKILL.md` | Primary-source capture |

### Sibling tickets (boundary interfaces only)

| Ticket | Interface to this research |
| --- | --- |
| [Curate the theme-respecting three-tier visual design skill](https://github.com/XertroV/tm-plugin-skills/issues/3) | Owns visual skill body/recipes; this ticket only places the skill boundary and trigger |
| [Build the provenance-cleared pattern-library candidate catalog](https://github.com/XertroV/tm-plugin-skills/issues/4) | Owns recipe catalog content; develop skill only points at “search before invent” |
| [Define initialization, policy onboarding, and clone-local agent state](https://github.com/XertroV/tm-plugin-skills/issues/5) | Owns init interview script and private-state rules; this ticket places the init skill |
| [Specify the capability ladder and dependency-aware lifecycle bridge](https://github.com/XertroV/tm-plugin-skills/issues/6) | Owns control protocol/ownership; this ticket places the control skill and ladder as disclosure |
| [Define validation tiers and completion evidence](https://github.com/XertroV/tm-plugin-skills/issues/10) | Consumes this boundary map to assign per-skill completion evidence |
| [Choose the final specification shape and approval gate](https://github.com/XertroV/tm-plugin-skills/issues/11) | Consumes the whole decision set |

---

## Findings

### F1. Official portable unit is a plugin folder rooted at `info.toml`

Openplanet’s modern-plugin tutorial creates the plugin **directly under** `Openplanet*/Plugins/<name>/` with `info.toml` and `.as` files in that folder, then loads it from the Scripts menu and proves success in the log (`modern-plugins.md`).

There is no official requirement for a separate source tree, `src/` staging, `build.sh`, LSP, or RemoteBuild.

**Implication:** the skillpack’s portable default (repo may itself be the live `Plugins/` folder — `AGENTS.md`, `README.md`, Hermes skill “Build / reload”) matches official docs. Max’s template README rule (“Do not put the template or the plugin repository folder in `OpenplanetNext/Plugins`”) is a **staging-topology preference for that template**, not the portable floor.

### F2. Two real layout topologies must be detected, not assumed

| Topology | Evidence | Agent behavior |
| --- | --- | --- |
| **Live folder** | Official tutorial; product portable default | Edit in place under `Plugins/<id>/`; reload via UI or bridge |
| **Staged source** | Template + nearly all Max plugins (`info.toml` at repo root, sources under `src/`, `./build.sh` stages flat into `Plugins/<name>/`) | Edit repo; never hand-copy; use project build when present; verify staged path with `cmp` |

Template staging rule (template `README.md`): contents of `src/` land at the staged root, so export paths and runtime paths are **not** prefixed with `src/`.

Hermes skill already encodes detect-then-act for both topologies (`SKILL.md` “Build / reload”).

### F3. The lifecycle loop is the product’s completion spine

`CONTEXT.md` defines:

- **Lifecycle loop** — edit → check → load/reload → inspect post-action log → exercise behavior → collect evidence
- **Runtime evidence** — post-change `Loaded plugin` with no later compile error for that plugin, plus observable behavior check when behavior changed

Official docs use the same spine at lower fidelity: edit → reload → read log (`modern-plugins.md`, `entry-point-execution.md`).

Hermes skill strengthens the log window: after a failed compile the game may still log a later successful load; scan for `ERR` / `Script compilation failed` **after** the latest `Loaded plugin '…'` line.

**Implication:** any skill that ends a behavioral change without runtime evidence invites **premature completion** (Pocock glossary).

### F4. Optional tools form a capability ladder, not prerequisites

Documented ladder (`public-pattern-curation.md`, restated in Hermes skill and map notes):

1. Manual Openplanet Scripts UI + log inspection
2. Minimal project-local lifecycle hook (socket) when needed
3. RemoteBuild for load/unload/reload
4. `tm-control-mcp` for screenshots, state inspection, interaction

Observed live tree includes `RemoteBuild.op` and `tm-control-mcp` under `~/OpenplanetNext/Plugins/`, confirming rungs 3–4 as real optional installs, not hypotheticals.

`openplanet-lsp check` appears in workspace practice (`CLAUDE.md`, many `build.sh` scripts) as a **pre-game static check**, not a substitute for game compile. When missing, degrade to game compile + log (map fog + issue 10).

Meta API documents programmatic `LoadPlugin` / `ReloadPlugin` / `UnloadPlugin` — relevant to issue 6’s bridge design; lifecycle skill must not assume a particular bridge.

### F5. The existing Hermes skill is a useful corpus and a negative example of granularity

`openplanet-plugins/SKILL.md` (~187 lines) currently mixes:

| Portable / general | Max-machine / product-specific |
| --- | --- |
| Plugin-folder model; detect build system | Editor++ gizmo delete crash matrix |
| Runtime evidence from logs | Dogfood PR shepherding + GraphQL review threads |
| Capability ladder pointer | Dual-repo E++ ↔ MCP rebuild order |
| Pattern search before invent | Version-number ownership ritual for Max |
| Export surface model | Specific MCP smoke recipe for BlueBay items |

Pocock **sprawl** / **context load**: one always-on description tries to own every Openplanet task. Agents working a simple timer plugin still pay for gizmo UAF lore.

**Implication:** skillpack v1 should **split by independently triggerable workflow**, and park Max-specific depth as optional progressive references or out-of-pack personal skills — not in the portable core bodies.

### F6. Workflow clusters in the wild

Observed clusters from docs + plugins + skills (not from the hypothesis alone):

| Cluster | What the agent is doing | Distinct leading words / user phrasing | Distinct completion criterion? |
| --- | --- | --- | --- |
| **Initialize** | Create or normalize a plugin folder, `info.toml`, basic layout, first load | new plugin, scaffold, from template, bootstrap `info.toml` | Folder loads once; meta is coherent |
| **Develop** | Implement behavior in AngelScript; settings; callbacks; deps; search patterns | implement, fix, add feature, AngelScript, settings, API | Code + static check when available; **defers** runtime proof to lifecycle for behavior changes |
| **Lifecycle / runtime proof** | Load/reload/unload; read log window; recover stuck tools; prove running version | reload, unload, Openplanet.log, Loaded plugin, compile failed, RemoteBuild stuck | Runtime evidence per `CONTEXT.md` |
| **Visual** | ImGui/NVG/UI polish with theme respect + screenshots | UI, ImGui, NVG, overlay, theme, screenshot, polish | Fresh screenshot critique gate (`theme-respecting-visual-design.md`, screenshot-loop skill) |
| **Control** | Drive game/editor via optional bridge | MCP, control bridge, live editor, screenshot capture tool, RemoteBuild client | Action result + still preserves lower-rung fallback |
| **Export surface** (sub-cluster) | Cross-plugin `exports` / `shared_exports` | export, shared class, dependent plugin | Audit checklist; rare for default monolith |
| **Package / publish** (sub-cluster) | `.op` zip, store upload | release, `.op`, publish | Owned by issues 7–9, not this boundary set |

The five-workflow hypothesis **survives** as the right *top-level* cut. Two sub-clusters are real but should **not** be top-level portable skills in v1:

- **Export surface** — advanced branch under develop (default is monolith; map notes).
- **Package/publish** — separate research/task tickets; not required to close the day-to-day lifecycle.

### F7. Pocock cuts applied

| Cut | Application |
| --- | --- |
| **By invocation** | Five model-invoked skills with distinct leading words (init / develop / lifecycle|reload|log / visual|UI|screenshot / control|MCP|RemoteBuild). |
| **By sequence** | Lifecycle split from develop so “ship the edit” does not skip log proof; visual split so screenshot gate is not optional prose inside develop. |
| **Progressive disclosure** | Export audit, RemoteBuild stuck, API lookup paths, pattern-curation gates, control ladder details → linked references, not SKILL.md bulk. |
| **Avoid excessive fragmentation** | No per-namespace skills (`Net`, `UI`, `IO`); no separate “lsp-check” skill; no separate “debug” skill. |
| **Avoid monolith** | Reject single `openplanet-plugins` body that owns all five clusters (Hermes status quo). |

### F8. Tension to preserve in the skillpack (not resolve away)

| Tension | Portable resolution |
| --- | --- |
| Official live-folder tutorial vs Max staged-`src/` template | Detect topology; support both; never moralize one as “wrong” |
| `openplanet-lsp` helpful vs optional | Check when present; game compile remains ground truth |
| Screenshot loop skill pushes branded polish vs theme-respecting default | Visual skill defaults to theme-respecting ImGui; branded/ Palettes are advanced depth (issue 3) |
| Control MCP powerful vs absent for most authors | Control skill is optional rung; lifecycle always has manual UI path |

---

## Decisive proposed boundary map

### Top-level skills (v1 portable core)

Five independently triggerable, model-invoked skills. Names are **proposals** for the specification to adopt or rename; the cut matters more than the final slug.

```text
                    ┌──────────────────────────┐
                    │  capability detection     │
                    │  (shared step, not skill) │
                    └────────────┬─────────────┘
           ┌──────────────┬──────┴──────┬──────────────┬────────────┐
           v              v             v              v            v
   openplanet-init  openplanet-dev  openplanet-   openplanet-  openplanet-
                                    lifecycle     visual       control
           │              │             │              │            │
           │              ├─ref: APIs   ├─ref: RB      ├─ref:       ├─ref:
           │              ├─ref: export │   stuck      │  depths    │  ladder
           │              └─ref:patterns│              └─ref: shot  └─ref:
           │                            │                 loop        protocol
           └──────── cross-link on behavior change ───────┘            │
                        dev ──requires──> lifecycle                    │
                        visual ──requires──> lifecycle (+ screenshot)  │
                        control ──fallback──> lifecycle manual rung <──┘
```

### Shared preamble (every skill, short)

Not a sixth skill — a few lines repeated or one tiny always-linked reference:

1. Locate **plugin folder** (`info.toml`).
2. Detect **topology** (live vs staged) and **capabilities** (build script, LSP, RemoteBuild, control bridge, screenshot tool).
3. Prefer project tools when present; never invent a required toolchain.
4. Domain terms: `CONTEXT.md`.

---

### Skill 1 — `openplanet-init`

| Field | Proposal |
| --- | --- |
| **Purpose** | Create or normalize a plugin folder so it can load under Openplanet. |
| **Trigger description (model-facing draft)** | Use when scaffolding a new Openplanet plugin, writing the first `info.toml`, cloning a template into a workable plugin folder, or onboarding a young plugin’s layout before feature work. |
| **Leading words** | scaffold, new plugin, `info.toml`, bootstrap, template |
| **In-skill steps (outline)** | Confirm target game/Openplanet tree → choose live-folder vs staged-source topology → write minimal `[meta]` (+ empty/minimal script entry) → place first `.as` with `Main()` → first load + log proof (hand off to lifecycle for the proof mechanics) → stop before feature scope creep |
| **Completion criterion** | Plugin identity is loadable: valid `info.toml`, at least one script module entrypoint path, and a successful first-load runtime evidence record (or explicit blocker: game not running). |
| **Progressive disclosure** | Full init interview + policy onboarding + clone-local private state → owned by [issue 5](https://github.com/XertroV/tm-plugin-skills/issues/5). Template mechanics → template README. Official keys → `info-toml.md`. |
| **Cross-links** | → `openplanet-lifecycle` for first-load proof; → `openplanet-dev` after scaffold; do **not** auto-enter visual/control. |
| **Out of body** | Store policy deep dive (issues 8–9); packaging matrix (issue 7); export/multi-plugin architecture (ask once, default monolith). |

### Skill 2 — `openplanet-dev`

| Field | Proposal |
| --- | --- |
| **Purpose** | Implement and modify plugin behavior in AngelScript inside an existing plugin folder. |
| **Trigger description (model-facing draft)** | Use when implementing or changing Openplanet/Trackmania plugin behavior, AngelScript code, settings, callbacks, dependencies, or plugin structure — and the task is not primarily UI polish, reload/log diagnosis, scaffolding, or live control. |
| **Leading words** | implement, AngelScript, settings, callback, dependency, feature, fix (plugin code) |
| **In-skill steps (outline)** | Read plugin AGENTS/README if any → search sibling/pattern corpus before inventing → edit sources → run `openplanet-lsp check` when available → if behavior changed, **invoke lifecycle** for runtime proof → if UI appearance changed, **invoke visual** |
| **Completion criterion** | Requested behavior is expressed in source; static check clean when tool exists; for behavior-affecting changes, lifecycle completion criterion is also met (hard gate via cross-link, not optional advice). |
| **Progressive disclosure** | Callbacks (`plugin-callbacks.md`); settings (`settings.md`); preprocessor/imports; type DBs / docs archive paths; **export/shared audit** (`shared-export-audit.md`) only when `exports`/`shared_exports` or multi-plugin APIs are in play; pattern promotion gates (`public-pattern-curation.md`); game-compiler→LSP feedback loop (`CLAUDE.md` pattern). |
| **Cross-links** | → `openplanet-lifecycle` (required after behavior change); → `openplanet-visual` (appearance change); → `openplanet-control` (when live editor/state driving is the task); → pattern catalog once issue 4 lands. |
| **Architecture defaults (in-body, short)** | Monolith plugin unless user accepts cross-plugin cost; prefer mature ecosystem deps; do not invent version numbers when the project treats versions as human-owned (portable phrasing: “read and report; don’t bump unless asked”). |

### Skill 3 — `openplanet-lifecycle`

| Field | Proposal |
| --- | --- |
| **Purpose** | Load, reload, unload, and **prove** what is actually running using logs and observable behavior. |
| **Trigger description (model-facing draft)** | Use when loading, reloading, or unloading an Openplanet plugin; when proving a change took effect; when reading Openplanet logs for compile/load errors; or when recovering a stuck reload/RemoteBuild path without assuming optional tools. |
| **Leading words** | reload, unload, load plugin, Openplanet.log, Loaded plugin, compile failed, runtime evidence |
| **In-skill steps (outline)** | Detect how reload will be performed (manual UI → project hook → RemoteBuild → other) → trigger load/reload/unload → open/read post-action log window → require fresh `Loaded plugin '…'` (or unload confirmation) with no later compile ERR for that plugin → exercise behavior when behavior changed → record evidence |
| **Completion criterion** | Matches `CONTEXT.md` **runtime evidence**. Absence of tools degrades capability rung; absence of evidence is failure, not success. |
| **Progressive disclosure** | RemoteBuild stuck diagnosis (`remotebuild-stuck.md`); false “shared class definition changed” → full game restart recovery (Hermes skill); staged-path `cmp` verification; Meta API load/reload/unload for bridge authors (issue 6). |
| **Cross-links** | ← required from dev/visual after changes; → control only when higher rung needed and available; never make control the only recovery path. |
| **Non-goals** | Implementing control protocol (issue 6); defining full validation tier matrix (issue 10) — this skill supplies the **runtime** tier mechanics those tickets reference. |

### Skill 4 — `openplanet-visual`

| Field | Proposal |
| --- | --- |
| **Purpose** | Theme-respecting visual design and review for plugin UI/overlays. |
| **Trigger description (model-facing draft)** | Use when designing, changing, or reviewing Openplanet plugin UI or overlays (ImGui/`UI::`, NVG, custom draw) where appearance matters — including theme-respecting defaults, NVG helpers, or advanced custom styling — and when a screenshot completion gate is required. |
| **Leading words** | UI, ImGui, NVG, overlay, theme, screenshot, visual polish |
| **In-skill steps (outline)** | State intended depth (1 theme-ImGui / 2 NVG / 3 advanced) → one focused change → lifecycle reload → fresh screenshot → observe-then-critique (not house-style conformity) → independent reviewer cadence for advanced work → final screenshot pass |
| **Completion criterion** | Visual gate from `CONTEXT.md` + theme-respecting reference: fresh screenshots reviewed against stated intent; alternate-theme check when color/contrast assumptions matter. |
| **Progressive disclosure** | Full three-tier recipe library, exemplars, and API gotchas → [issue 3](https://github.com/XertroV/tm-plugin-skills/issues/3) + `theme-respecting-visual-design.md` + screenshot-loop skill as historical source (note: loop skill currently biases branded polish; portable default is theme-respecting). |
| **Cross-links** | → `openplanet-lifecycle` every iteration; → `openplanet-control` when screenshot/capture tools are the available rung; → `openplanet-dev` for non-visual logic. |
| **Default stance** | Preserve user Openplanet theme; hard-coded palettes and broad style pushes are depth 3 opt-in (map notes). |

### Skill 5 — `openplanet-control`

| Field | Proposal |
| --- | --- |
| **Purpose** | Optional external/runtime control: drive load lifecycle, inspect state, capture screenshots, exercise editor/game actions through the deepest **available** rung. |
| **Trigger description (model-facing draft)** | Use when controlling a live Openplanet/Trackmania session through RemoteBuild, a project lifecycle bridge, or Control MCP (or successor) — screenshots, editor actions, state inspection — or when selecting the right control capability rung and fallback. |
| **Leading words** | RemoteBuild, control MCP, live control, bridge, editor automation, capability ladder |
| **In-skill steps (outline)** | Detect installed rungs → choose deepest available → preserve fallback → perform action → verify via lifecycle log and/or tool result → do not claim stronger rung than detected |
| **Completion criterion** | Requested control action observed; if failed, next-lower rung attempted or explicit blocker; never “success” solely because a socket accepted bytes without runtime evidence when reload was involved. |
| **Progressive disclosure** | Full protocol, ownership (this repo vs companion plugin vs upstream), dependent-closure restore semantics → [issue 6](https://github.com/XertroV/tm-plugin-skills/issues/6). Active practice pointer today: `tm-control-mcp` + `tools/call.py` (Hermes skill, MCP `AGENTS.md`). |
| **Cross-links** | → `openplanet-lifecycle` as permanent fallback; ← from visual when capture needs the bridge; not required for pure code edits on live-folder plugins with manual reload. |

---

## Progressive-disclosure reference map (not separate skills)

| Reference (proposed path under skillpack) | Content | Loaded when |
| --- | --- | --- |
| `references/capability-detection.md` | How to find `info.toml`, topology, build.sh, LSP, RB, MCP, screenshot tools | Shared preamble / all skills |
| `references/runtime-evidence.md` | Exact log-window rules, false shared-class reload, staged `cmp` | Lifecycle; end of dev/visual |
| `references/export-surface.md` | exports / shared_exports / module model + audit checklist | Dev when cross-plugin API touched |
| `references/api-lookup.md` | Docs archive, type DB paths, official API roots | Dev / visual when resolving symbols |
| `references/pattern-search.md` | Search-before-invent; provenance pointer to issue 4 catalog | Dev |
| `references/remotebuild-recovery.md` | Stuck vs dead; reload RemoteBuild first | Lifecycle / control when RB present |
| `references/visual-depths.md` | Three depths summary; points to issue 3 body | Visual |
| `references/control-ladder.md` | Four rungs; points to issue 6 protocol | Control / lifecycle |

These are **context pointers**, not invocation surfaces — Pocock progressive disclosure.

---

## Cross-link matrix

| From → To | When |
| --- | --- |
| init → lifecycle | First load proof |
| init → dev | After scaffold, feature work begins |
| dev → lifecycle | Any behavior-affecting change (required) |
| dev → visual | Appearance/layout/overlay change |
| dev → control | Task is live drive/inspect, not just code |
| visual → lifecycle | Every visual iteration reload |
| visual → control | Screenshot/capture rung available and needed |
| control → lifecycle | Reload involved, or fallback when bridge missing |
| lifecycle → control | Manual rung insufficient and higher rung detected |
| \* → init | No `info.toml` / broken layout discovered mid-task |

---

## Rejected alternatives

### R1. One monolithic `openplanet-plugins` skill

**Why rejected:** Hermes skill already shows the failure mode — portable reload rules buried under product-specific gizmo/dogfood mass; high context load; weak independent triggers; visual and lifecycle completion criteria get skipped as “later sections.” Map and README explicitly want concise composable skills.

### R2. Merge develop + lifecycle into one “build loop” skill

**Why rejected:** Sequence cut. Lifecycle is independently triggered (“why didn’t reload work?”, “prove it’s loaded”, “RemoteBuild stuck”) without code changes. Merging lets agents declare develop complete at “LSP clean” and skip log proof — the exact premature-completion failure `CONTEXT.md` exists to prevent. Cross-link with a **required** gate is enough coupling.

### R3. Separate `openplanet-lsp` / “static check” skill

**Why rejected:** Checking is a capability rung inside develop/lifecycle, not a user-facing workflow. No distinct completion product beyond “diagnostics.” Fragmentation without invocation value.

### R4. Per-API or per-concern micro-skills (`openplanet-settings`, `openplanet-net`, `openplanet-coroutines`, …)

**Why rejected:** Exhaustive fragmentation; cognitive/context load explosion; official docs already own API reference pages. Develop skill should **point at** docs/type DBs, not re-host the API surface as skills.

### R5. Top-level `openplanet-exports` skill in v1

**Why rejected:** Map default is monolith; exports are an advanced branch. A progressive reference + audit checklist covers the rare path without a permanent description competing for attention. Revisit only if issue 4/5 show exports are a primary author journey.

### R6. Top-level package/publish skill in this boundary set

**Why rejected:** Real cluster (modern-plugins packing section; template release mode; issues 7–9) but outside the portable **day-to-day lifecycle** this ticket was asked to cover. Keep packaging out of the five core triggers so v1 stays game-dev-loop focused.

### R7. Fold visual into develop with “remember to screenshot” prose

**Why rejected:** Visual work has a different completion criterion (screenshot gate), three intentional depths, and a dedicated research ticket (issue 3). Prose reminders lose to dedicated skills with checkable criteria (Pocock completion criterion + screenshot-loop empirical practice).

### R8. Require Max’s staged-`src/` + `build.sh` + RemoteBuild as the only supported workflow

**Why rejected:** Contradicts official modern-plugins tutorial, product portable default, and map notes (“detect, don’t assume”). Skills must work for a first-time author with only Openplanet + a folder.

### R9. Require Control MCP (or any bridge) for “done”

**Why rejected:** Capability ladder rung 1 is manual UI + log. Issue 6 and pattern-curation both forbid making a stronger rung the only recovery path.

### R10. Six+ skills by splitting init into “policy onboarding” vs “scaffold”

**Why rejected:** Issue 5 owns onboarding content; both share the same invocation moment (young/new plugin). One init skill with progressive disclosure keeps the frontier small.

---

## Hypothesis verdict

The five-workflow hypothesis is **accepted as the v1 top-level skill cut**, with these refinements:

1. Name the clusters as independently triggerable skills with explicit required cross-links (not five chapters of one skill).
2. Treat export-surface and package/publish as **disclosed sub-clusters**, not top-level v1 skills.
3. Make **capability detection** a shared step, not its own skill.
4. Bind develop/visual completion to lifecycle (and visual to screenshots) so composability does not reintroduce premature completion.
5. Keep Max-specific Editor++/dogfood content out of portable core bodies.

---

## Implications for blocked tickets (non-resolving)

| Ticket | What this asset hands off |
| --- | --- |
| Issue 10 (validation tiers) | Five completion criteria above as the skeleton for ordinary guidance vs recipe vs release gates |
| Issue 11 (spec shape) | Proposed skill list + reference tree + cross-link matrix as the workflow chapter outline |
| Issue 3 | Visual skill is in; body/recipes still open |
| Issue 5 | Init skill is in; interview/private-state still open |
| Issue 6 | Control skill + ladder disclosure is in; protocol/ownership still open |
| Issue 4 | Pattern reference pointer from develop; catalog content still open |

---

## Document checks run

1. **Citation path existence** — all primary paths listed in Sources consulted were checked present on the research host (2026-08-11).
2. **Internal consistency** — five skills, eight reference slots, ten rejected alternatives; no skill proposed for open product decisions owned by other tickets.
3. **Wayfinder compliance** — research asset only; no skill implementation; issue not edited/closed by this work.
4. **Domain language** — uses `CONTEXT.md` terms (plugin folder, lifecycle loop, runtime evidence, portable path, capability detection, visual gate, control bridge).

---

## Proposed one-line resolution gist (for later map append)

> Portable v1 skillpack splits into five independently triggerable skills — init, dev, lifecycle, visual, control — with shared capability detection, required dev/visual→lifecycle proof links, and progressive references for exports, patterns, and optional tool recovery; rejects monolith and per-API fragmentation.

*(Do not post until a human/session performs formal ticket resolution per `docs/agents/issue-tracker.md`.)*
