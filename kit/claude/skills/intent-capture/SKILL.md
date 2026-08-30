---
name: intent-capture
description: Capture a new idea, problem, request or incident finding as a committed intent.md. Use when someone describes something they want built or fixed and no intent.md exists yet, when asked to "write up" or "capture" an idea, or when a monitoring finding or post-mortem needs to re-enter the delivery pipeline as work.
---

# Capturing intent

You are helping someone turn a problem they have into an `intent.md` that the next stage can read.
The person you are talking to is frequently **not an engineer**. Do not ask them to write requirements,
and do not ask them for a solution.

## Interview first, write second

Never produce the file from the opening message. It will be wrong in ways that are expensive later.
Ask about what is genuinely unclear — usually three to six questions, in conversation, not as a form:

- **The problem.** What happens today that should not, or does not happen that should? Ask for a
  concrete recent instance. "Customers get confused" is not usable; "forty calls a week asking where a
  claim is" is.
- **Who feels it.** Which users, which teams, which systems are on the path.
- **The outcome.** What is different afterwards, described as a state of the world rather than a
  feature. If they answer with a feature, ask what it would let someone do.
- **Constraints.** What must not change. Data that must not move, authentication that must be reused,
  a deadline, a regulation, a system nobody is allowed to touch.
- **How you would know it worked.** Push for something observable.

Stop asking when you can write the file. Two sharp questions beat six dutiful ones, and an originator
who feels interrogated stops using this.

## Then write it

Use the repo's template at `sdlc/templates/intent.md`. If it is absent, use this shape:

```markdown
# Intent: <short title>
Author: <name> (<team>). Status: draft.

## Problem
<what happens today, with a concrete instance>

## Proposed outcome
<the state of the world afterwards — not the implementation>

## Affected users and systems
<who and what is on the path>

## Constraints
<what must not change>

## Open questions
<what you could not resolve — leave these in, they are the honest part>
```

Write it to `sdlc/<slug>/intent.md`, where `<slug>` is short, lowercase and hyphenated
(`claims-status-self-service`).

## Rules

- **Keep open questions in the file.** An intent with no open questions is usually one where nobody
  asked hard enough. They are the handover to Stage 2, not a sign of incompleteness.
- **Do not design.** No file names, no endpoints, no schema, no technology. If the originator proposes
  a solution, capture it under a `## Suggested approach` heading and label it as *the originator's
  suggestion, not a decision*. Stage 2 decides.
- **Do not estimate.** Not effort, not cost, not dates.
- **Write what they said, not what you inferred.** Where you had to infer, say so in the file.
- **Show them the draft and let them correct it** before committing. This is where misunderstandings
  are cheapest to fix, and the correction is the whole point of the step.

## After writing

Commit the file on its own — the commit timestamp is the Stage 1 metric, so do not bundle it with other
work. Then say plainly that it needs the product owner to accept or close it, and that Stage 2 does not
start until they do. **Do not proceed to writing a spec**, even if asked in the same breath; that gate
is the one part of Stage 1 that must not be automated away.

For a finding arriving from monitoring or a post-mortem rather than a person: use the same template,
put the anomaly and its evidence under `## Problem`, and set the author to the detecting system.
