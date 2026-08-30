# Agent-configuration evals

These regression-test **the configuration that steers Claude** — `CLAUDE.md`, the skills, the hooks —
not the product. When someone edits a skill, these tell you whether it made things worse.

> **Not your product evals.** If this repo already scores an AI feature it ships, keep that suite where
> it is. It cannot tell you whether last week's `CLAUDE.md` edit made Claude worse at working here.
> Separate directories, separate owners, separate gates.

## Running

```bash
kit/evals/run.sh                    # the whole suite
kit/evals/run.sh --case artifact-chain
```

Each case runs in a **throwaway git worktree** off `HEAD`, so a case that writes files never dirties
the repo. The worktree is removed afterwards, pass or fail. The repository must be committed and clean
for a worktree to be created.

Needs `claude`, `jq`, `git`, and working Claude Code auth (`ANTHROPIC_API_KEY` in CI).

## Writing a case

One JSON file per case in `cases/`. Use the `eval-authoring` skill — it carries the rules.

```json
{
  "id": "no-double-money",
  "description": "Money must be BigDecimal, never double — CLAUDE.md conventions. From INC-4412.",
  "prompt": "Add a discount field to the Order model and a method that applies it.",
  "allowed_tools": "Read,Edit,Glob,Grep,Bash",
  "checks": [
    { "type": "file_contains",     "path": "src/model/Order.java", "pattern": "BigDecimal discount" },
    { "type": "file_not_contains", "path": "src/model/Order.java", "pattern": "double discount" },
    { "type": "command",           "run": "make test" }
  ]
}
```

### Check types

| Type | Passes when |
|---|---|
| `file_contains` | `path` exists and matches the extended regex `pattern` |
| `file_not_contains` | `path` is absent, or does not match `pattern` |
| `file_exists` | `path` exists |
| `file_unchanged` | `git diff` is empty for `path` — the agent did not touch it |
| `command` | `run` exits 0 |
| `command_fails` | `run` exits non-zero — **this is how you prove a hook blocks something** |
| `output_contains` | the final assistant message matches `pattern`, case-insensitively |

### The rules that matter

- **One behaviour per case.** A case asserting five things tells you something broke, not what.
- **Assert the outcome, not the transcript.** Prefer `file_contains` over `output_contains`; asserting
  what Claude *said* tests phrasing, not behaviour.
- **Prove the blocks.** A hook is only tested by a case that tries the forbidden thing and expects
  failure. `file_unchanged` and `command_fails` exist for this.
- **Confirm it fails when the guard is removed.** A case that passes both with and without the thing it
  guards is testing nothing. This is the most common defect in a new suite — check it once, deliberately,
  for every case you add.
- **Keep it fast and deterministic.** No network, no clock, no ordering assumptions. Anything needing a
  full stack belongs in the scheduled run, not the pull-request run.

## The three shipped cases are exemplars

`001`–`003` demonstrate the three shapes — an instruction in `CLAUDE.md`, a hook that must block, and
the artifact chain. **They assume things about your repo that are probably not true.** Read them, adapt
them, then start collecting real cases: 20–50 tasks drawn from actual recent work, and one for every
production incident.

Three cases that run beat fifty that were designed and never wired up.
