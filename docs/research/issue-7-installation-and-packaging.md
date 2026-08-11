# Research: official installation and packaging targets (issue 7)

**Ticket:** [Research official installation and packaging targets](https://github.com/XertroV/tm-plugin-skills/issues/7)  
**Map:** [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1)  
**Date:** 2026-08-11  
**Branch:** `research/issue-7`  
**Status:** Evidence + recommended v1 decisions (not implemented; issue not closed)

## Question

Which installation and package metadata targets must version one officially support, and what repository layout serves them without unnecessary release machinery?

Evaluate Agent Skills installation (including `npx skills add`), Claude Code plugin metadata, Codex/OpenAI agent metadata, direct git use, and maintainer symlink conveniences. Use Matt Pocock's repository ergonomics as a reference while preserving concise domain-specific content and the `CC0-1.0 OR Unlicense` licensing choice. Resolve an installation matrix, generated-versus-authored metadata policy, and validation requirements.

## Method

Primary sources inspected (not secondary blogs):

| Source | What was read |
| --- | --- |
| This repository | `README.md`, `AGENTS.md`, `CONTEXT.md`, `LICENSE`, `LICENSES/*`, `docs/agents/issue-tracker.md` |
| Issue 1 (map) and issue 7 bodies | Destination constraints; packaging research brief |
| [agentskills.io specification](https://agentskills.io/specification.md) and [agentskills/agentskills](https://github.com/agentskills/agentskills) | Canonical `SKILL.md` format, progressive disclosure, `skills-ref` / `agentskills` validator |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI v1.5.22 (`npx skills`, README, `src/agents.ts`, `src/plugin-manifest.ts`, discovery rules) | Install matrix, agent paths, skill discovery depth, Claude plugin manifest discovery |
| [Claude Code skills](https://code.claude.com/docs/en/skills.md) and [plugins](https://code.claude.com/docs/en/plugins.md) / [plugins reference](https://code.claude.com/docs/en/plugins-reference.md) | Skill locations, frontmatter extensions, `plugin.json` schema, path behavior |
| `claude plugin validate --help` (local CLI) | Strict validation gate |
| [OpenAI Codex skills](https://developers.openai.com/codex/skills.md) | Local skill load paths, progressive disclosure budget, `agents/openai.yaml` |
| [openai/codex](https://github.com/openai/codex) samples | `openai_yaml.md`, Codex `plugin.json` / marketplace specs (`skills` as a **string path**) |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Layout, install story, `.claude-plugin/*`, ADR 0002, `scripts/link-skills.sh`, invocation split, version sync |

No packaging files were added beyond this research note. No issue comments, closes, or map edits were made.

---

## Executive decision (v1)

### Official installation matrix

| Target | v1 status | User-facing install | Notes |
| --- | --- | --- | --- |
| **Agent Skills / skills.sh** | **Required** | `npx skills@latest add XertroV/tm-plugin-skills` | Universal path for Codex, Claude (editable copy), Cursor, OpenCode, Grok Build, and the rest of the skills CLI agent table. Project or global (`-g`). Default symlink into agent dirs; `--copy` when symlinks are unavailable. |
| **Claude Code native plugin** | **Required** | Documented once listed or via repo marketplace fallback: `claude plugins install …` / `/plugin install …` | Managed, read-only, namespaced skills. Ship `.claude-plugin/plugin.json` (+ fallback `.claude-plugin/marketplace.json`). Official Anthropic marketplace listing is **aspirational**, not a v1 gate. |
| **Direct git** | **Required** | `git clone` then either (a) `npx skills add ./tm-plugin-skills`, (b) Claude `--plugin-dir` / marketplace-add of the clone, or (c) maintainer symlink script | Portable default for offline, forks, and unreleased commits. |
| **Codex / OpenAI skill files** | **Required via skills.sh + git** | Same as Agent Skills row; Codex loads repo skills from `.agents/skills` (and user `~/.agents/skills` / `$CODEX_HOME/skills` depending on path) | Author `agents/openai.yaml` per skill. |
| **Native Codex plugin** (`.codex-plugin/plugin.json`) | **Deferred** | — | Codex `skills` is a **single path string** with recursive discovery. Greenfield layout below keeps a future single-path plugin cheap; do not ship or document a Codex plugin in v1. |
| **npm registry publish** | **Rejected** | — | `package.json` may exist as **private** version/metadata only. Install is git + skills CLI + Claude plugin, not `npm i`. |
| **Maintainer symlink script** | **Maintainer-only** | `scripts/link-skills.sh` (not in user README install block) | Symlinks every promoted skill into `~/.claude/skills` and `~/.agents/skills` for live editing of this repo. |

**Exclusive routes for end users (document explicitly):** pick **either** the Claude plugin (subscribe, read-only) **or** skills.sh / git copies (own and edit). Installing both duplicates every skill. Same lesson as Matt Pocock's install block.

### Repository / package layout (v1)

Greenfield advantage over mattpocock/skills: put **only promoted, installable skills** under `skills/`. Keep drafts outside discovery containers.

```text
tm-plugin-skills/
├── LICENSE                          # SPDX: CC0-1.0 OR Unlicense
├── LICENSES/
│   ├── CC0-1.0.txt
│   └── Unlicense.txt
├── README.md                        # human index + canonical install block
├── AGENTS.md                        # agent maintainer rules (may symlink CLAUDE.md)
├── CLAUDE.md                        # same content or primary; keep in sync
├── CONTEXT.md                       # domain language (already present)
├── package.json                     # private: true; version source of truth
├── .claude-plugin/
│   ├── plugin.json                  # Claude plugin manifest; explicit skills[]
│   └── marketplace.json             # single-plugin fallback marketplace only
├── skills/                          # ONLY promoted skills (discovery root)
│   └── <skill-name>/
│       ├── SKILL.md                 # Agent Skills standard + CC extensions
│       ├── agents/
│       │   └── openai.yaml          # Codex/ChatGPT UI + invocation policy
│       ├── references/              # optional progressive disclosure
│       ├── scripts/                 # optional
│       └── assets/                  # optional
├── drafts/                          # WIP skills; NOT shipped; not under skills/
├── docs/
│   ├── agents/                      # wayfinding ops (existing)
│   └── research/                    # this file and siblings
└── scripts/
    ├── link-skills.sh               # maintainer-only harness linking
    ├── sync-plugin-version.mjs      # optional: package.json → plugin.json version
    └── check-packaging.sh           # validation entrypoint (implement later)
```

**Why flat `skills/<name>/` (not multi-bucket under `skills/`):**

1. **skills CLI** discovers under `skills/` up to three levels deep; a flat one-level layout is unambiguous and matches the common Agent Skills shape.
2. **Claude Code plugins** default-scan `skills/` for `<name>/SKILL.md`. Nested buckets without an explicit path list are easy to mis-ship. An explicit `skills` array of `./skills/<name>` directories remains the promotion gate even when default scan would also work.
3. **Future Codex plugin** can set `"skills": "./skills/"` as a single string and recurse only promoted skills—avoiding Matt Pocock ADR 0002's rejected options (symlink farm dropped on install; duplicate tree; or restructuring mid-life).
4. Domain content stays concise: no parallel `docs/<bucket>/` marketing site is required for v1.

**Drafts:** `drafts/<name>/SKILL.md` (or `.agents/drafts/`). Never place a root-level `SKILL.md` (skills CLI treats a root `SKILL.md` as a single-skill package and can shadow nested discovery unless `--full-depth`).

**Top-level agent docs:** Keep `AGENTS.md` / `CLAUDE.md` as repository rules for contributors working *on* this skillpack, not as installable skills. Matt Pocock's `AGENTS.md -> CLAUDE.md` symlink is a fine ergonomic; optional.

### Generated-versus-authored metadata policy

| Artifact | Policy | Rationale |
| --- | --- | --- |
| `skills/*/SKILL.md` | **Authored** source of truth | Agent Skills standard body + frontmatter (`name`, `description`, optional `license`, `compatibility`, `metadata`; Claude extensions as needed). |
| `skills/*/agents/openai.yaml` | **Authored**, kept in lockstep with invocation frontmatter | Codex UI + `policy.allow_implicit_invocation`. Not inferred at runtime by skills.sh. |
| `skills/*/references|scripts|assets` | **Authored** | Progressive disclosure; scripts validated as real executables when present. |
| `.claude-plugin/plugin.json` `skills` array | **Authored list**, mechanically **checked** against `skills/*` | Explicit promotion gate (README + plugin + filesystem must match). Do not hand-curate a second tree of skill bodies. |
| `.claude-plugin/plugin.json` `version` | **Synced** from `package.json` version | Same invariant as mattpocock/skills; Claude uses plugin version for update visibility. |
| `.claude-plugin/marketplace.json` | **Authored** minimal fallback | Not the documented primary install once an official listing exists; kept for forks and unreleased commits. |
| `package.json` | **Authored**, `"private": true` | Version + description + repository metadata only. No publishConfig, no runtime deps required for v1. |
| `README.md` install block | **Authored single source** (optional extract under `docs/agents/install-block.md`) | One wording for Claude plugin vs skills.sh; “pick one”. |
| skill bodies / indexes from codegen | **Rejected** | No skill compiler, no template expansion pipeline in v1. |
| `skills-lock.json` as distribution format | **Rejected** as authoring/release surface | Consumer-side lock from skills CLI is fine when *they* install; we do not ship or require it. |
| Changesets / automated GitHub Release train | **Optional later**, not a v1 packaging requirement | Version bump can be manual (`package.json` + sync script). |

**Per-skill invocation metadata (authored pair):**

| Kind | `SKILL.md` | `agents/openai.yaml` | Description style |
| --- | --- | --- | --- |
| Model-invoked | omit `disable-model-invocation` (or false) | omit `policy` or `allow_implicit_invocation: true` | Model-facing triggers (“Use when…”). |
| User-invoked | `disable-model-invocation: true` | `policy.allow_implicit_invocation: false` | Human-facing one-liner; no trigger laundry list. |

Mirror Matt Pocock's [invocation](https://github.com/mattpocock/skills/blob/main/.agents/invocation.md) split so Claude and Codex agree on who may fire a skill.

**License metadata:**

- Repository dual license remains **`CC0-1.0 OR Unlicense`** (already in `LICENSE` + `LICENSES/`).
- `package.json` and `.claude-plugin/plugin.json` should carry a dual-license expression compatible with that choice (e.g. `CC0-1.0 OR Unlicense`), not MIT-from-template drift.
- Optional per-skill frontmatter `license: CC0-1.0 OR Unlicense` is allowed by the Agent Skills spec; not required if the repo root license is clear and README states it.

### Validation gates (must pass before merge of packaging/skill changes)

Implement later as `scripts/check-packaging.sh` (or equivalent). Gates:

1. **Agent Skills frontmatter** — every `skills/*/SKILL.md` validates against the open spec (`name`, `description` constraints; `name` equals parent directory basename; no consecutive/leading/trailing hyphens). Prefer the reference validator from agentskills (`skills-ref` / `agentskills` package) when pinned in CI; otherwise equivalent checks.
2. **openai.yaml presence + sync** — every promoted skill has `agents/openai.yaml` with quoted strings; `allow_implicit_invocation: false` **iff** `disable-model-invocation: true` in frontmatter.
3. **Claude plugin strict validate** — `claude plugin validate . --strict` on the repo root (manifest paths, unrecognized fields, metadata).
4. **Promotion triple** — set of directories under `skills/` equals (a) `.claude-plugin/plugin.json` `skills` entries and (b) linked skill entries in top-level `README.md`. No extras, no missing.
5. **Discovery hygiene** — no root `SKILL.md`; no `SKILL.md` under `drafts/` referenced by plugin manifests; `npx skills add . -l` (or clone path) lists exactly the promoted set.
6. **Internal links** — relative links from each `SKILL.md` to sibling references/scripts resolve on disk; prefer one-level-deep references per Agent Skills guidance.
7. **Bundled scripts** — if present: executable bit or documented interpreter invocation; no secrets; fail closed in check script if non-executable shell scripts are claimed as runnable.
8. **Version sync** — `package.json` `version` == `.claude-plugin/plugin.json` `version`.
9. **License intact** — root `LICENSE` still declares `CC0-1.0 OR Unlicense`; both full texts under `LICENSES/`.
10. **Maintainer script safety** — `link-skills.sh` refuses to write if `~/.claude/skills` or `~/.agents/skills` is a symlink into this repo (Matt Pocock guard).

**Not v1 gates:** Anthropic official marketplace acceptance; Codex plugin validate; npm publish; screenshot/visual gates (those belong to skill *content* / issue 10, not packaging layout).

### Maintainer-only symlink conveniences

Ship a script modeled on [mattpocock/skills `scripts/link-skills.sh`](https://github.com/mattpocock/skills/blob/main/scripts/link-skills.sh):

- Discover `skills/**/SKILL.md` (promoted tree only).
- `ln -sfn` each skill directory into `$HOME/.claude/skills/<name>` and `$HOME/.agents/skills/<name>`.
- Document in `AGENTS.md` / `CLAUDE.md` only: **not** a supported end-user installer; modifications for “please also link X” are out of scope for user support.
- Re-run after add/rename/remove of skills; `git pull` then keeps content current because links point into the working tree.

Optional later: also link into `$CODEX_HOME/skills` if a maintainer’s Codex build only watches that tree—but official Codex docs emphasize `~/.agents/skills` for USER scope and `.agents/skills` for REPO scope; skills CLI already installs Codex project skills to `.agents/skills` and global Codex skills to `$CODEX_HOME/skills`.

---

## Evidence by target

### 1. Agent Skills open standard

From [agentskills.io/specification](https://agentskills.io/specification.md):

- A skill is a directory with `SKILL.md` (YAML frontmatter + Markdown body).
- Required frontmatter: `name` (≤64 chars, `[a-z0-9-]+`, no leading/trailing/consecutive hyphens, **must match parent directory name**), `description` (≤1024 chars).
- Optional: `license`, `compatibility`, `metadata` (string→string map), experimental `allowed-tools`.
- Progressive disclosure: metadata always; body on activate; `scripts/` / `references/` / `assets/` on demand. Keep main `SKILL.md` under ~500 lines.
- Validator: reference library under agentskills (`skills-ref` README still documents `skills-ref validate`; published entrypoint may be `agentskills` depending on package build—pin whatever CLI the locked version exposes).

This is the **portable skill body** all harnesses share. Harness-specific files (`disable-model-invocation`, `agents/openai.yaml`) sit beside it without breaking the standard.

### 2. `npx skills` / skills.sh (vercel-labs/skills)

Observed CLI **1.5.22** (`npx skills --help`, package README, source):

**Install:**

```bash
npx skills add XertroV/tm-plugin-skills
npx skills add https://github.com/XertroV/tm-plugin-skills
npx skills add ./tm-plugin-skills          # local / direct git checkout
npx skills add owner/repo --skill name -a claude-code -a codex -g -y
```

**Discovery containers** (walked up to three levels for `SKILL.md`; shallower shadows deeper; `--full-depth` searches outside containers):

- Root (if root `SKILL.md`)
- `skills/`, `skills/.curated/`, `skills/.experimental/`, `skills/.system/`
- Many harness dirs (`.claude/skills`, `.agents/skills`, `.codex/skills`, …)

**Plugin-aware discovery:** `src/plugin-manifest.ts` also reads `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` and adds declared `./…` skill paths (plus conventional `skills/`). Paths must start with `./`.

**Project vs global (examples):**

| Agent | Project | Global |
| --- | --- | --- |
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `$CODEX_HOME/skills` (default `~/.codex/skills`) |
| Universal / many others | `.agents/skills/` | `~/.agents/skills` or agent-specific |
| Grok Build | `.grok/skills/` | `~/.grok/skills/` |

Default install method is **symlink** to a canonical copy; `--copy` duplicates. Telemetry `--metadata` exists; ignore for packaging design.

**Implication:** Author skills under `skills/<name>/SKILL.md`, expose the GitHub repo, and skills.sh covers the multi-agent matrix without per-agent packaging.

### 3. Claude Code plugin metadata

From Claude Code plugins docs/reference and local `claude plugin validate`:

- Manifest at `.claude-plugin/plugin.json`. Only `name` is required if the file exists; ship `version`, `description`, `author`, `repository`, `license`, `keywords`, and component paths for a real release.
- Default skill location: plugin-root `skills/<name>/SKILL.md`.
- Manifest field `skills`: **string or array** of paths starting with `./` (or `"."` / `"./"` for plugin root on recent versions). **Adds to** the default `skills/` scan (unlike `commands`/`agents`, which replace).
- A path may point at a directory that **is** a skill (`…/SKILL.md` inside), enabling explicit lists like Matt Pocock's `"./skills/engineering/tdd"`.
- Plugin skills are **namespaced** in the UI (`/<plugin-name>:<skill>`).
- `disable-model-invocation: true` is the Claude extension for user-only skills.
- Fallback distribution: `.claude-plugin/marketplace.json` with `source: "./"` for repo-as-marketplace; official `claude-plugins-official` listing is separate and pin/sha mediated (Matt Pocock ADR 0002 update, 2026-08-05).
- Validation gate: `claude plugin validate . --strict`.

**v1 choice:** Ship plugin manifests; document skills.sh + plugin as exclusive alternatives; treat official marketplace inclusion as post-v1 distribution polish.

### 4. Codex / OpenAI skill metadata

From [developers.openai.com/codex/skills](https://developers.openai.com/codex/skills.md) and codex repo samples:

**Local load paths (Codex):**

| Scope | Location |
| --- | --- |
| REPO | `.agents/skills` from CWD up to repo root |
| USER | `$HOME/.agents/skills` |
| ADMIN | `/etc/codex/skills` |
| SYSTEM | Bundled |
| (skills CLI global for agent `codex`) | `$CODEX_HOME/skills` ≈ `~/.codex/skills` |

Codex follows **symlinked** skill folders when scanning. Duplicate `name` values are not merged; both may appear.

**`agents/openai.yaml`** (optional but required by our policy for every promoted skill):

```yaml
interface:
  display_name: "Human Title"
  short_description: "25–64 char UI blurb"
  # optional: icon_*, brand_color, default_prompt (must mention $skill-name)
policy:
  allow_implicit_invocation: false   # user-invoked only
# optional dependencies.tools MCP entries
```

Implicit invocation uses `description`; Codex may shorten descriptions under a context budget (≤2% of window or 8k chars for the skills list).

**Native Codex plugin** (deferred): sample `plugin.json` uses `"skills": "./skills/"` as a **string**. Matt Pocock ADR 0002: arrays rejected; symlink trees dropped when Codex copies plugin into cache. Our promoted-only `skills/` tree is the forward-compatible fix without implementing the plugin in v1.

### 5. Direct git use

Supported without registry:

1. Clone → `npx skills add /path/to/clone` (project or `-g`).
2. Clone → `claude --plugin-dir /path/to/clone` or marketplace-add the clone via `.claude-plugin/marketplace.json`.
3. Clone → maintainer `scripts/link-skills.sh`.
4. Consume individual skill paths over git URL forms skills CLI already accepts (`owner/repo/tree/…/skills/name`).

No submodule, subtree, or sparse-checkout requirement for v1.

### 6. Matt Pocock ergonomics (adopt / adapt / reject)

| Practice | Adopt? | Notes for this repo |
| --- | --- | --- |
| Small composable skills + progressive disclosure | **Adopt** | Aligns with map and Agent Skills. |
| Two install philosophies (plugin subscribe vs skills.sh own) | **Adopt** | Document exclusive choice. |
| `.claude-plugin/plugin.json` + fallback marketplace.json | **Adopt** | Explicit `skills` array as promotion gate. |
| `package.json` private + version sync into plugin.json | **Adopt** | No npm publish. |
| `agents/openai.yaml` + invocation split | **Adopt** | Every promoted skill. |
| `scripts/link-skills.sh` maintainer-only | **Adopt** | Same destinations + safety guard. |
| Promotion rules in AGENTS/CLAUDE (README + plugin list) | **Adopt** | Triple-check with filesystem. |
| Bucket folders under `skills/` (`engineering/`, `misc/`, …) | **Adapt → reject nesting under discovery root** | Greenfield: promoted-only flat `skills/`; WIP in `drafts/`. Avoids Codex single-path pain and accidental draft install. |
| Changesets + changelog automation | **Defer** | Optional; not required to install or validate. |
| Parallel public docs site (`docs/<bucket>/<skill>.md`) | **Defer** | Domain skillpack can live on README + skill bodies. |
| Native Codex plugin deferred with ADR | **Adopt decision** | Same deferral; layout leaves door open. |
| MIT license | **Reject** | Keep **CC0-1.0 OR Unlicense**. |
| Router skill (`ask-matt`) | **Out of scope for packaging ticket** | Content/catalog decision elsewhere. |

---

## Rejected machinery (explicit)

Do **not** take on for v1 packaging:

1. **npm/pypi/crates publish** as an install channel.  
2. **Native Codex plugin** packaging and App Store–style plugin UX.  
3. **Duplicate skill trees** or generated flat copies for multi-manifest satisfaction.  
4. **Symlink farms committed in-repo** for Codex (broken on plugin copy).  
5. **Root-level single-skill `SKILL.md`** layout for a multi-skill pack.  
6. **Shipping drafts** under `skills/` (including `skills/.experimental` unless deliberately opted into skills CLI discovery).  
7. **Requiring** Anthropic official marketplace listing before calling packaging done.  
8. **skills-lock.json**, `experimental_install`, or `experimental_sync` as author-side release tools.  
9. **Monorepo / multi-package** workspace.  
10. **Homebrew, Docker images, install.ps1 frameworks, git submodules.**  
11. **Codegen of SKILL.md** from another IDL.  
12. **CI release trains, changesets, semantic-release** as blockers (manual version bump + sync script is enough).  
13. **Committing consumer harness dirs** (`.claude/skills`, `.agents/skills`) inside this repo for end users.  
14. **Dual-install without warning** (plugin + skills.sh).  
15. **Replacing dual public-domain licensing** with MIT/Apache “for package managers.”

---

## Canonical install wording (draft for future README)

> **Pick one.**  
>  
> **Claude Code (managed plugin):** once manifests exist — install via Claude’s plugin flow for this repository (official marketplace if listed; otherwise `marketplace add` of this git URL + install from the repo’s single-plugin marketplace). Updates follow the plugin channel.  
>  
> **Codex and everyone else (editable files):**  
> `npx skills@latest add XertroV/tm-plugin-skills`  
> Choose skills and agents when prompted (or `--all` / `-a` / `-s`).  
>  
> **Direct git:** clone this repository, then `npx skills add ./tm-plugin-skills` or point Claude at the checkout with `--plugin-dir`.  
>  
> Maintainers hacking on the pack: `scripts/link-skills.sh` (unsupported for end users).

Exact command strings should be centralized (Matt-style install-block file) when packaging is implemented.

---

## Mapping back to issue 1 constraints

| Map constraint | How this research satisfies it |
| --- | --- |
| Portable default; plugin folder rooted at `info.toml` is about **target plugins**, not this skillpack | Skillpack installs into agent harness dirs; it does not need to live under Openplanet `Plugins/`. |
| Detect capabilities rather than assume toolchains | Packaging adds no hard dependency on Openplanet, RemoteBuild, or MCP; optional MCP only inside individual `openai.yaml` later if a skill needs it. |
| Concise, opinionated, progressive disclosure | Flat Agent Skills layout + references/; no heavy release monorepo. |
| `CC0-1.0 OR Unlicense` | Retained; dual-license metadata on manifests; MIT-from-template rejected. |
| Final directory/package metadata after distribution research | This document is that decision input. |

---

## Implementation handoff (out of scope for this ticket)

When a later **task** ticket implements packaging (not this research commit):

1. Add `package.json` (`private: true`, version `0.1.0`, license expression, repository URL).  
2. Add `.claude-plugin/plugin.json` + `marketplace.json`.  
3. Create `skills/` and `drafts/` placeholders as skills are promoted.  
4. Add `scripts/link-skills.sh`, `sync-plugin-version.mjs`, `check-packaging.sh`.  
5. Wire CI to `check-packaging.sh` + `claude plugin validate . --strict`.  
6. Replace README install stub with the canonical block.  
7. Do **not** add `.codex-plugin/` until a dedicated decision revisits the Codex plugin.

---

## Source index (URLs and local observations)

- https://agentskills.io/llms.txt  
- https://agentskills.io/specification.md  
- https://github.com/agentskills/agentskills (docs + skills-ref)  
- https://github.com/vercel-labs/skills (CLI 1.5.22; README discovery tables; `src/agents.ts`, `src/plugin-manifest.ts`)  
- `npx skills --help` / `npm view skills` (2026-08-11)  
- https://code.claude.com/docs/en/skills.md  
- https://code.claude.com/docs/en/plugins.md  
- https://code.claude.com/docs/en/plugins-reference.md  
- `claude plugin validate --help` (strict mode)  
- https://developers.openai.com/codex/skills.md  
- https://github.com/openai/codex — `codex-rs/skills/src/assets/samples/skill-creator/references/openai_yaml.md`, `…/plugin-creator/references/plugin-json-spec.md`  
- https://github.com/mattpocock/skills — README install sections, `AGENTS.md`/`CLAUDE.md`, `.claude-plugin/*`, `.agents/adr/0002-ship-as-a-claude-code-plugin.md`, `.agents/install-block.md`, `.agents/invocation.md`, `scripts/link-skills.sh`, `scripts/sync-plugin-version.mjs`  
- Repo: `LICENSE` (`SPDX-License-Identifier: CC0-1.0 OR Unlicense`)

---

## Decision summary (for the ticket resolution comment, when a human/session closes issue 7)

**v1 officially supports:** (1) `npx skills@latest add` / skills.sh across Agent Skills–compatible agents, (2) Claude Code native plugin manifests with fallback repo marketplace, (3) direct git clone consumption, (4) per-skill Codex `agents/openai.yaml` metadata.  

**v1 layout:** promoted-only flat `skills/<name>/`; drafts outside; dual license retained; private `package.json` version + `.claude-plugin/plugin.json`; maintainer `link-skills.sh` only.  

**v1 does not ship:** npm publish, native Codex plugin, committed symlink farms, draft skills under discovery roots, or heavy release automation.  

**Metadata:** author skill bodies and openai.yaml; author plugin skill list; sync plugin version from package.json; validate with Agent Skills checks + `claude plugin validate --strict` + promotion triple + link/script gates.
