---
description: Stage 6 — turn an incident, alert or scan finding into a new intent.md
argument-hint: "[the finding, an incident ID, or a path to the alert output]"
allowed-tools: Read, Write, Glob, Grep, Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*)
---

Close the loop on: **$ARGUMENTS**

Something happened in production — a control band breached, an incident, a security finding, a
post-mortem action. It re-enters the pipeline at Stage 1, in exactly the same format as an idea from a
person. That symmetry is the whole point: there is one intake, and findings do not get a lesser one.

Use the `intent-capture` skill, with these differences:

1. **Gather the evidence first.** What was observed, when, against what baseline, and what the deviation
   was. Logs, traces, the alert payload, the diff that preceded it. Be specific — the evidence *is* the
   problem statement.
2. **Write `sdlc/<slug>/intent.md`** with the anomaly and its evidence under `## Problem`, the author
   set to the detecting system or the on-call engineer, and the outcome expressed as the state of the
   world once it cannot happen again.
3. **Do not diagnose past what you can support.** A plausible root cause you have not confirmed goes
   under `## Open questions`, marked as a hypothesis. Confident wrong attribution sends the next stage
   in the wrong direction with a false sense of certainty.
4. **Say whether an eval is owed.** Every production incident earns a permanent regression eval — name
   the behaviour it should assert, and use the `eval-authoring` skill to write it.
5. **Commit**, and say it needs triage before it moves to Stage 2.

If a post-mortem is warranted, write it to `sdlc/<slug>/postmortem.md` from the template.
