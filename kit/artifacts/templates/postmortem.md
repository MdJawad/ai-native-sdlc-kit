# Post-mortem: <short title>

Incident: <ID or date>. Author: <name>.
Detected by: <alert, control band, customer report, scheduled scan>
Date: <YYYY-MM-DD>

## What happened

<Plain narrative. What broke, what the effect was, who noticed and how.>

## Timeline

| Time (UTC) | Event |
|---|---|
| | |

## Impact

<Who was affected, how many, for how long, and what they experienced. Numbers where you have them
and an explicit "unknown" where you do not.>

## What we know, and what we believe

<Separate these. Confirmed cause goes under "know"; a plausible cause you have not proven goes
under "believe", marked as a hypothesis. Confident wrong attribution sends the next change in the
wrong direction with a false sense of certainty.>

**Confirmed:**

**Hypothesis, unconfirmed:**

## Why the existing controls did not catch it

<The gates, tests, evals, hooks and reviews that were in place, and why each one passed. This is
the section that changes anything.>

## Actions

| Action | Type | Owner | Where it lands |
|---|---|---|---|
| | fix / eval / control / doc | | `sdlc/<slug>/intent.md`, ADR-NNNN, `evals/cases/…` |

## Eval owed

<Every production incident earns a permanent regression eval. Name the behaviour it asserts.
If you conclude none is owed, say why — that conclusion is usually wrong.>

## What we are not doing

<The actions considered and deliberately declined, with the reason. A post-mortem where every
suggestion became an action item produces a backlog nobody works, and the next one is taken less
seriously.>
