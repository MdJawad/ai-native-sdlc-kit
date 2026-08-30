# Plan: <short title>

Source: `spec.md` (<commit SHA or date>)
Author: <name>. Status: proposed | accepted
Date: <YYYY-MM-DD>

## Approach

<Two or three sentences on the shape of the change, and — briefly — what you rejected and why.
One line per rejected alternative. It is the fastest way for a reviewer to tell whether you
understood the problem.>

## Files that change

| Path | New/Modified | What happens |
|---|---|---|
| `<real/path/to/file.ext>` | new | |
| | modified | |

<Real paths only. Not "the handler" — `services/claims/routes/status.py`. This is the section
reviewers use to spot a change reaching somewhere it should not.>

## Order of work

1. <Each step a state where the repo still builds and can be verified. If a step cannot be
   verified on its own, it is two steps — or one badly sized one.>
2.
3.

## Risks

<What could break, what is uncertain, what has a blast radius wider than the diff. Rate limits,
migrations, concurrency, backwards compatibility, anything with a rollback question. A plan with
no risks named has not been thought about.>

| Risk | Likelihood | What we do about it |
|---|---|---|
| | | |

## Proof

<The specific tests, commands and observations that will show this worked. Name the test files and
what each asserts. "Tests pass" is not proof; "`test_status.py` covers the four claim states" is.>

- [ ] `<test file>` — asserts <what>
- [ ] `<verification command>` — green
- [ ] <observation, screenshot, or manual check>

## Decision record owed

<Yes / No. If yes: what it decides, and the ADR number taken from the directory at the time of
writing — never a number quoted from a document.>
