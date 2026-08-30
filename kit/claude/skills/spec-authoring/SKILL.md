---
name: spec-authoring
description: Turn an accepted intent.md into a requirements-and-design spec.md that conforms to this organisation's policies, flagging any policy conflicts it cannot resolve. Use when asked to write, produce or review a spec, or when moving an accepted intent into design.
---

# Authoring a spec

You are collapsing requirements and design into one pass. The output is `spec.md` beside the
`intent.md` it came from, in `sdlc/<slug>/`.

## Before you write

1. **Read the `intent.md` in full.** Every requirement traces back to something in it. If you are about
   to write a requirement that does not, either you found a real gap — say so — or you are inventing
   scope, which is worse.
2. **Read the repo.** `CLAUDE.md`, the architecture notes, the contracts or interface definitions, the
   decision records. A spec that ignores the existing system produces a plan that fights it.
3. **Load every applicable policy skill.** Security, data handling, API conventions, brand, UX,
   accessibility. These are what make the spec conform *as it is written* rather than in a review three
   weeks later. If this repo has none, say so explicitly in your summary — an unconstrained spec is a
   fact the reader should know.

## The spec

Use `sdlc/templates/spec.md`. It covers:

- **Requirements** — numbered, testable, each traceable to a line in the intent. "Testable" means you
  could write the assertion now.
- **Out of scope** — as important as the requirements, and the part reviewers rely on.
- **Design** — the components that change, the data that flows, the interfaces at the boundary.
- **Data and privacy** — what is stored, what crosses a boundary, what is classified, what is logged.
- **Policy conformance** — which policies you applied, and *how* this design satisfies each. Name them.
- **Concerns and conflicts** — see below.
- **Verification** — how someone proves this works. Feeds Stage 3's `plan.md`.
- **Decisions needing a record** — anything load-bearing enough to owe an ADR.

## Flagging conflicts is the job, not a failure

**This is the most valuable thing this skill does.** When two policies cannot both be satisfied, or a
requirement cannot be met within a constraint, do not quietly pick one and move on. Do not soften it
into a caveat. Write it under `## Concerns and conflicts` with:

- what the conflict is, concretely;
- which policies or constraints are in tension, **named**;
- the options, with what each costs;
- **who owns the decision** — a named policy owner, or an explicit "owner unknown".

Then say in your summary that the spec cannot be accepted until each is resolved. Finding these before
engineering starts is the entire reason this stage exists.

## Rules

- **Never invent a policy.** If you think a rule applies but cannot find it written down, say that you
  believe it applies and could not find the source. An invented policy is worse than a missing one,
  because it looks authoritative.
- **Do not resolve an open question from the intent by guessing.** Carry it forward, or get an answer.
- **Do not write implementation.** No file paths, no function names, no work order — that is `plan.md`,
  and doing it here means it gets reviewed by the wrong person.
- **Say what you are unsure about.** A spec that hedges nothing has usually hidden something.

## After writing

Commit `spec.md` beside its `intent.md`. Then state, in this order: what the spec covers, what it
excludes, and every flagged conflict with its owner. Say plainly that it needs product-owner sign-off,
and that any higher-risk item needs the tech lead too.

If the repo has a `spec-critic` subagent, running it against the draft before you present it will catch
the requirement that is not actually testable.
