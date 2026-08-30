---
description: Stage 5 — review the current change against REVIEW.md in named passes
argument-hint: "[base ref — defaults to the repo's trunk branch]"
allowed-tools: Read, Grep, Glob, Agent, Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git merge-base:*), Bash(git branch:*)
---

Review the current change against **$ARGUMENTS** (if empty, work out the trunk from `CLAUDE.md` or
`CONTRIBUTING.md` and say which you picked).

1. **Get the diff.** `git diff <base>...HEAD`. Report its size before reviewing — a diff too large to
   review honestly should be said out loud, not quietly skimmed.
2. **Run the `reviewer` subagent** against it. It reads `REVIEW.md`, `plan.md`, `spec.md` and
   `CLAUDE.md`, and runs the bugs / security / compliance passes with the nit cap applied.
3. **Present the findings** grouped by pass, Important first, nits capped with a count of the rest.
4. **Write them to** `sdlc/<slug>/review.md` if the change has an `sdlc/` directory — the findings are
   part of the audit trail, not just a message in a terminal.

Then stop. **Do not apply the findings in this session.** The thing that wrote the code does not get to
decide which criticisms of it were valid; a human triages, and fixes land as their own change.

If a finding reveals a mistake this repo has now seen twice, say so and propose the correction for
`CLAUDE.md` — that is the feedback loop that makes the next review shorter.
