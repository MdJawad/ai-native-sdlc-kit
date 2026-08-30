# Spec: <short title>

Source: `intent.md` (<commit SHA or date>)
Author: <name>. Status: draft | approved
Date: <YYYY-MM-DD>

## Summary

<Two or three sentences. What this change is, for someone who will not read the rest.>

## Requirements

<Numbered and testable — you should be able to write the assertion right now. Each traces to a
line in the intent.>

| # | Requirement | Traces to |
|---|---|---|
| R1 | <the system must …> | intent: Problem ¶1 |
| R2 | | |

## Out of scope

<As important as the requirements, and the section reviewers rely on most. Name the things a
reader would otherwise assume were included.>

## Design

<The components that change, the data that flows, the interfaces at the boundary. Enough that
Stage 3 can plan against it — not the file-by-file implementation, which is `plan.md`.>

## Data and privacy

<What is stored, what crosses a boundary, what is classified, what appears in logs and error
messages. Silence here is a finding, not an absence of risk.>

## Policy conformance

<Which policies were applied, and how this design satisfies each. Name them.>

| Policy | How this satisfies it |
|---|---|
| <name the skill or standard> | |

## Concerns and conflicts

<The most valuable section in the file. Where two policies cannot both be satisfied, or a
requirement cannot be met within a constraint: state it concretely, name the policies in tension,
give the options and what each costs, and name **who owns the decision**. Do not resolve it
silently by picking one.>

| Conflict | In tension | Options | Owner |
|---|---|---|---|
| | | | |

## Verification

<How someone proves this works. Feeds `plan.md`'s Proof section.>

## Decisions needing a record

<Anything load-bearing enough to owe an ADR — a dependency, a schema, a boundary, a policy
exception. Name what it will decide.>

## Open questions carried forward

<From the intent, plus anything new. A question that silently disappeared was answered by a guess.>
