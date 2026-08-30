---
name: adr-authoring
description: Write an architecture decision record in this repo's house format, with a correctly allocated number. Use when a load-bearing decision is made — a new dependency, backend, schema, boundary or policy — or when asked to write, update or supersede an ADR.
---

# Writing an ADR

An ADR records a decision that outlives the change that prompted it. A `spec.md` describes *this*
change; an ADR describes a constraint everything after it inherits.

## Is one owed?

Write an ADR when the decision is expensive to reverse and someone will later ask why:

- a new dependency, vendor, backend or engine;
- a schema, wire format or public interface;
- a boundary — what a module may import, where vendor code may live;
- a policy with teeth, or a deliberate exception to one;
- **reversing or narrowing an earlier ADR** — this one gets missed most often.

Do **not** write one for a refactor with no external consequence, a bug fix, or a choice you would
happily remake next week. An ADR directory diluted with routine changes stops being read, and then the
real ones are invisible too.

## Get the number right

**Read the directory. Take the next free number.**

```bash
ls decisions/ | grep -oE '[0-9]{4}' | sort -n | tail -1
```

Never trust a number quoted in a plan, a spec, a ticket or a conversation — those go stale the moment
two changes are in flight, and a duplicate number is confusing for the life of the repository. Check
the filesystem at the moment you create the file.

Adjust the path and pattern to this repo's convention (`decisions/`, `docs/adr/`, `adr/` are all
common). Mirror the numbering width you find; do not introduce a new one.

## Match the house style

**Open an existing ADR in this repo and mirror its shape** before using any generic template. Most repos
carry a variant of context / decision / consequences, but the local variant is the one that belongs.
If there is genuinely no precedent:

```markdown
# ADR-NNNN: <the decision, as a statement>

Status: proposed | accepted | superseded by ADR-NNNN
Date: YYYY-MM-DD

## Context
<the forces. What is true that makes this a decision rather than an obvious step?>

## Decision
<what we will do, in the active voice: "We will …">

## Consequences
<what this makes easy, what it makes hard, what it forecloses. Include the bad ones —
an ADR listing only benefits is advocacy, not a record.>

## Alternatives considered
<what else was on the table and why it lost>
```

## Rules

- **State the decision as a decision.** "We will store money as `BigDecimal`", not "`BigDecimal` seems
  better".
- **Write the negative consequences.** They are the most valuable lines in the file, and the reason
  someone reading it in two years trusts it.
- **Never edit an accepted ADR to change its decision.** Write a new one and mark the old
  `superseded by ADR-NNNN`. The record of having changed your mind is part of the record.
- **Date it.** Absolute dates, never "last week".
- **Link it.** Reference the `spec.md` or `plan.md` that prompted it, and cite it from the code or docs
  it governs.

## After writing

Commit it with the change it belongs to, not separately — the ADR and the code that first honours it
should arrive together. Then say plainly which decision was recorded and what it now constrains.
