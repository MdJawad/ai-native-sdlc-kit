---
description: Stage 3 — produce a reviewable implementation plan before any code is written
argument-hint: "<slug> — the change directory under sdlc/"
allowed-tools: Read, Glob, Grep, Write, Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*)
---

Plan the implementation of: **$ARGUMENTS**

Use the `implementation-plan` skill. **Do this in plan mode** so nothing can be edited until the plan
is accepted.

1. **Read** `sdlc/$ARGUMENTS/spec.md` and `intent.md`, then `CLAUDE.md`, then **the actual files you
   intend to change**. A plan naming files you have not opened is a guess with formatting.
2. **Write the plan** from `sdlc/templates/plan.md`: files that change (real paths, new or modified),
   order of work (each step a state where the repo still builds), risks (including what you rejected),
   and proof (named tests and what each asserts).
3. **Flag an owed ADR** if the change makes a load-bearing choice.
4. **Ask for the interrogation** — what could break, what is risky, what did you reject — and update
   the plan from the answers.
5. **Commit the accepted plan** as `sdlc/$ARGUMENTS/plan.md` *before* implementing.

Then implement in the stated order. If reality contradicts the plan, stop and say so rather than
improvising — update the plan, then continue.
