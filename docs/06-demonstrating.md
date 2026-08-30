# Demonstrating this in twenty minutes

A runbook for showing the process to another team. It is a demonstration of a *loop*, so it has to
end where it started — that is the part people remember.

**Prepare beforehand.** Have a repo with the kit installed and a real, small change picked out. Have a
second terminal open. Do not demo on a repo you have never run the gates on.

## The shape

| Minutes | Beat | What they see |
|---|---|---|
| 0–2 | The argument | One slide or one sentence: code stopped being the bottleneck; the process around it did not move |
| 2–5 | Stage 1 | You *talk* to Claude about a problem. It asks you things. `intent.md` appears and gets committed |
| 5–8 | Stage 2 | `intent.md` → `spec.md`, with a policy skill loaded — and a **flagged conflict** |
| 8–13 | Stage 3 | Plan mode. Claude cannot edit. You interrogate the plan, change it, *then* accept |
| 13–16 | Stage 4 | The session runs the gates itself. Then try to edit a test — the hook blocks it |
| 16–18 | Stage 5 | `/review` against `REVIEW.md`. Three passes, nits capped |
| 18–20 | Stage 6 | A band breach writes a new `intent.md`. Point at the screen from minute 2 |

## The three moments that land

Everything else is context. These are what people repeat afterwards.

**1. The flagged conflict (minute 7).** Have a spec where two of your policies genuinely disagree —
easiest is a data-handling rule against a UX rule. Claude writes the spec and says it cannot satisfy
both, and names them. The point to make out loud: *that conversation used to happen in a review, six
weeks later, after the code was written.*

**2. The blocked test edit (minute 15).** Ask Claude to make a failing test pass. Watch it reach for the
test file. Watch the hook stop it. Then show `protect-tests.sh` — it is nine lines.

> "The rule was already in our contributing guide. It held about as often as people were reading
> carefully. Now it is a fact."

This is the moment the governance argument stops being abstract. Do not rush it.

**3. Closing the loop (minute 19).** Trip a control band and let it write an `intent.md`. Open the file
from minute 2 beside it — same template, same directory, same shape. The loop is closed, and nobody
typed the second one.

## Questions you will be asked

**"Does the AI approve its own work?"** No, and the design forbids it. Show the profile: in
`pr-github`, branch protection and the agent identity; in `trunk-local`, the coordinator's merged-tree
gate. Then show a hook blocking a push. Answer this one with the mechanism, never with reassurance.

**"What if the model changes and everything behaves differently?"** That is exactly why Stage 4b exists.
`CLAUDE.md`, skills and hooks are model inputs, so they get regression tests. Show `agent-evals.yml`
and its `paths:` trigger.

**"Isn't this a lot of files?"** Show `install.sh --dry-run`. The whole thing is one command, and the
week-one subset is four modules.

**"Our repo does not work like the blog post."** Good — nor do most real repos, which is why the kit
ships two profiles instead of one. Show [`05-profiles.md`](05-profiles.md) and the `trunk-local`
profile. The kit adapts to your integration model; the separation-of-duties requirement is the only
thing that does not bend.

**"Where does our existing Jira/ADR/contract process go?"** Three options, and the middle one is usually
right: repo as source of truth, legacy system as source of truth with markdown as working copy, or —
most commonly — both, linked by ID in the artifact and commit SHA in the ticket. Pick one deliberately;
the failure is having two sources of truth and no link.

## Do not

- **Do not demo Stage 6 first.** It is the most impressive and the least adoptable. A team that leads
  with the autonomous loop gets asked to justify autonomy before it has shown the guardrails.
- **Do not hide the flagged conflict.** A demo where the AI agrees with everything teaches the audience
  that the AI agrees with everything.
- **Do not run `--dangerously-skip-permissions` on screen.** You will spend the rest of the session on
  that instead of the process.
