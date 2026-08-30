---
description: Stage 2 — turn an accepted intent.md into a policy-conformant spec.md
argument-hint: "<slug> — the change directory under sdlc/"
allowed-tools: Read, Write, Glob, Grep, Agent, Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*)
---

Write the spec for: **$ARGUMENTS**

Use the `spec-authoring` skill.

1. **Confirm the intent was accepted.** `sdlc/$ARGUMENTS/intent.md` must exist. If its status is still
   draft, stop and say so — Stage 2 does not start on an unaccepted intent.
2. **Read** the intent in full, then `CLAUDE.md`, the architecture and contract documents, and the
   decision records that bear on it.
3. **Load every applicable policy skill.** If this repo has none, say so explicitly — an unconstrained
   spec is a fact the reader should know.
4. **Write** `sdlc/$ARGUMENTS/spec.md` from `sdlc/templates/spec.md`.
5. **Run the `spec-critic` subagent** against the draft and address what it finds before presenting.
6. **Commit** beside the intent.

Then report, in this order: what the spec covers, what it excludes, and **every flagged conflict with
its named owner**. State that it needs product-owner sign-off, and the tech lead too for anything
higher-risk.
