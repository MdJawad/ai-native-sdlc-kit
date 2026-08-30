# Assessing your own repository

An hour's work that tells you which stage to adopt first, and — more usefully — which of the practices
you already have without calling them that.

Most repositories that are run well are already strong on two or three stages and have never thought
about the others. Adopting in the order this exercise produces beats adopting in the order the playbook
is written.

Fill in the table at the bottom as you go.

---

## Before the stages: two prerequisites

Neither is optional, and both are usually five-minute fixes.

### 1. Is `.claude/` version-controlled?

```bash
git check-ignore -v .claude && echo "IGNORED — fix this first"
```

A great many repositories ignore the whole directory as *local agent config*. That is a reasonable
decision that quietly expires the moment agent configuration becomes something you want reviewed,
owned and diffed. While it holds, skills, hooks and subagents cannot be shared: they work on one
machine and exist nowhere else.

The narrow fix keeps genuinely local things local:

```gitignore
# Agent configuration is reviewed code — only these are local
.claude/settings.local.json
.claude/worktrees/
```

**Then check what is already there and untracked.** Repositories that have been using Claude for a
while often have real, load-bearing content in `.claude/commands/` that nobody has ever backed up:

```bash
git status --ignored --porcelain .claude | head -20
```

Commit that before you install anything. It is usually worth more than anything a kit would add, and it
is the least safe content in the repository.

### 2. Is there one command that verifies the repo?

One target, exiting non-zero on failure: `make all`, `npm test`, `./gradlew check`. If you do not have
one, **build it before anything else here**. Stage 4 has nothing to stand on without it, and every
session will hand you work you cannot trust.

---

## Stage by stage

For each: what good looks like, the question that actually discriminates, and the cheapest first move.

### Stage 1 — Plan

**Good looks like:** the reason a change exists is written down separately from what will be built, by
the person who wanted it, before anyone designs anything.

**The question:** pick your last three merged changes. For each, can you find a written statement of the
*problem* that does not immediately describe the *solution*?

Most repositories fail this, and it does not look like a failure — the roadmap items, the tickets and
the design docs all describe what will be built from the first sentence. The originators exist; they
just have nowhere to write.

**Cheapest first move:** `sdlc/templates/intent.md`, used once, on a change that has not started.

### Stage 2 — Design

**Good looks like:** policy is applied *while* the spec is written, and conflicts between policies are
named, with owners, before engineering starts.

**The question:** where do your security, data-handling and API conventions live, and *when* are they
applied? If the honest answer is "in a wiki, and at review time", that is the gap — not the absence of
the documents, but the lateness of their application.

A second question worth asking: when two of your policies contradict each other, who decides? If the
answer is "whoever writes the code", the decision is being made at the wrong level by the wrong person.

**Cheapest first move:** take the one convention that gets violated most and write it as a skill. One,
not six.

### Stage 3 — Build

**Good looks like:** an implementation plan is written and interrogated *before* code exists; the
repo's context lives in a `CLAUDE.md` that is read every session; institutional knowledge is versioned.

**The questions:**
- Is plan mode used, and is what it produces *kept*? Producing a plan and discarding it means nothing
  can later compare the merged diff against what was agreed.
- Does `CLAUDE.md` exist, is it near a page, and does it have a section for mistakes the team actually
  makes? That section is empty at first and the most valuable one within a month.
- Do `.claude/skills/`, `.claude/hooks/` and `.claude/agents/` exist at all?

**Cheapest first move:** commit one `plan.md`, for one change, before implementing it.

### Stage 4 — Test

Two separate things live here and are routinely conflated.

**4a — the feedback loop.** Does `CLAUDE.md` name the verification commands *and* say what healthy
output looks like *and* say that running them is part of "done"? Naming the command is not enough; a
session needs to know what success looks like to check its own work.

**4b — agent-configuration evals.** The discriminating question: **if someone edits a skill or
`CLAUDE.md` today, what tells you it made things worse?** For almost every repository the answer is
"nothing", including repositories with excellent test suites and even ones with their own AI evals.

> A product eval scores the AI feature you ship. It cannot tell you whether last week's skill edit made
> Claude worse at working in your codebase. Separate suites, separate directories, separate owners.

**Cheapest first move:** the verification block in `CLAUDE.md`, and the `protect-tests` hook. Ten
minutes, and it is the change most likely to reduce sessions reporting success they did not observe.

### Stage 5 — Deploy

