# Profiles: `trunk-local` and `pr-github`

Stage 5 is the only stage where the kit forks, because it is the only stage that depends on how your
team actually integrates work. Everything in Stages 1–4 and 6 is identical across profiles.

Choose with `--profile` at install time. Getting this wrong is not fatal — re-run the installer with
the other profile and it swaps the Stage 5 assets — but choose deliberately rather than taking the
default.

## `pr-github`

**Pick this if** work reaches the default branch through pull requests, you have (or can enable) branch
protection, and CI can run on a PR.

| | |
|---|---|
| The gate | Branch protection + code-owner approval |
| Review runs | In CI, on the PR, via `claude-review.yml` |
| Findings land | As PR comments, addressed by tagging the agent |
| Deploy gate | `production-gate.sh` — production deploys require a named release authorisation |
| Installed | `ci/github/claude-review.yml`, `hooks/production-gate.sh`, `settings.d/profile-pr-github.json` |

**Separation of duties** comes from the forge: the agent's identity cannot approve, and there is no
push path to the protected branch.

## `trunk-local`

**Pick this if** work merges into a trunk branch locally, by a coordinator, and a human pushes by hand
— or if remote operations are deliberately restricted for safety.

| | |
|---|---|
| The gate | A coordinator reads the diff, merges locally, re-runs the full verify command **on the merged tree** |
| Review runs | Locally, via `/review` and the `reviewer` subagent, against `REVIEW.md` |
| Findings land | In `sdlc/<slug>/review.md`, committed with the change |
| Push gate | `no-remote-push.sh` — pushes, remote-adds and `gh` writes are blocked outright |
| Installed | `ci/local/pre-merge-gate.sh`, `hooks/no-remote-push.sh`, `settings.d/profile-trunk-local.json` |

**Separation of duties** comes from the merge: a unit cannot push and cannot merge itself. The
coordinator is the approving human, and the merged-tree gate is the check.

### Why this profile is not a compromise

It is tempting to read `trunk-local` as "PR-based, but without the tooling". It is not. When work lands
in coordinated batches of concurrent units that share a dependency graph, the check that matters is the
full gate on the **merged** tree — every unit's change together — and a per-branch PR check
structurally cannot give you that. Each branch can be green and the merge still red.

The shape that calls for it: units branch off the trunk into their own worktrees, a coordinator merges
them locally and re-runs the full verification on the result, and remote operations are deliberately
restricted — sometimes because the corporate remote is not safe to automate against. The playbook's
Stage 5 is satisfied in that arrangement — a named human reviews before integration, the agent cannot
self-approve, and the trail is in the merge commits. It is simply not satisfied *by a forge*.

## Switching profiles

```bash
install/install.sh --target /path/to/repo --profile pr-github
```

Re-running with a different profile removes the previous profile's Stage 5 assets (they are recorded in
`.sdlc-ai/manifest.lock`) and installs the new ones. Nothing outside Stage 5 changes.

## Neither fits

If you integrate through GitLab, Gerrit, or something in-house, start from `trunk-local` — it makes the
fewest assumptions about a forge — and replace `ci/local/pre-merge-gate.sh` with your equivalent. The
requirement the kit actually cares about is the one in
[`03-governance.md`](03-governance.md#separation-of-duties): a named human looks at the change before it
reaches the default branch, and the agent that wrote it is not that human.
