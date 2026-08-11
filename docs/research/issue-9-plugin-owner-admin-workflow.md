# Openplanet plugin-owner administration workflow

**Inspected:** 2026-08-11
**Scope:** Authenticated, read-only inspection of ordinary owner-facing pages for one existing plugin on `openplanet.dev`.
**Excluded:** Reviewer menus, reviewer queues/pages, reports, moderation controls, credentials, secret values, and all state-changing actions.

## Method and evidence boundary

A user-authenticated, visible Chromium session was attached to Playwright over local CDP. The inspection used direct GET navigation and accessibility-tree snapshots only. No controls were clicked, no fields were changed, and no forms were submitted. Temporary snapshots and screenshots were deleted after extracting the non-sensitive workflow facts below.

The inspected owner navigation exposed these areas:

- dashboard and public page;
- information, supported games, images, configs, and authentication;
- all versions and upload new version;
- history and authors.

A reviewer-only navigation section was visible in the shared page chrome. It was not opened or investigated and is outside this document.

## Owner workflow

### 1. Create and maintain store information

The **Information** page contains:

| Field | Help or validation signal |
| --- | --- |
| Plugin name | Owner-editable text field. |
| Short description | “Provide a short description of what your plugin does.” |
| Description | Longer Markdown-capable description. |
| Source code URL | Optional HTTPS link to a source repository such as GitHub or GitLab. |
| Issue reporting URL | Optional HTTPS link where users can report issues. |

A single **Save** action applies information changes. This inspection did not test required fields, length limits, URL rejection behavior, or server-side error messages.

### 2. Declare supported games

The **Supported games** page lists current games and allows owners to add another from:

- Maniaplanet 4;
- Trackmania Turbo;
- Trackmania;
- TrackMania Forever.

The page explicitly warns: **“Make sure you only add games that you have tested!”** Existing entries have a removal control. Neither add nor remove behavior was exercised.

### 3. Supply store images

The **Images** page separates:

- **Main image** — shown in the plugin list and plugin manager; uploaded images are resized to fit **960 × 540**.
- **Screenshots** — optional showcase images; uploads are rescaled to fit **1600 × 900**, with a stated maximum of **8 images at a time**.

Each screenshot has a description field identified as **“Description of image (for screen reader accessibility)”**, plus Update and Remove actions. This makes useful alt text an explicit owner responsibility.

### 4. Maintain public runtime configuration

The **Configs** page describes named JSON blobs that a plugin can fetch to update frequently changing state without uploading a new plugin version.

Policy and runtime signals shown in the owner UI:

- config data is public and must contain **no secrets**;
- the endpoint is intended for Openplanet user agents and does not work as an ordinary browser URL;
- plugin code should request it through `Net::HttpRequest`;
- the owner surface provides New, Edit, and Delete operations and shows each config's name, last update, and API URL.

The existing config contents and action URLs were deliberately not retained. New/Edit/Delete were not opened.

### 5. Optionally enable Openplanet Authentication

The **Authentication** page explains that Openplanet's authentication API can authenticate a user's account ID to a third-party API with zero user interaction while preserving security and privacy. It links to the public authentication reference and an example plugin/server.

The owner control is an **Enable authentication** checkbox followed by **Save**. It was left unchanged. No secret, credential, token, callback configuration, or enabled-state detail was inspected.

### 6. Upload a version for review

The **Upload new version** page contains:

| Field/control | Owner-facing rule or help |
| --- | --- |
| Plugin file | Accepts `.op` or `.zip`; maximum **20 MB**; `info.toml` must be at the ZIP root. |
| Changes since previous version | Markdown-capable changelog. |
| Minimum Openplanet version | Optional; example format `1.24.0`; the page advises leaving it alone if unsure. The current plugin's prior minimum is prefilled. |
| Reviewer note | Optional and visible only to plugin reviewers. |
| Generative-AI disclosure | Checkbox stating that the version contains code or content created using generative AI. |
| Automatic publication | Optional checkbox to publish automatically after approval. |
| Terms attestation | Checkbox affirming that the version follows the plugin terms of service. |

The AI disclosure help explicitly includes AI code completion beyond ordinary autocomplete, coding agents, copied LLM output, generated assets, and similar usage. The form therefore asks for a binary per-version disclosure rather than a category picker in the ordinary owner flow.

The terminal action is labeled **Save**. Because it includes a plugin file, review metadata, policy attestations, and optional post-approval publication, agents must treat it as a submission boundary—not as a harmless draft-save action. It was not triggered.