**Good looks like:** a written review policy, applied consistently, and a gate the agent that wrote the
change cannot pass.

**The questions:**
- Is there a `REVIEW.md`, or is review whatever the reviewer thinks to look for that day?
- Can an agent's work reach your default branch without a named human having looked at it? Trace the
  actual path, not the intended one.

**Cheapest first move:** write `REVIEW.md`. Three passes, a definition of *Important*, and a nit cap.
The nit cap matters more than it sounds: an uncapped reviewer produces output nobody reads.

### Stage 6 — Maintain

**Good looks like:** something in production can raise a finding that re-enters the pipeline without a
person remembering to do it.

**The question:** when an incident happens, what carries the lesson forward? If the answer is a
post-mortem document and someone's memory, the loop is open.

**Cheapest first move:** none yet. **Do not start here.** An autonomous loop feeding findings into a
process that cannot absorb them produces a queue nobody triages, and the experiment gets written off.

---

## The advisory-to-deterministic audit

Usually the highest-value half hour in this exercise, and it needs no tooling.

**Open your `CONTRIBUTING.md`, `CLAUDE.md`, and any command or runbook files. Find every rule stated in
prose that is supposed to hold without exception.** They are easy to spot — they are the ones in bold,
in capitals, or with *never* in them:

> **NEVER PUSH from a session.**
> Do not weaken a gate to make it pass.
> Vendor code lives only under `adapters/`.
> The frozen `v1/` package does not change; work goes in `v2/`.

Each of those holds because everyone happens to be reading carefully. That works until it does not, and
the failure is silent. For each rule, ask three things:

1. **Must this hold without exception?** If it is really a preference, leave it as prose and stop.
2. **Can a script detect the violation from the tool call?** Editing a path, running a command, writing
   a file — if yes, it can be a hook.
3. **Is there a legitimate exception?** Then design the escape hatch deliberately, as an environment
   variable or a config file, rather than leaving the rule advisory so people can ignore it quietly.

Rules that survive all three are your first hooks. Start with the two that are least controversial —
the ones the team already believes in — because then the only thing changing is whether the rule holds
when nobody is watching. That is the cheapest possible demonstration that the governance layer is real.

**The prose does not go away.** It becomes the layer that explains *why*, which is what stops a session
hunting for another route to the same effect. See [`03-governance.md`](03-governance.md).

---

## See what installing would actually do

```bash
install/install.sh --target /path/to/your/repo --profile trunk-local --dry-run
```

Writes nothing. Prints every file, every merge, and every conflict. Read it for three things:

- **Conflicts.** Zero is common and means the kit adds beside your files rather than over them.
- **Directory collisions that are not filename collisions.** If you already have an `evals/` holding
  product evals, the kit's agent-configuration harness would land beside it — no file collides, but two
  different kinds of eval would share a directory and eventually an owner. Install with `--modules`
  excluding `evals` and put the new suite in `evals/agent/`.
- **Where `sdlc/` lands.** If your repo has an established pattern for top-level content directories,
  it belongs alongside them. If everything lives under `docs/`, use `--artifacts-dir docs/sdlc`.

---

## Your assessment

| Stage | Have | Partly | Missing | First move | Effort |
|---|:--:|:--:|:--:|---|---|
| 0 — `.claude/` tracked | | | | | |
| 0 — one verify command | | | | | |
| 1 Plan | | | | | |
| 2 Design | | | | | |
| 3 Build | | | | | |
| 4a Feedback loop | | | | | |
| 4b Config evals | | | | | |
| 5 Deploy | | | | | |
| 6 Maintain | | | | | |

**Then sequence it.** Prerequisites first, then whichever of Stages 3, 4a and 5 you scored worst on —
those three pay back fastest and need no process change from anyone outside engineering. The artifact
chain (1–3) next, on one real change end to end. Evals after you have configuration worth protecting.
Stage 6 last.

If that ordering contradicts [`02-adoption-path.md`](02-adoption-path.md), trust this one. It is based
on your repository; that one is based on the average.

## One more thing worth doing

Write down what your repository already does **better** than this kit, and keep it.

Repositories that are run well usually have at least one convention worth more than anything here — a
decision-record numbering discipline, a documentation-archiving rule that beats letting docs rot, a
table in `CLAUDE.md` saying which document is authoritative when two disagree. Installing a kit is not
a reason to lose them, and the kit's templates are a floor, not a ceiling.
