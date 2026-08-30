# The six stages, and what each one commits

This is the shared vocabulary for the rest of the kit. Every other document assumes it.

The AI-native SDLC is a **loop**, not a line. Each stage commits an artifact the next stage reads.
Together those artifacts — intent, spec, plan, diff, review findings — *are* the audit trail. There is
no separate compliance document to maintain, because the git history is the record.

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  ▼                                                                  │
1 PLAN ──▶ 2 DESIGN ──▶ 3 BUILD ──▶ 4 TEST ──▶ 5 DEPLOY ──▶ 6 MAINTAIN
intent.md   spec.md      plan.md    green      review        breach
                                    gates      findings      ──▶ intent.md
```

---

## Stage 1 — Plan · commits `intent.md`

**What changes.** An idea is captured by the person who had it, in conversation with Claude, and lands
as a version-controlled markdown file. Not a ticket, not workshop notes.

**Who.** The originator (often not an engineer). Approved or rejected by the product owner.

**Kit assets.** `intent-capture` skill · `/intent` command · `sdlc/templates/intent.md`.

**The gate.** A human product owner accepts or closes it. Never automate this away — it is the only
place the organisation decides whether a thing is worth building.

**Leading indicator.** Time from first conversation to a committed `intent.md`. Read straight out of
git. Weeks → hours is the expected shape.

---

## Stage 2 — Design · commits `spec.md`

**What changes.** Requirements and design stop being two phases run by two teams. One prompted session
produces both, constrained by **skills** that encode your brand, security, compliance and UX policy —
so policy is applied *while the spec is written*, not discovered in a review three weeks later.

**Who.** Product owner, with policy owners pulled in on anything the spec flags as contradictory.

**Kit assets.** `spec-authoring` skill · `spec-critic` subagent · `/spec` command ·
`sdlc/templates/spec.md`. Your own policy skills go beside `secure-api-review`.

**The gate.** Product owner sign-off, and every flagged conflict routed to a *named* policy owner
before engineering starts.

**Leading indicator.** Elapsed time between the `intent.md` commit and the `spec.md` commit.

---

## Stage 3 — Build · commits `plan.md`, then the diff

**What changes.** Four things at once:

| | What it is | Kit asset |
|---|---|---|
| **Plan mode** | Claude reads the repo but cannot edit until you accept a written plan. Design review moves *before* code generation, where correction is cheap. | `implementation-plan` skill, `/plan` |
| **`CLAUDE.md`** | The context a new joiner needs: commands, conventions, architecture, and the mistakes your team actually makes. Read in full at session start, so keep it near a page. | `kit/claude-md/` |
| **Skills** | Institutional knowledge that must be applied *consistently*, made explicit and versioned. | `kit/claude/skills/` |
| **Hooks** | The deterministic layer under a skill. A skill makes the right thing likely; a hook makes the wrong thing impossible. | `kit/claude/hooks/` |

**The working rule for `CLAUDE.md`:** when Claude makes the same mistake twice, the correction goes in
the file. If it only happened once, it was noise.

**The rule for skills vs `CLAUDE.md`:** write a skill for knowledge that must be applied consistently
across many sessions and repos. Leave in `CLAUDE.md` what is just this repo's day-one orientation.

**Parallel sessions.** Independent tasks run in their own git worktrees. Start with two or three; the
cap is how many streams one person can genuinely review, not what the machine can run.

**Leading indicator.** Share of changes that merge from the first implementation pass.

---

## Stage 4 — Test · commits green gates and eval cases

Two distinct things live here, and teams routinely conflate them.

**4a. Give Claude a feedback loop.** The session checks its own work — build, tests, lint, screenshot
diff — and fixes what it broke *before* a human ever sees it. This needs one command that exits
non-zero on failure (`make all`, `npm test`), listed in `CLAUDE.md` with an example of healthy output,
and an explicit instruction that running it is part of "done".

For a bug fix, the order matters: write the failing test **first**, confirm it fails for the expected
reason, commit it, *then* ask for the fix — and use a hook to stop the agent editing the test to go
green. `protect-tests.sh` does exactly that.

**4b. Continuous evals on the agent configuration.** This is the part almost everyone skips.
`CLAUDE.md`, your skills and your hooks are *inputs to a model* — change them and behaviour changes.
So they need regression tests like any other code. An eval is a prompt plus checks defining what
acceptable looks like, run non-interactively in CI whenever `CLAUDE.md` or `.claude/**` changes.

> **Product evals are not agent-configuration evals.** If your repo already scores an AI feature it
> ships — a suite that grades your assistant's answers, say — that is a product quality gate. It tells
> you nothing about whether last week's skill edit made Claude worse at working in your codebase. You
> need both, in separate suites, with separate owners.

Every production incident becomes a permanent eval. That is how the suite earns its keep.

**Leading indicator.** First-pass CI success rate for agent-written changes; eval pass rate over time.

---

## Stage 5 — Deploy · commits review findings

**What changes.** Review runs in both directions — Claude reviews incoming changes, and addresses
findings on its own. Governance is enforced *as the agent acts*, not audited afterwards. The agent does
everything up to the production gate and nothing past it.

**Review policy is a file.** `REVIEW.md` at the repo root: the passes to run, what counts as
*Important* versus a nit, a cap on nit volume, and what not to report at all. Without a nit cap you get
a review nobody reads.

**Separation of duties is non-negotiable.** The agent that wrote the change cannot be the thing that
approves it. How that gate is expressed depends on your profile — see
[`05-profiles.md`](05-profiles.md). In `trunk-local` it is the coordinator reading the diff and the
merged-tree gate going green; in `pr-github` it is branch protection and code-owner approval.

**Hooks are approval gates here, not in Build.** An approval prompt during Build puts a human back on
the critical path and re-serialises everything you just parallelised.

**Leading indicator.** Time to first review; share of findings resolved without a human touching the
branch.

---

## Stage 6 — Maintain · commits a new `intent.md`

**What changes.** The loop closes. A deterministic script watches production for a control-band breach
and invokes Claude with **no person in the invocation path**. Claude diagnoses, acts only through
pre-approved routes, and writes what it found as an `intent.md` — which re-enters at Stage 1.

**Tiered response is what keeps this safe.** Detection is deterministic; the *response* is banded, and
the bands are version-controlled in `bands.yaml`:

| Band | Action |
|---|---|
| 1σ | log only |
| 2σ | invoke Claude **read-only** to diagnose |
| 3σ | Claude may act — open a change into the review gate, or trigger a pre-approved runbook |

An agent that can act at 1σ is a runaway; an agent that can only log at 3σ is decoration.

**Leading indicator.** Time from band breach to an `intent.md` sitting in the triage queue — measured
against how long "incident → post-mortem action" used to take.

---

## The artifact chain, in one table

| Artifact | Written at | Read by | Lives at |
|---|---|---|---|
| `intent.md` | Stage 1 | Stage 2 | `sdlc/<slug>/intent.md` |
| `spec.md` | Stage 2 | Stage 3 | `sdlc/<slug>/spec.md` |
| `plan.md` | Stage 3 | Stages 3, 5 | `sdlc/<slug>/plan.md` |
| the diff + tests | Stages 3–4 | Stage 5 | your branch |
| review findings | Stage 5 | `CLAUDE.md` | review thread / `sdlc/<slug>/review.md` |
| ADR | any stage | everything after | your existing ADR directory |
| `postmortem.md` | Stage 6 | Stage 1, evals | `sdlc/<slug>/postmortem.md` |

**Where ADRs fit.** A `spec.md` describes *this* change. An ADR records a decision that outlives it —
a new backend, a schema, a boundary. When a spec makes a load-bearing choice, it says so and the ADR is
written alongside. The `adr-authoring` skill enforces your house shape and, critically, reads the
directory for the next free number rather than trusting a number quoted in a document.
