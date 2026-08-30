---
name: implementation-plan
description: Produce a reviewable implementation plan (plan.md) from a spec before any code is written — files that change, order of work, risks, and the proof it worked. Use in plan mode, when asked to plan an implementation, or before starting a non-trivial change.
---

# Writing an implementation plan

The plan is reviewed **before** any code exists, which is the cheap place to catch a wrong approach.
Write it so that someone unfamiliar with the change could implement it from the plan alone. If they
could not, it is not finished.

## Before you write

Read the `spec.md` and its `intent.md`. Read `CLAUDE.md`. Then read the code you are about to change —
actually open the files. A plan naming files you have not looked at is a guess with formatting.

## The plan

Use `sdlc/templates/plan.md`. Four sections carry the weight:

**Files that change.** Every path, with one line on what happens to it, marked new or modified. This
is the section reviewers use to spot the change touching something it should not.

**Order of work.** Numbered steps, each one a state where the repo still builds. If a step cannot be
verified on its own, it is two steps or it is one badly sized one.

**Risks.** What could break, what is uncertain, what you rejected and why. This is the section people
skip and the section that earns the plan its keep — a plan with no risks named has not been thought
about. Rate limits, migrations, concurrency, backwards compatibility, anything with a blast radius
wider than the diff.

**Proof.** The specific tests, commands and observations that will show it worked. Name the test files
and what each asserts. "Tests pass" is not proof; "`test_status.py` covers the four claim states" is.

## Rules

- **Name real paths.** Not `the handler` — `services/claims/routes/status.py`.
- **Land tests in the plan, not after it.** Every behavioural change names the test that proves it.
- **Respect the repo's stated invariants.** If `CLAUDE.md` lists hard rules, the plan says how it stays
  inside them — or flags, loudly, that it cannot.
- **Flag an owed decision record.** If the change makes a load-bearing choice — a new dependency, a
  schema, a boundary — say that an ADR is owed and what it will decide.
- **Say what you rejected.** One line each for the approaches you considered and dropped. It is the
  fastest way for a reviewer to tell whether you understood the problem.
- **Do not pad.** A plan for a two-file change is short. Length is not diligence.

## Invite the interrogation

After presenting the plan, ask directly for the three questions worth asking: *what could break*,
*what is risky here*, *what did you reject*. Then update the plan from the answers. The iteration is
the point — a plan accepted without a single change was almost certainly not read.

## When the plan is accepted

Commit it as `sdlc/<slug>/plan.md` **before** implementing. The commit timestamp is the Stage 3 metric,
and the committed plan is what review compares the diff against later.

Then implement it in the stated order. **If reality contradicts the plan** — a file that does not exist,
an interface different from what you assumed, a risk that turns out to be real — stop and say so rather
than quietly improvising. Update the plan, then continue. A merged diff that no longer resembles its
`plan.md` means the plan review was theatre, and that is visible in the metrics.
