# Why this exists

## The argument

Code is no longer the bottleneck.

Every SDLC process in wide use was designed when implementation took weeks. Planning, design, review
and release ceremonies were sized against that. Implementation has since collapsed to hours, and the
ceremonies have not moved — so the constraint has quietly relocated to the human-speed steps around the
build. A team that adopts AI coding tools and changes nothing else gets faster at the one step that was
never the problem, and then queues.

The response is not to remove the human steps. It is to change what humans spend their judgement on,
and to make the handoffs machine-readable so the loop can close.

## What actually changes

**Documents become artifacts.** A requirements document is written for a person, read once, and rots.
An `intent.md` is written for a person *and* a model, version-controlled, diffable, and read by the
next stage as input. Same information, radically different half-life.

**Review moves earlier.** Reviewing generated code is the expensive place to catch a wrong approach.
Reviewing a written plan before any code exists is the cheap place. Plan mode makes this structural
rather than a matter of discipline.

**Policy moves from review-time to authoring-time.** A security standard enforced by a reviewer is
applied inconsistently, weeks late, by whoever happened to be on the PR. The same standard written as a
skill is applied while the code is being written, every time, by everyone.

**Governance becomes executable.** "Never push from a unit" written in a contributing guide is a hope.
The same rule as a `PreToolUse` hook is a fact. The distinction between those two — advisory and
deterministic — is the single most useful idea in the playbook, and most of this kit is built around it.

**The audit trail is free.** Intent, spec, plan, diff, findings — all commits, all timestamped, all
attributed. There is no separate compliance artefact to keep current, because keeping it current is the
same act as doing the work.

## Why a kit and not a document

Anthropic's [AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) is the
source material and it is good. But it ships as prose, and prose has a predictable failure mode inside
a large organisation: every team reads it, agrees with it, and implements a different subset with
different file names. Six months later nothing is comparable, nothing is reusable, and the second team
to try it starts from zero.

So this repository turns the playbook into something you install:

- **Idempotent.** Run the installer twice and the second run changes nothing. Run it again after a kit
  upgrade and it updates only what moved.
- **Merging, not clobbering.** Target repos already have a `CLAUDE.md` and a `settings.json` worth
  keeping. The installer adds to them; it never rewrites them.
- **Modular.** Adopt Stages 1–3 this quarter and Stage 6 next year. Stages are independent by design.
- **Profiled.** Trunk-based local merges and PR-with-branch-protection are both legitimate. The kit
  ships both and makes you choose deliberately.

## What this kit deliberately does not do

- **It does not decide your policy.** `secure-api-review` is an *exemplar* skill. Your security
  standard is yours to write; the kit gives you the shape and the loading mechanism.
- **It does not replace a judgement gate with automation.** Every stage keeps a named human decision.
- **It does not install enterprise controls.** `kit/enterprise/managed-settings.json` is deployed by IT
  through MDM, because a control an engineer can edit is not a control. See
  [`03-governance.md`](03-governance.md).

## Read next

1. [`01-stages.md`](01-stages.md) — the vocabulary. Read this before anything else.
2. [`02-adoption-path.md`](02-adoption-path.md) — what to do in week one.
3. [`../INSTALL.md`](../INSTALL.md) — how to put it in a repo.
