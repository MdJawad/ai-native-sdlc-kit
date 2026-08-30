# Governance: advisory, deterministic, and immovable

There are three places a rule can live, and choosing the wrong one is the most common mistake teams
make when they adopt this. The three are not alternatives — they are layers, and a serious control uses
more than one.

| Layer | Mechanism | Strength | Who owns it | Who can change it |
|---|---|---|---|---|
| **Advisory** | `CLAUDE.md`, skills | Makes the right thing *likely* | Tech lead, policy owner | Anyone, via review |
| **Deterministic** | Hooks, `.claude/settings.json` | Makes the wrong thing *fail* | Platform engineer | Anyone with repo write access |
| **Immovable** | Managed settings (MDM) | Makes the wrong thing *impossible* | IT / platform admin | Only IT |

## Advisory: skills and `CLAUDE.md`

A skill is instructions loaded when its trigger matches. It shapes what the model does; it does not
constrain what the model *can* do. That is the right layer for the large majority of institutional
knowledge, because most knowledge is contextual rather than absolute — *prefer this pattern*, *check
that document*, *these are the four states this API can be in*.

**Write a skill when** the knowledge must be applied consistently across many sessions, by many people,
and updated centrally when policy changes.

**Leave it in `CLAUDE.md` when** it is this repo's day-one orientation: the build command, the directory
layout, the two mistakes newcomers make.

**Put it in the prompt when** it is true for this task only.

The failure mode is treating an advisory control as if it were deterministic. "Never push from a unit"
in a contributing guide reads like a rule and behaves like a suggestion. It will hold most of the time,
which is worse than failing loudly, because you will stop checking.

## Deterministic: hooks

A hook is a script the harness runs around tool calls. It sees the tool input, and it can block.
`exit 2` stops the action and sends the message on stderr back to Claude, which is what makes a good
block message worth writing carefully — it is read by the thing that has to change course.

Use a hook when a policy must hold **without exception**:

- protected paths — generated code, frozen packages, vendor directories;
- test files during a bug fix, so a red test cannot be edited into green;
- remote operations that are supposed to be a human's decision;
- credentials never appearing in a diff.

**Every hook should be backed by a skill, and vice versa.** The skill explains *why* and shapes
behaviour before the attempt; the hook catches the attempt. A hook with no skill produces an agent that
keeps trying the same blocked thing. A skill with no hook produces a rule that mostly holds.

**Where hooks must not go: approval prompts during Build.** A hook that stops and asks a human for
permission mid-session puts a person back on the critical path and serialises every parallel session
you were running. Approval gates belong in Stage 5, at the point of deploy.

### Worked example: prose → hook

Plenty of repositories carry a rule like this one, in a contributing guide, in capitals:

> **NEVER PUSH from a session.** Work merges into the trunk locally, and the human pushes by hand
> after review.

It is often a well-judged rule — and it is prose, so it holds because everyone happens to be reading
carefully. It will hold most of the time. That is worse than failing loudly, because you will stop
checking, and the one time it does not hold, the failure is silent and remote.

`kit/claude/hooks/no-remote-push.sh` is the same rule as a fact: `git push`, `git remote add` and every
`gh` write subcommand fail, with a message explaining what to do instead. The prose does not go away —
it becomes the layer that explains *why*, which is what stops a session hunting for another route to
the same effect. Advisory and deterministic, doing the two different jobs each is good at.

## Immovable: managed settings

Anything an engineer can edit is not a control against an engineer. For regulated work, the controls
that matter are deployed through MDM to a path outside the repository, and Claude Code refuses to widen
them:

- `permissions.deny` / `allow` — keep secrets unreadable, block arbitrary network egress, pre-approve
  the safe inner loop;
- `allowManagedPermissionRulesOnly` + `disableBypassPermissionsMode` — no project file and no CLI flag
  can widen the rules;
- `sandbox` with `failIfUnavailable` — OS-level isolation that refuses to start rather than degrade;
- `credentials` — deny reads of `~/.ssh` and `~/.aws`, strip tokens from sandboxed environments;
- `allowManagedHooksOnly` — your approval gates are the *only* hooks; nothing local can replace them;
- `disableSideloadFlags` + `strictKnownMarketplaces` — every skill, agent and MCP server arrives through
  an approved marketplace;
- `allowManagedMcpServersOnly` — the tool surface is an allowlist, not a discovery mechanism;
- `requiredMinimumVersion` — refuse to run on an unapproved client.

`kit/enterprise/managed-settings.json` is a template for this. **The installer will not install it**,
deliberately: putting it in the repo would teach exactly the wrong model of where controls live.

## Separation of duties

The agent that wrote a change must not be the thing that approves it. This holds in every profile; only
the mechanism differs.

- **`pr-github`** — branch protection requires a code-owner approval that the agent's identity does not
  have. Agent writes become pull requests; there is no direct path to the default branch.
- **`trunk-local`** — unit branches are never pushed and never self-merged. A coordinator reads the
  diff, merges locally, and re-runs the full gate *on the merged tree*, which is a stronger check than
  any per-branch CI run can give you. The human pushes.

Both are legitimate. What is not legitimate is an agent whose work reaches the default branch without a
named human having looked at it.

## What gets logged, and where the audit trail is

You do not build an audit trail; you commit one.

| Question an auditor asks | Where the answer is |
|---|---|
| Why was this built? | `sdlc/<slug>/intent.md`, with author and commit timestamp |
| Who approved it? | The commit or merge that accepted the intent and spec |
| What policy applied? | The skill versions in the tree at that commit |
| What was the plan, and did the change match it? | `plan.md` versus the merged diff |
| What did review find? | Review findings, in the thread or `review.md` |
| What was blocked, and when? | Hook decisions in the session log / OpenTelemetry export |
| Why was this deploy allowed? | The release authorisation the production gate required |
