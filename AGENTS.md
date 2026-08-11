# Agent instructions

This repository is in Wayfinder planning mode. GitHub Issues are the canonical decision map; implementation must follow closed decision tickets rather than inventing unresolved product choices.

## Planning

- Read `docs/agents/issue-tracker.md` before operating on the map.
- Refer to issues by linked title in human-facing prose, not bare issue numbers.
- Keep decisions in their resolution tickets. The map only links and gists them.
- One decision ticket per session, except parallel research tickets.

## Product direction

- Portable default: the plugin repository may itself be a folder inside Openplanet's `Plugins/` directory.
- Project-specific build scripts, `openplanet-lsp`, RemoteBuild, MCP bridges, and screenshot tooling are capabilities to detect, not universal prerequisites.
- Skills must be concise, opinionated, progressively disclosed, and backed by observable completion gates.

## Repository work

- Do not implement a skill while its governing decision remains open.
- Add every promoted skill to the top-level index and plugin manifests.
- Validate frontmatter, internal links, invocation metadata, and any bundled scripts before committing.
