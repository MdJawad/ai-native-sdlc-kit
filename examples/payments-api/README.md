# Worked example: `refund-approval-threshold`

A filled-in artifact chain for one change to a fictional payments service. Reference material — nothing
installs it, and the service does not exist.

Read them in order. They show what the templates look like when used properly, and in particular what
Stage 2 is *for*: `spec.md` carries two flagged conflicts that would otherwise have surfaced in review,
after the code was written.

| File | Stage | What to notice |
|---|---|---|
| [`intent.md`](intent.md) | 1 | Written by operations, not engineering. Describes a problem, not a feature. Open questions kept in. |
| [`spec.md`](spec.md) | 2 | Every requirement traces to a line in the intent. **Two flagged conflicts with named owners**, one blocking. An owed ADR. An explicit out-of-scope section. |
| [`plan.md`](plan.md) | 3 | Real-looking paths, a work order where every step still builds, three rejected alternatives with reasons, and proof naming the tests. |

The change was never built. These are the artifacts as they would stand at the moment the plan is
accepted and implementation begins.

**Everything here is fictional** — the service, the people, the incident, the thresholds.
