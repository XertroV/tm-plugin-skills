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

- [`openplanet-reviewer`](skills/openplanet-reviewer/SKILL.md) — adversarial,
  evidence-graded review for subtle Openplanet runtime and architecture failure.

Other manifest entries remain planned until their own promotion gates pass.

Implementation will follow the decisions recorded in the issue map.

## Install

Pick one installation route; do not install the same skill through both because
duplicate skill names are not merged.

### Agent Skills CLI (Claude Code, Codex, and other supported agents)

```bash
npx skills add XertroV/tm-plugin-skills
```

To select only the currently promoted skill:

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
