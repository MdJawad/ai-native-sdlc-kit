# Review instructions

The policy this repository's reviewers — human and agent — apply to every change.

> **Tune this file.** It ships with defaults that are sane and generic. The three things worth
> changing first are the *Do not report* list, the definition of *Important*, and the nit cap. A review
> policy nobody has edited is one nobody has agreed to.

## Passes

Run three passes and **tag every finding with its pass**. Do not merge them — the tags are what let a
reader triage in ten seconds instead of ten minutes.

- **Bugs** — logic errors, unhandled edge cases, subtle regressions, concurrency, error paths that
  swallow failures, resource leaks.
- **Security** — injection, authentication and authorisation gaps, secrets in code or logs, PII in log
  lines and error messages, unsafe deserialisation, dependency risk.
- **Compliance** — does the change match `spec.md` and `plan.md`? Does it hold the invariants in
  `CLAUDE.md`? Did it touch files the plan never mentioned?

## What *Important* means here

Reserve **Important** for findings that would **break behaviour, leak data, or breach a stated policy**.
Style, naming and preference are nits.

Applying this honestly is most of the job. A review where everything is Important is a review where
nothing is, and the team stops reading within a fortnight.

An Important finding must be **concrete**: the input or state, and the wrong output or crash it
produces. If you cannot make it concrete, it is a suspicion — say so, or drop it.

## Cap the nits

Report at most **five** nits per review, then summarise the rest as a count.

An uncapped review is not read, and a review that is not read is worse than no review, because it
consumes the team's willingness to have one.

## Do not report

- Anything CI already enforces — formatting, lint, import order, type errors. It is noise, and the
  reader learns to skim you.
- Generated files, vendored dependencies, lockfiles.
- Test fixtures and golden files, unless the assertion itself is wrong.
- Preferences with no defensible reason. "I would have written this differently" is not a finding.

<!-- Add your repo's paths here, e.g.:
- Generated code under `src/gen/`
- Anything under `vendor/`
-->

## Reporting a finding

- File and line.
- Pass, and Important or nit.
- What is wrong. For Important: the concrete failure.
- The suggested fix, briefly.

**Say when you found nothing.** "No Important findings; three nits" is a complete review. Manufacturing
a finding to look diligent is the fastest way to make this gate worthless.

## Who decides

Findings do not approve or block on their own. A named human approves — see the profile in
`docs/05-profiles.md`. The agent that wrote the change is never that human.

## Feeding it back

When a review surfaces a mistake this repo has now seen **twice**, the correction goes into
`CLAUDE.md`. Once is noise; twice is a pattern, and a pattern belongs in the file every session reads.

Rate the reviewer's findings monthly. If the useful-to-noise ratio is falling, tighten *Do not report*
before you tighten anything else — over-reporting is almost always the cause.
