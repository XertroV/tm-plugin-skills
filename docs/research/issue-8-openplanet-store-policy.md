# Issue 8 — Openplanet store policy and publication constraints

**Ticket:** [Research the Openplanet store policy and publication constraints](https://github.com/XertroV/tm-plugin-skills/issues/8)
**Parent map:** [Chart the implementation-ready specification for the Openplanet agent skillpack](https://github.com/XertroV/tm-plugin-skills/issues/1)
**Research retrieved (UTC):** 2026-08-11T13:31:48Z
**Method:** Read-only fetch of public primary pages on `https://openplanet.dev` (no login, no upload, no admin UI).
**Out of scope (per map):** Performing store submission.

This brief is an agent-facing pre-code compatibility gate. It separates (1) rules that should shape **every** plugin design, (2) constraints that apply only when **publication/signing** is intended, (3) **local-only** exceptions that must be labelled non-publishable, and (4) facts resolved by the later read-only plugin-owner inspection in [the owner workflow research](issue-9-plugin-owner-admin-workflow.md).

---

## 1. Authority and source map

Prefer these in order. Relative “page updated / posted” stamps are from the live HTML `title` attributes at research time.

| Rank | Source | URL | Page stamp (source HTML) | Role |
|------|--------|-----|--------------------------|------|
| 1 | Plugin terms of service | https://openplanet.dev/docs/plugin-tos | Updated 2026-06-07 by Miss | **Canonical upload/approval rules** |
| 2 | Signature modes | https://openplanet.dev/docs/tutorials/signature-modes | Updated 2026-07-19 by Miss | What “signed / school / developer” means at load time |
| 3 | School mode | https://openplanet.dev/docs/school-mode | Updated 2024-08-09 by Miss | Competitive-integrity boundary for helpers |
| 4 | School mode for developers | https://openplanet.dev/user/trusted | Public at research time | Folder vs `.op`, whitelist maps, trusted-dev path |
| 5 | `info.toml` reference | https://openplanet.dev/docs/reference/info-toml | Updated 2026-05-16 by Miss | Metadata required for site submission |
| 6 | Permissions API | https://openplanet.dev/docs/api/Permissions | Live API docs (no “page updated” stamp extracted) | Paid-feature gate API referenced by ToS |
| 7 | Authentication API | https://openplanet.dev/docs/reference/auth | Updated 2024-10-21 by Miss | Site plugin + admin auth prerequisites |
| 8 | Installing plugins | https://openplanet.dev/docs/tutorials/installing-plugins | Updated 2022-08-13 by tooInfinite | `.op` manager path, signature error classes |
| 9 | Privacy policy | https://openplanet.dev/privacy | Updated 2026-04-12 by Miss | Login, review email, trusted-dev public linkage |
| 10 | Plugin Signature Feed | https://openplanet.dev/plugins/signs | Live feed | Observable review action types |
| 11 | Trusted Developer List | https://openplanet.dev/users/trusted | Live list | Public trusted-dev roster (volatile) |
| 12 | Competition Profiles | https://openplanet.dev/competitions | Live | Dynamic competition signature modes |
| 13 | News: Developer Mode | https://openplanet.dev/news/2022/developer-mode | Posted 2022-07-17 | Unsigned load requires developer mode |
| 14 | News: School Mode | https://openplanet.dev/news/2024/introducing-school-mode | Posted 2024-10-01 | Policy intent for SD helpers |
| 15 | News: visual SD helpers | https://openplanet.dev/news/2022/allowing-visual-sd-helpers | Posted 2022-11-16 | Historical policy; delayed then superseded by school mode |
| 16 | News: API endpoint move | https://openplanet.dev/news/2026/updated-plugin-api-endpoints | Posted 2026-01-27 | Auth/config base URL migration |
| 17 | Example school plugin page | https://openplanet.dev/plugin/schoolexample | Live listing | Public “signed for School Mode” wording |

There is **no** public page at `/store`. The public catalog is `/plugins`; distribution is the website + in-game plugin manager. Site chrome also links `openplanet.nl` as an alias host in some redirects.

**Contact channels cited by primary docs (not used in this research):** Discord staff; `miss@openplanet.dev`; `team@openplanet.dev` (school feedback); `competitions@openplanet.dev` (competition profiles).

---

## 2. Pre-code compatibility gate (all plugins)

Apply these **before writing feature code**, even for local-only work. The upload ToS legally attaches at upload, but the skillpack deliberately adopts the constraints below as its stricter universal product policy because they are hard to retrofit and protect players, authors, reviewers, and the community. Do not misstate that broader skillpack policy as the legal scope of the upload agreement.

### 2.1 Hard product/legal constraints (ToS-shaped)

From [Plugin terms of service](https://openplanet.dev/docs/plugin-tos):

1. **Copyright / third-party ownership** — Do not ship material (code, assets, other people’s plugins) without permission.
2. **No paid-feature bypass** — Do not unlock Club/Standard/paid game capabilities the user does not own. Gate paid surfaces with the [Permissions API](https://openplanet.dev/docs/api/Permissions) (ToS links “permission checks”).
3. **No full-leaderboard bulk scraping from the client** — Plugins that “request full leaderboards (or similar information)” are not approved because of request volume. If the product needs that data, design a **separate caching server**; the plugin consumes the cache.
4. **No cryptocurrency features** — Anything crypto-related is barred from the website; avoid building it into a shared codebase you might later publish.
5. **No NSFW** — Same as above for content policy.
6. **AI-generated bulk** — “Plugins which are mostly AI generated are not allowed.” Other AI usage “must be disclosed during plugin review as well as publicly using the AI classification settings.” Reviewers may reject work that appears largely AI-generated. **Design implication:** keep human-authored structure, tests, and reviewable diffs; plan disclosure if AI-assisted.
7. **Stability / community harm** — Openplanet may unpublish plugins deemed damaging (explicitly includes game instability). Prefer fail-safe defaults, timeouts, and no reckless memory patching in default paths.

### 2.2 Runtime integrity / competitive boundaries

From [Signature modes](https://openplanet.dev/docs/tutorials/signature-modes), [School mode](https://openplanet.dev/docs/school-mode), and [School mode for developers](https://openplanet.dev/user/trusted):

8. **Classify helper / advantage features early** — Tools that indicate perfect speed-drift / ice-slide inputs (and similar competitive helpers) are **not** free-for-all “regular” features. School mode exists specifically to host practice/accessibility helpers without online play or official leaderboard submits (with whitelist exceptions).
9. **Unsigned code implies Developer mode (+ School mode)** — Developer mode loads unsigned plugins and **also enables school mode** (leaderboard/online restrictions for non-trusted developers, except whitelisted maps). Local folder plugins are the normal dev form; do not assume end users can load unsigned code in Regular mode.
10. **Plugin ID = folder / `.op` filename** — `Plugins/Example/` and `Plugins/Example.op` share ID `Example`. Signature mode decides precedence: Developer prefers folder; otherwise prefers packaged `.op`.
11. **Do not set `meta.essential = true` without a strong reason** — Users cannot disable essential plugins ([info.toml](https://openplanet.dev/docs/reference/info-toml)).
12. **Do not set `script.controls_other_plugins = true` without a strong reason** — Suppresses user warnings when disabling other plugins ([info.toml](https://openplanet.dev/docs/reference/info-toml)).
13. **Prefer Permissions API over deprecated `meta.perms`** — `perms` (`free` / `paid` / `full`) is documented as deprecated ([info.toml](https://openplanet.dev/docs/reference/info-toml)).

### 2.3 Minimum metadata hygiene (cheap, always)

Even for local plugins, keep a valid modern plugin folder:

- Rooted at `info.toml` with a real `meta.version` string (site submission **requires** version; runtime defaults missing version to `1.0` but docs still mark it required for submission) ([info.toml](https://openplanet.dev/docs/reference/info-toml)).
- Recommended: `name`, `author`, `category` (prefer categories already used by other plugins).
- Set `game.min_version` / `max_version` / `supported_games` only when needed; empty `supported_games` means all games ([info.toml](https://openplanet.dev/docs/reference/info-toml)).
- Keep `script.timeout` sane (0 disables timeout and infinite-loop protection).

### 2.4 One-screen checklist (all plugins)

```
[ ] Own or have permission for all code/assets
[ ] Paid game features gated via Permissions::* (no edition bypass)
[ ] No client-side full-leaderboard (or similar) hammering; server cache if needed
[ ] No crypto; no NSFW
[ ] AI assistance planned for disclosure if ever published; not "mostly AI"
[ ] Competitive helpers classified as school-mode candidates, not silent regular features
[ ] essential / controls_other_plugins left false unless justified
[ ] info.toml version/name/author present; deprecated meta.perms avoided
[ ] Failure modes will not brick game sessions (unpublish risk)
```

---

## 3. Publication-only constraints

These apply when the author intends website listing, plugin-manager install, and/or a **signed** build for non-developer players. Signing/review is how plugins enter Regular (or School) signature mode ([Signature modes](https://openplanet.dev/docs/tutorials/signature-modes); [Developer Mode news](https://openplanet.dev/news/2022/developer-mode)).

### 3.1 Agreement surface

Uploading agrees to the [Plugin terms of service](https://openplanet.dev/docs/plugin-tos): display/share rights for Openplanet; possible forced `siteid`/identifier change; unpublish rights for harm/instability.

### 3.2 Review & signing

- **Regular signed plugins** are reviewed/approved against the ToS, then loadable in default Regular mode ([Signature modes](https://openplanet.dev/docs/tutorials/signature-modes)).
- **School signed plugins** only run under School (or Developer) mode. Public example: [School Example](https://openplanet.dev/plugin/schoolexample) states it is “signed for School Mode” and will not allow online play / official leaderboard times in that mode.
- Observable public review actions on the [Plugin Signature Feed](https://openplanet.dev/plugins/signs) include types such as `review_sign_regular_approve` (live feed entries at research time; action vocabulary is volatile).
- Historical note: unsigned website uploads were pushed toward signing via plugin admin (“upload a new version … mark that you want it to be signed”) ([Developer Mode news](https://openplanet.dev/news/2022/developer-mode)). Exact current admin controls need authenticated inspection (§5).

### 3.3 Packaging & manager

- Plugin manager installs **modern `.op` plugins** only, not legacy loose script files ([Installing plugins](https://openplanet.dev/docs/tutorials/installing-plugins)).
- Manual install: `.op` → user `Plugins/`; legacy `.as` (+ optional `.sig`) → `Scripts/` ([Installing plugins](https://openplanet.dev/docs/tutorials/installing-plugins)).
- Signature-related runtime errors documented for scripts: missing signature, invalid signature, insufficient game-edition permissions, game-version incompatibility ([Installing plugins](https://openplanet.dev/docs/tutorials/installing-plugins)).

### 3.4 Site metadata & identity

From [info.toml](https://openplanet.dev/docs/reference/info-toml) and public plugin pages (e.g. [Dashboard](https://openplanet.dev/plugin/dashboard), [Better TOTD](https://openplanet.dev/plugin/bettertotd)):

| Field / concept | Publication note |
|-----------------|------------------|
| `meta.version` | Required for successful website submission |
| `meta.siteid` | Numeric site ID; used for updates + Auth API. Review process can inject it automatically unless Auth API needs it early |
| Public Identifier | Folder/`.op` ID (e.g. `Dashboard`, `SchoolExample`) |
| Public Numeric ID | Site ID shown on plugin page |
| Min. Openplanet | Listing field on plugin pages |
| Games | Listing can span Trackmania / Maniaplanet 4 / Turbo |
| Featured | Site may feature plugins (ToS usage grant) |
| Source / issues links | Common on listings; not ToS-mandated in the short ToS text |

### 3.5 AI disclosure (publish path)

ToS requires AI disclosure **during review** and **publicly via AI classification settings**. Exact enum/UI values were **not** visible on sampled public plugin pages at research time → admin inspection (§5).

### 3.6 Auth API (only if used)

From [Authentication API](https://openplanet.dev/docs/reference/auth):

- Plugin must already exist on the website.
- Enable authentication in plugin **admin** Authentication tab.
- Put `siteid` in `info.toml`.
- Validate tokens server-side (`/api/auth/validate`; preferred host migration noted below).
- Intermediate tokens are short-lived (~5 minutes at doc writing; volatile).
- Abuse may disable a plugin’s auth access.

Preferred endpoints after 2026-01 migration ([API endpoints news](https://openplanet.dev/news/2026/updated-plugin-api-endpoints)):

- Auth validate: `https://api.openplanet.dev/auth/validate` (old `https://openplanet.dev/api/auth/validate` kept “for a good while”)
- Plugin config: `https://api.openplanet.dev/plugin/<id>/config/<name>`

### 3.7 Account prerequisites (publish path)

From [Privacy policy](https://openplanet.dev/privacy) and site login chrome:

- Site login via **GitHub and/or Codeberg**.
- Email used for **plugin review notifications**.
- Connecting game accounts may surface publicly if the user is a trusted developer.

### 3.8 Publication-only checklist

```
[ ] ToS acceptable (display rights, identifier change, unpublish)
[ ] Not mostly AI; AI classification + review disclosure prepared
[ ] Signed target chosen: Regular vs School
[ ] .op package path; manager-compatible
[ ] meta.version set; name/author/category polished
[ ] siteid/Auth plan if using Auth API or update checks
[ ] No ToS-prohibited features (copyright, NSFW, paid bypass, bulk LB, crypto)
[ ] Stability bar suitable for public installs
```

---

## 4. Legitimate local-only development

`local-only` / `do-not-publish` describes a distribution decision, not a waiver from safety, rights, integrity, or the skillpack's non-deception policy. The skillpack may assist legitimate unsigned development and remediation, but must refuse work that facilitates infringement, paid-feature bypass, harmful exploitation, review evasion, prohibited bulk scraping, or false disclosure.

| Exception class | Why non-publishable | Runtime reality |
|-----------------|---------------------|-----------------|
| **Unsigned folder plugins** | Not signed; Regular mode users will not load them | Requires Developer mode ([Signature modes](https://openplanet.dev/docs/tutorials/signature-modes); [Developer Mode news](https://openplanet.dev/news/2022/developer-mode)). Club edition required for unsigned per that news. |
| **Policy-remediation prototypes** | Existing work may need prohibited material removed, permissions added, provenance repaired, scraping redesigned, or AI usage truthfully disclosed | Assistance is limited to diagnosis and remediation; local-only status never authorizes the prohibited behavior |
| **Unapproved competitive helpers intended for ranked/online play** | School mode / competition integrity policy | Practice helpers belong in **School** signing, not silent Regular features ([School mode](https://openplanet.dev/docs/school-mode)) |
| **Trusted-dev-only workflows** | Depend on personal trusted flag / abuse risk | Trusted status is case-by-case; abuse → revoke + ban risk ([user/trusted](https://openplanet.dev/user/trusted)) |
| **Breakage / exploit probes** | Unpublish + community harm; school bypasses must be reported privately | School-mode bypasses: confidential email to Miss per [school developer preview news](https://openplanet.dev/news/2024/school-mode-developer-preview) |
| **Auth-secret or admin-only tooling** | Secrets and admin surfaces are not plugin payload | Auth secrets live in plugin admin ([Auth API](https://openplanet.dev/docs/reference/auth)) |

**Labelling recommendation for the skillpack (non-normative to Openplanet):** legitimate unsigned or private work may use `publication: none` / `local-only: true`. If work conflicts with §2, refuse enabling assistance and offer remediation; do not use a local-only marker to launder it into an acceptable state.

**Allowed local pattern that is still publishable later:** develop as `Plugins/<ID>/` folder; optionally install signed `.op` of same ID for non-dev testing. Mode decides which wins ([user/trusted](https://openplanet.dev/user/trusted)).

---

## 5. Facts requiring read-only authenticated admin inspection

Do **not** invent these. A later read-only logged-in pass (no submit) should capture screenshots/notes from plugin admin + account settings.

| # | Fact gap | Why it matters | Likely surface |
|---|----------|----------------|----------------|
| A | **Exact upload / version / “request signing” controls** | Publish skill completion gates | Plugin admin (historical “mark that you want it to be signed” — [Developer Mode news](https://openplanet.dev/news/2022/developer-mode)) |
| B | **AI classification settings** — field names, allowed values, where public disclosure appears | ToS-mandated public disclosure; not visible on sampled public plugin pages | Plugin admin + public listing rendering |
| C | **Review workflow states** (pending, changes requested, rejected reasons, SLA) | Agent expectations while waiting | Plugin admin + review notification emails |
| D | **Signer roles / who can `review_sign_*`** | Trust model; feed shows Miss, Fort-TM, etc. | Admin + [Signature Feed](https://openplanet.dev/plugins/signs) correlation |
| E | **School vs Regular signing request flags** | Choosing correct signature class at upload | Plugin admin create/version form |
| F | **Auth tab**: secret issuance, rotation, enable/disable | Auth API plugins | Plugin admin Authentication tab ([Auth API](https://openplanet.dev/docs/reference/auth)) |
| G | **`siteid` assignment timing** vs first upload | When `info.toml` must gain `siteid` | Admin URL / public “Numeric ID” |
| H | **Trusted developer application form** fields and approval criteria in practice | Only guidelines are public | https://openplanet.dev/user/trusted (form requires login) |
| I | **Current whitelisted map set** beyond “Openplanet School Campaign” | Dev play outside school restrictions | Trusted/school docs + club campaign links (partially public) |
| J | **Competition Profile admin** rule language (`allow` lists, extra restrictions) | Competition-safe plugin advice | https://openplanet.dev/competitions + admin (login) |
| K | **Edition-specific signing** (Starter vs Standard vs Club) current UI/policy | “Insufficient permissions” class errors | Admin signing options + [Installing plugins](https://openplanet.dev/docs/tutorials/installing-plugins) |
| L | **Featured selection criteria** | Marketing, not correctness | Editorial / admin |
| M | **Account privacy settings** affecting public profile | Author identity on listings | Account settings ([Privacy](https://openplanet.dev/privacy)) |
| N | **Live API base URLs shown on admin dashboard** | Endpoint migration already announced | Plugin admin dashboard ([API endpoints news](https://openplanet.dev/news/2026/updated-plugin-api-endpoints)) |

---

## 6. Distribution model (context for agents)

```
Author source folder  Plugins/<ID>/     → Developer mode (unsigned OK; school restrictions apply unless trusted)
        │
        ▼  review + sign (website admin; out of scope to perform)
Signed .op on openplanet.dev/plugins
        │
        ├─ Regular signature → loads in Regular + School + Developer
        └─ School signature  → loads in School + Developer (not normal Regular play)
        │
        ▼
In-game Plugin Manager (.op only) / manual Plugins/ install
        │
Competition Profiles → alternate dynamic allow-lists for events
Official mode → shipped Openplanet plugins only
```

**Trusted developers** may bypass school restrictions from developer mode; status is public on [/users/trusted](https://openplanet.dev/users/trusted); abuse risks revocation and broader bans ([user/trusted](https://openplanet.dev/user/trusted)).

---

## 7. Volatile facts (timestamped)

Re-check before baking into long-lived skills:

| Fact | As of research UTC 2026-08-11 | Source |
|------|-------------------------------|--------|
| Plugin ToS text (AI rule, crypto, LB, NSFW, copyright, paid bypass) | Present; page updated **2026-06-07** | ToS |
| Signature mode definitions | Page updated **2026-07-19** | Signature modes |
| Auth token lifetime “5 minutes” | Documented as of **2024-10-21**; may change | Auth API |
| Auth/config API hosts | New `api.openplanet.dev` preferred since **2026-01-27**; old hosts retained temporarily | API endpoints news |
| School mode GA | Openplanet **1.27+** era; docs **2024-08/10** | School mode + news |
| Visual SD helper “allow on manager” announcement | **2022-11-16**, then **delayed**; later school-mode regime is the durable policy | SD helpers news + school mode |
| Signature feed action type seen | `review_sign_regular_approve` dominant in recent entries | Signature feed |
| Trusted developer roster | Live list; entries change (e.g. last ticket times on page) | Trusted list |
| Competition “Generic Competition” allow-list | Empty at research time | Competitions |
| Sample school plugin | `SchoolExample` siteid **602**, school-signed | School Example page |

---

## 8. Implications for the skillpack (non-decision)

These are research conclusions for downstream tickets, not product decisions:

1. A **pre-code gate skill/section** should encode §2 checklist for every new plugin, independent of publish intent.
2. A **publish readiness** gate should add §3 and refuse ToS-violating or unsigned-only designs unless labelled §4.
3. **School vs Regular** is a first-class product choice for any input helper / competitive-adjacent feature.
4. **Store submission automation** remains out of map scope; at most, skills may prepare metadata and point humans at admin UI after §5 is filled.
5. Do not hardcode trusted-dev assumptions; detect or ask.

---

## 9. Citations (primary)

1. Openplanet, *Plugin terms of service*, https://openplanet.dev/docs/plugin-tos — retrieved 2026-08-11; HTML page updated 2026-06-07 (Miss).
2. Openplanet, *Signature modes*, https://openplanet.dev/docs/tutorials/signature-modes — retrieved 2026-08-11; HTML page updated 2026-07-19 (Miss).
3. Openplanet, *School mode*, https://openplanet.dev/docs/school-mode — retrieved 2026-08-11; HTML page updated 2024-08-09 (Miss).
4. Openplanet, *School mode for developers / trusted developer*, https://openplanet.dev/user/trusted — retrieved 2026-08-11 (public body; application form login-gated).
5. Openplanet, *info.toml reference*, https://openplanet.dev/docs/reference/info-toml — retrieved 2026-08-11; HTML page updated 2026-05-16 (Miss).
6. Openplanet, *Permissions namespace*, https://openplanet.dev/docs/api/Permissions — retrieved 2026-08-11.
7. Openplanet, *Authentication API*, https://openplanet.dev/docs/reference/auth — retrieved 2026-08-11; HTML page updated 2024-10-21 (Miss).
8. Openplanet, *Installing plugins*, https://openplanet.dev/docs/tutorials/installing-plugins — retrieved 2026-08-11; HTML page updated 2022-08-13 (tooInfinite).
9. Openplanet, *Privacy Policy*, https://openplanet.dev/privacy — retrieved 2026-08-11; HTML page updated 2026-04-12 (Miss).
10. Openplanet, *Plugin signs* (signature feed), https://openplanet.dev/plugins/signs — retrieved 2026-08-11.
11. Openplanet, *Trusted developers*, https://openplanet.dev/users/trusted — retrieved 2026-08-11.
12. Openplanet, *Competition Profiles*, https://openplanet.dev/competitions — retrieved 2026-08-11.
13. Miss, *Introducing "Developer Mode"*, https://openplanet.dev/news/2022/developer-mode — posted 2022-07-17.
14. Miss, *Introducing School Mode*, https://openplanet.dev/news/2024/introducing-school-mode — posted 2024-10-01.
15. Miss, *Allowing visual SD helpers*, https://openplanet.dev/news/2022/allowing-visual-sd-helpers — posted 2022-11-16 (policy delayed in-page).
16. Miss, *Developer preview for School Mode*, https://openplanet.dev/news/2024/school-mode-developer-preview — posted 2024-08-10.
17. Miss, *Updated plugin API endpoints*, https://openplanet.dev/news/2026/updated-plugin-api-endpoints — posted 2026-01-27.
18. Openplanet, *School Example* plugin page, https://openplanet.dev/plugin/schoolexample — retrieved 2026-08-11.
19. Openplanet, *Dashboard* plugin page, https://openplanet.dev/plugin/dashboard — retrieved 2026-08-11 (listing field inventory; changelog notes school-restricted speed style).
20. Openplanet, *Documentation* index / footer transparency links, https://openplanet.dev/docs — retrieved 2026-08-11.

---

## 10. Explicit non-actions (this research)

- Did not log in, authenticate, or open plugin admin.
- Did not upload, sign, submit, or modify any plugin listing.
- Did not close or edit GitHub issues.
- Did not implement skillpack behavior.
