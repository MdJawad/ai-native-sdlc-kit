# AI-Native SDLC Kit

**The [AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook), as something you
install.**

The playbook is good, and it ships as prose. Prose has a predictable failure mode in a large
organisation: every team reads it, agrees with it, and implements a different subset with different
file names. This repository turns it into an idempotent, mergeable installation you drop into a repo
and tweak.

Apache-2.0 licensed. Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

> **Not an Anthropic project.** This is an independent, community implementation of the ideas in
> Anthropic's published playbook. It is not affiliated with, endorsed by, or supported by Anthropic.
> "Anthropic" and "Claude" are trademarks of Anthropic PBC. See [`NOTICE`](NOTICE).

---

## The loop

Six stages, each committing an artifact the next one reads. Together they *are* the audit trail —
there is no separate compliance document, because keeping it current is the same act as doing the work.

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  ▼                                                                  │
1 PLAN ──▶ 2 DESIGN ──▶ 3 BUILD ──▶ 4 TEST ──▶ 5 DEPLOY ──▶ 6 MAINTAIN
intent.md   spec.md      plan.md    green      review        breach
                                    gates      findings      ──▶ intent.md
```

| Stage | What the kit gives you |
|---|---|
| **1 Plan** | `intent-capture` skill, `/intent`, `intent.md` template — an idea captured by whoever had it |
| **2 Design** | `spec-authoring` skill, `spec-critic` subagent, `/spec` — policy applied *while the spec is written*, conflicts flagged and owned |
| **3 Build** | `implementation-plan` skill, `/plan`, `CLAUDE.md` scaffold, five hooks — the plan is reviewed before any code exists |
| **4 Test** | Verification block, `protect-tests` hook, an agent-configuration eval harness, `agent-evals.yml` |
| **5 Deploy** | `REVIEW.md`, `reviewer` subagent, `/review`, and a profile-appropriate gate |
| **6 Maintain** | `bands.yaml`, `watch-band.sh`, `/close-loop` — a production breach writes a new `intent.md` |

## Install

```bash
git clone <this repo> && cd ai-native-sdlc-kit

# See exactly what would happen. Writes nothing.
install/install.sh --target /path/to/your/repo --profile trunk-local --dry-run

# Week one: the highest-payback subset
install/install.sh --target /path/to/your/repo --profile trunk-local \
  --modules claude-md,skills,hooks,agents
```

Requires `git`, `jq`, `yq`, and `bash`. Full reference in [`INSTALL.md`](INSTALL.md).

The installer **merges rather than overwrites**: your `CLAUDE.md` gains a marked block and keeps every
other line; your `.claude/settings.json` gains the hook registrations and keeps your permissions. It is
idempotent — run it twice and the second run changes nothing — and it records what it did in
`.sdlc-ai/manifest.lock` so upgrades and uninstall are exact.

**It will refuse to install if `.claude/` is gitignored**, and tell you the three-line fix. Installing
version-controlled agent configuration into an ignored directory produces a setup that works on one
machine and exists nowhere else.

## Profiles

Stage 5 is the only stage that forks, because it is the only one that depends on how your team
integrates work.

- **`trunk-local`** — work merges into a trunk locally, a coordinator reads the diff and re-runs the
  full gate **on the merged tree**, a human pushes by hand. `no-remote-push.sh` blocks pushes and `gh`
  writes outright.
- **`pr-github`** — pull requests, branch protection, code-owner approval, Claude reviewing in CI.
  `production-gate.sh` requires a named release authorisation.

Both satisfy the requirement that actually matters: a named human looks at the change before it reaches
the default branch, and the agent that wrote it is not that human. See [`docs/05-profiles.md`](docs/05-profiles.md).

## Documentation

| | |
|---|---|
| [`docs/00-why.md`](docs/00-why.md) | The argument, and what this kit deliberately does not do |
| [`docs/01-stages.md`](docs/01-stages.md) | **Read this first.** The six stages and the vocabulary everything else uses |
| [`docs/02-adoption-path.md`](docs/02-adoption-path.md) | What to do in week one, and the order *not* to use |
| [`docs/03-governance.md`](docs/03-governance.md) | Advisory vs deterministic vs immovable — the idea most worth getting right |
| [`docs/04-metrics.md`](docs/04-metrics.md) | Leading and lagging indicators, and how to read them without fooling yourself |
| [`docs/05-profiles.md`](docs/05-profiles.md) | `trunk-local` vs `pr-github` |
| [`docs/06-demonstrating.md`](docs/06-demonstrating.md) | A twenty-minute demo runbook, and the questions you will be asked |
| [`docs/07-assessing-your-repo.md`](docs/07-assessing-your-repo.md) | Assess your own repository against the six stages, and pick the first move |

## What is in `kit/`

Everything installable. Nothing in it runs; it is content.

```
kit/
├── claude/skills/        six skills — the artifact chain, ADRs, evals, one policy exemplar
├── claude/agents/        verifier · reviewer · spec-critic
├── claude/commands/      /intent /spec /plan /review /close-loop
├── claude/hooks/         protect-tests · protect-paths · no-remote-push · production-gate · format-after-edit
├── claude/settings.d/    JSON fragments merged into the target's settings.json
├── artifacts/            the intent → spec → plan chain and its templates
├── review/REVIEW.md      the review policy: passes, what "Important" means, the nit cap
├── claude-md/            CLAUDE.md scaffold and the marker-delimited blocks
├── evals/                Stage 4b — agent-configuration eval harness
├── ci/                   agent-evals.yml · claude-review.yml · pre-merge-gate.sh
├── maintain/             bands.yaml · watch-band.sh
└── enterprise/           managed settings for regulated environments — NOT installed, by design
```

## Metrics

```bash
scripts/metrics/artifact-coverage.sh --target /path/to/repo --since 90.days
scripts/metrics/stage-latency.sh     --target /path/to/repo
```

Coverage before latency. A brilliant latency number over 12% of changes tells you about the 12%.

## Three things worth knowing before you start

1. **Skills are advisory; hooks are deterministic.** A rule written in a contributing guide holds
   because people are reading carefully. The same rule as a hook is a fact. Most of this kit is built
   around that distinction — [`docs/03-governance.md`](docs/03-governance.md).
2. **Agent-configuration evals are not product evals.** If your repo already scores an AI feature it
   ships, that suite cannot tell you whether last week's skill edit made Claude worse at working in
   your codebase. You need both, separately.
3. **The exemplars carry someone else's rules.** `secure-api-review` and the three eval cases are
   worked examples showing the shape. Adapt them before you rely on them.
