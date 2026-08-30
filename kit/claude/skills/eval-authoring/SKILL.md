---
name: eval-authoring
description: Write a regression eval for the agent configuration — CLAUDE.md, skills, hooks — usually after an incident or a repeated mistake. Use when asked to add an eval, turn an incident into a test, or when Claude has made the same mistake twice.
---

# Writing an agent-configuration eval

These evals regression-test **the configuration that steers Claude**, not the product. When someone
edits `CLAUDE.md`, adds a skill or changes a hook, these tell you whether the change made things worse.

> **Not the same as your product evals.** If this repo already scores an AI feature it ships, that is a
> product quality gate. It cannot tell you whether last week's skill edit made Claude worse at working
> in this codebase. Keep the two suites separate, in separate directories, with separate owners.

## When to write one

- **After an incident.** Every production incident earns a permanent eval. This is the rule that makes
  the suite worth having, because each case is a thing that actually went wrong here.
- **When Claude makes the same mistake twice.** The first correction goes into `CLAUDE.md`. The eval is
  what proves the correction still holds after the next edit.
- **When you add or change a policy skill.** The eval is how you show the skill fires.

## The shape

One JSON file per case in `evals/cases/`:

```json
{
  "id": "no-double-money",
  "description": "Money must be BigDecimal, never double — CLAUDE.md conventions",
  "prompt": "Add a discount field to the Order model and a method that applies it.",
  "checks": [
    { "type": "file_contains", "path": "src/model/Order.java", "pattern": "BigDecimal discount" },
    { "type": "file_not_contains", "path": "src/model/Order.java", "pattern": "double discount" },
    { "type": "command", "run": "make test" }
  ]
}
```

Check types shipped by the harness: `file_contains`, `file_not_contains`, `command` (must exit 0),
`command_fails` (must exit non-zero — for asserting a hook blocks something), and `output_contains`
against the session's final message.

## Rules

- **One behaviour per case.** A case asserting five things tells you something broke, not what.
- **Derive the prompt from real work.** Take the actual phrasing someone used. Prompts invented to suit
  the check test the check.
- **Assert the outcome, not the transcript.** Check the file that was written or the command that
  passes. Asserting that Claude *said* something is brittle and tests phrasing, not behaviour.
- **Make it deterministic.** No network, no clock, no ordering assumptions. A flaky eval gets muted, and
  a muted suite is worse than none because it still looks like coverage.
- **Assert the blocks too.** A hook is only proven by a case that tries the forbidden thing and expects
  it to fail. Use `command_fails`.
- **Keep it fast.** These run on every configuration change. A case needing a full stack belongs in the
  scheduled run, not the pull-request run.

## After writing

Run it against the current configuration and confirm it **passes now** — an eval that has never gone
green is asserting your aspiration, not your behaviour. Then confirm it *fails* if you temporarily
break the thing it guards. A case that passes both before and after the guard is removed is testing
nothing, and this is the single most common defect in a new suite.

Commit it with the configuration change it protects, and note the incident it came from in
`description`.
