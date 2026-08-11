# Plugin initialization brief

This tracked document is the durable marker that initialization has completed.
Complete it for every plugin, including tiny, temporary, and local-only work.
Record portable decisions here. Keep machine paths, ports, detected capabilities,
runtime receipts, and private state in clone-local excluded state. Never record
secrets in either artifact.

## Simple interview — required

- **Plugin identity / folder:**
- **Purpose:**
- **Target games:**
- **Tested games and Openplanet versions/channels:**
- **Publication intent:** public candidate / private distribution / local-only / do-not-publish
- **Source, provenance, and AI use:** newly authored, owner-authorized, or copied/adapted sources and compatible licenses; truthful AI-use disclosure assumptions
- **Paid-feature permissions:** required permissions/entitlements, or N/A
- **Architecture / module topology:** default one plugin module; justify every additional plugin or shared boundary
- **Dependencies:** required, optional with degradation behavior, or none
- **Canonical source and build/staging flow:** source root, deterministic generated outputs, and relationship to the live plugin folder
- **Expected Openplanet callbacks:**
- **Smallest observable completion gate:** identity-level behavior that proves the first load without adding a product feature
- **Validation plan:** repository checks, `openplanet-lsp`, exact-bytes/staging check, fresh load/log evidence, and observable gate
- **Policy assumptions:** safety, rights, integrity, non-deception, disclosure, and human-controlled publication assumptions

## Advanced branches — answer when applicable

Mark unused branches `N/A` with a short reason.

### Assets

- Asset/font/media sources, licenses, permissions, attribution, and packaging:

### Dependencies and exports

- Dependency IDs, versions, required/optional behavior, and load order:
- Why ordinary `exports` are insufficient, if `shared_exports` are proposed:
- Dependent reload/lifetime evidence plan for multi-plugin topology:

### Build, staging, and defines

- Build/staging command and deterministic source-to-output mapping:
- Preprocessor defines, who expands them, and public/release defaults:
- Exact-bytes comparison method:

### Authentication and public configuration

- Secret-store boundary (name the mechanism, never the secret):
- Non-secret public settings and safe defaults:
- DEV-only/local-only enablement and shutdown behavior:

### Packaging and publication preparation

- Package contents and excluded development artifacts:
- Compatibility, version, changelog, images/accessibility text, and disclosure plan:
- Human decision boundaries for upload, terms, signing, attestation, approval, and publication:

## Initialization result

- **Tracked brief path:**
- **Clone-local state path (excluded via `.git/info/exclude`):**
- **Manifest and entrypoint:**
- **Static diagnostics:**
- **First-load evidence:** fresh log window and observable result
- **Explicit runtime blocker, if evidence is unavailable:** attempted action, exact cause, and next step
- **Initialization boundary:** no feature work included; next work item/skill