### 7. Observe version state without entering reviewer pages

The **All versions** table exposes these owner-visible columns:

- Version;
- Downloads;
- Minimum Openplanet version;
- Review status;
- Signed;
- Published;
- Actions.

Observed historical rows demonstrate:

- **Approved** as a review state, with a timestamp;
- **Regular** as a signing classification;
- signed and published as separate status columns;
- owner-accessible download and edit links.

Some rows also render links into reviewer routes because the authenticated user has reviewer permissions. Those links were not opened, and this research does not describe their content or behavior. Other review states, School signing, rejection/requested-changes feedback, manual publication controls, and edit constraints after submission remain unverified in the ordinary owner pages inspected.

### 8. Audit history

The **History** page is an owner-visible audit log with:

- time;
- action;
- note;
- user.

Its entries show the lifecycle as distinct events rather than one atomic upload: adding/editing a version, beginning review, approving a regular signature, CDN upload, and publication. This is historical owner-visible evidence only; reviewer behavior was not inspected.

### 9. Manage collaborators

The **Authors** page lists authors and supports invitations by username. It warns that:

- an added author can access the plugin admin panel;
- the plugin appears on the additional author's profile;
- additional authors are displayed as plugin authors;
- invitees must approve authorship;
- owners should be careful whom they invite.

The invitation action is **Send author invite**. No username was entered and no invitation was sent.

## Pre-code compatibility gate informed by the owner UI

Before implementing a plugin intended for publication, an agent should establish:

1. **Artifact shape:** produce `.op` or `.zip`, stay below 20 MB, and keep `info.toml` at the ZIP root.
2. **Store metadata:** prepare a concise summary, Markdown description, and optional HTTPS source/issue URLs.
3. **Game support:** declare only games that have actually been tested.
4. **Visual assets:** provide a 16:9 main image suitable for 960 × 540, optional screenshots suitable for 1600 × 900, and accessible descriptions.
5. **Runtime compatibility:** determine and test the minimum Openplanet version rather than guessing it.
6. **Change communication:** prepare a Markdown changelog and, only when necessary, a concise reviewer note.
7. **AI disclosure:** track whether any code or content in the version used generative AI under the broad owner-facing definition.
8. **Terms compliance:** complete the public plugin-policy gate before upload so the terms attestation is truthful.
9. **Publication intent:** decide whether approval should automatically publish the version; do not assume approval and publication are the same state.
10. **Secrets:** never place secrets in public plugin configs; authentication setup is a separate opt-in capability.
11. **Collaboration:** treat author invitations as privileged admin access, not attribution-only metadata.

## Automation safety boundary

A future skill may help prepare artifacts and preflight the values above. It must not autonomously:

- upload a version;
- attest to terms or AI disclosure on the developer's behalf;
- enable authentication;
- mutate public configs;
- add/remove supported games or images;
- invite authors;
- publish, request signing, or follow reviewer-route links.

These are human-confirmed owner actions. Reviewer-role pages remain wholly out of scope.

The skillpack must also never help a user deceive or evade Openplanet review or the Plugin Terms of Service. In particular, it must not:

- conceal, minimize, or misclassify generative-AI use;
- fabricate provenance, authorship, licenses, testing, compatibility, or permission checks;
- coach around reviewer checks or reshape an artifact solely to hide prohibited behavior;
- recommend false answers for disclosures, attestations, reviewer notes, or public metadata;
- automate a terms attestation or infer that the user agrees to it.

If compliance is uncertain, the skill should identify the uncertainty, link the current official policy, and direct the developer to ask Openplanet staff before submission. Refusal to assist with deception must not block legitimate remediation: the skill may explain the rule, help remove prohibited material or behavior, improve provenance, add required permission checks, and prepare an accurate disclosure.

## Unverified owner-facing questions

The read-only inspection intentionally leaves these open:

- exact client/server validation errors and field-length limits;
- accepted image formats and file-size limits;
- all possible review states and how owner feedback is surfaced;
- School-signing selection or eligibility from an ordinary owner perspective;
- whether automatic publication defaults on or off for a newly created plugin/version;
- version editability after submission, approval, signing, or publication;
- Authentication API setup details after enabling it;
- new-plugin creation fields and validation.

These should be answered from public documentation or a purpose-built disposable owner test plugin, never by experimenting on a real published plugin and never by entering reviewer interfaces.
