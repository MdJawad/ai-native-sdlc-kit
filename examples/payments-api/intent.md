# Intent: stop refunding the wrong amount to the wrong account

Author: J. Okafor (payments operations).
Status: accepted
Date: 2026-05-04

## Problem

The support assistant can issue a refund directly. It either has permission or it does not, and today
it does, up to any amount.

That has cost us twice in six weeks. In March a duplicate-charge refund went out at ten times the
charge — a decimal in the amount the agent parsed out of an email thread — and we found it when the
customer told us. In April a refund went to the right customer's *older*, closed card, which took
eleven days and two people to unwind.

Both were legitimate refunds. Neither was a permissions problem, so tightening permissions does not
fix them: the agent was allowed to do exactly what it did. What was missing was anyone looking at the
unusual ones before the money moved.

We already have a person for this. Refunds over £500 go to a duty manager under the manual process,
and they turn round in minutes. The assistant cannot ask them, because there is nowhere to ask.

## Proposed outcome

A refund that is large or unusual pauses and asks a named human, in the tool they already sit in all
day. They see enough to decide, they answer, and the refund goes out or does not. The whole exchange is
in the record we already keep for refunds.

Small routine refunds keep going out automatically. This is for the band that today is either waved
through or would have to be blocked entirely.

## Affected users and systems

Duty managers in support operations. The payments service and whatever it calls to move money. The
support assistant. The audit log that finance reconciles against monthly. The people who set the
thresholds, who are in finance, not engineering.

## Constraints

- **No card numbers or bank details anywhere new.** They are not in the assistant's context today and
  must not start being.
- **No new login.** The approver signs in the way they already do. Anyone who can approve here must be
  someone who could approve today.
- It must do something sensible when nobody answers. A refund that hangs indefinitely is its own
  incident, and it is the customer who feels it.
- Finance must be able to change the thresholds without an engineering release.

## How we would know it worked

No refund over the threshold moves money without either an automatic decision or a named person behind
it — and the two incidents above could not recur. Duty managers should see roughly the same number of
approvals they handle manually today, not more.

## Open questions

- Who approves when the duty manager is at lunch? There is a rota for the manual process; is it
  reusable, or does it need modelling separately?
- What happens to a pending approval when the customer disputes the charge in the meantime, or the
  original payment is already being reversed by the bank?
- Operations asked whether a manager can pre-approve a batch — "everything from this incident, up to
  £2,000". That sounds like a different thing with a much wider blast radius.
