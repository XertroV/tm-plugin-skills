# Domain language

- **Plugin folder** — A modern Openplanet plugin source directory rooted at `info.toml`. It may be the repository itself and may live directly under Openplanet's `Plugins/` directory.
- **Lifecycle loop** — Edit, check, load or reload, inspect the post-action log window, exercise behavior, and collect evidence.
- **Runtime evidence** — A post-change `Loaded plugin` event with no later compile error for that plugin, plus an observable behavior check when behavior changed.
- **Portable path** — A workflow requiring only Openplanet and ordinary filesystem access; optional tools may tighten it but never replace it.
- **Capability detection** — Discovering available build, checker, RemoteBuild, log, screenshot, and control tools before selecting a workflow.
- **Visual gate** — Screenshot-based observation and critique required before declaring a visual UI change complete.
- **Control bridge** — An optional plugin or external tool that exposes live game/plugin state and actions to an agent.
- **Initialization brief** — A tracked, human-readable file created for every initialized plugin, including tiny local-only experiments. Its presence is the durable marker that onboarding has completed; it records product intent and architectural/policy decisions, never machine-local paths or secrets.
- **Clone-local state** — Private per-checkout capability discoveries, machine paths, receipts, and other non-portable state stored outside tracked project documentation and excluded through `.git/info/exclude`.
- **Demo plugin** — A temporary/development Openplanet plugin used to compile, load, smoke, and visibly inspect skillpack snippets incrementally. Multiple demo plugins may isolate concerns; all use the dedicated `Skillpack Demos` category.
- **Gotcha** — An experienced Openplanet failure mode whose preventative default belongs in `docs/openplanet-gotchas.md`, automated checks, and relevant skill guidance rather than only in session history.
