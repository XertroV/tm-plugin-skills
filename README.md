# Openplanet Plugin Skills

Opinionated agent skills for developing, testing, operating, and visually reviewing Openplanet AngelScript plugins.

This repository is currently being designed through a [Wayfinder map](https://github.com/XertroV/tm-plugin-skills/issues?q=label%3Awayfinder%3Amap).

## Intent

- Treat a plugin checked out directly under an Openplanet `Plugins/` directory as the portable default.
- Detect project build systems and automation as enhancements rather than assumptions.
- Close the feedback loop through static checks, live load/reload, `Openplanet.log`, screenshots, and observable plugin behavior.
- Keep skills concise, composable, and usable across agent harnesses.
- Maintain six independently triggerable skills, including `openplanet-reviewer` for adversarial runtime, state, synchronization, callback-safety, and architecture review. See `docs/skill-manifest.md`.
- Turn every newly discovered subtle failure mode into a reviewer-ledger entry and, where applicable, development guidance plus test/demo evidence.

## Promoted skills

- [`openplanet-init`](skills/openplanet-init/SKILL.md) — scaffold and normalize
  plugin identity, policy onboarding, tracked briefs, and private local state.
- [`openplanet-lifecycle`](skills/openplanet-lifecycle/SKILL.md) — stage, load,
  reload, unload, diagnose, restore dependents, and prove exact running bytes.
- [`openplanet-dev`](skills/openplanet-dev/SKILL.md) — implement AngelScript with
  adjacent tests, effective demos, diagnostics parity, and lifecycle proof.
- [`openplanet-visual`](skills/openplanet-visual/SKILL.md) — build theme-safe UI
  with deterministic galleries and fresh screenshot critique. The bundled demo
  gallery leads with interesting reusable recipes under `Featured`; foundational
  and diagnostic examples remain available under `Boring`. Demo/test main
  windows are toggleable from Plugins → `Skillpack Demos`.
- [`openplanet-control`](skills/openplanet-control/SKILL.md) — choose safe runtime
  capabilities and optionally build bounded DEV-only semantic controls.
- [`openplanet-reviewer`](skills/openplanet-reviewer/SKILL.md) — adversarial,
  evidence-graded review for subtle Openplanet runtime and architecture failure.

## Install

Pick one installation route; do not install the same skill through both because
duplicate skill names are not merged.

### Agent Skills CLI (Claude Code, Codex, and other supported agents)

```bash
npx skills add XertroV/tm-plugin-skills
```

To select one skill:

```bash
npx skills add XertroV/tm-plugin-skills --skill openplanet-reviewer
```

### Claude Code plugin

Clone the repository, then load that checkout directly:

```bash
claude --plugin-dir /path/to/tm-plugin-skills
```

The repository also includes a minimal local marketplace manifest for forks and
unreleased commits. Official marketplace publication is not a v1 requirement.

## License

[CC0-1.0 OR Unlicense](LICENSE) — use either license at your option.

## Acknowledgements

The repository-development conventions are inspired by [Matt Pocock's engineering skills](https://github.com/mattpocock/skills): small composable skills, explicit invocation boundaries, portable Agent Skills, and repository-level validation.
