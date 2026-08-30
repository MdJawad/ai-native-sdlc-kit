# Spec: human approval for refunds above a threshold

Source: `intent.md` (2026-05-04)
Author: J. Okafor, with R. Lindqvist (tech lead). Status: draft — blocked on C1
Date: 2026-05-11

## Summary

Adds a third outcome to the refund authorisation check, alongside allow and refuse: **hold**. A held
refund suspends before any money moves, raises an approval request to a named duty manager in the chat
tool they already use, and completes or cancels on their answer. The pause survives a service restart,
the approver is authenticated through the existing single sign-on, and every step lands in the refund
audit log finance already reconciles against.

## Requirements

| # | Requirement | Traces to |
|---|---|---|
| R1 | The authorisation check may return `hold` for a refund, carrying an approver group and a timeout | Problem ¶2–4 |
| R2 | A held refund suspends **before** the payment provider is called, and survives a service restart | Constraints ¶3 |
| R3 | The request reaches the on-duty approver in chat, showing amount, currency, reason, order reference and who requested it | Outcome ¶1 |
| R4 | Approve and reject authenticate through existing SSO; the approver must hold the `refund:approve` entitlement they already have | Constraints ¶2 |
| R5 | An unanswered request expires at the configured timeout and resolves as **reject**, never as approve | Constraints ¶3 |
| R6 | Every transition — held, notified, approved, rejected, expired — is an audit event with actor, action, refund reference and timestamp | Outcome ¶2 |
| R7 | Thresholds are configuration, changeable by finance without a release | Constraints ¶4 |
| R8 | Refunds below the threshold behave exactly as they do today, with no added latency | Outcome ¶2 |

## Out of scope

- **Batch or standing pre-approval.** Raised in the intent's open questions and deliberately excluded.
  It converts a per-refund gate into a time-boxed spending capability — a different control, a much
  wider blast radius, and it needs its own intent.
- **Approver rota and delegation.** Depends on C2 below.
- **Approving from anywhere but chat.** No email, no SMS, no admin console.
- **Changing which refunds are allowed at all.** This adds a hold; it does not re-open permissions.

## Design

The refund authoriser returns `HOLD` alongside `ALLOW` and `REFUSE`, carrying `approver_group` and
`timeout_seconds`. It is currently a two-valued result used in four call sites, which is why an ADR is
owed.

On `HOLD`, the refund service writes an `approval_request` row, emits the request over a notification
port, and returns *pending* to its caller rather than calling the payment provider. **Approval state
lives in the database, not in memory** — that is what makes R2 hold across a restart, and it is the
whole reason this is not simply a blocking call.

`approvals/` is a new module holding the state machine and an `ApprovalChannel` port. The chat
implementation goes in `approvals/adapters/chat/`; nothing outside that directory imports the chat
vendor's SDK, so a second channel is an adapter rather than a rewrite.

Inbound approve/reject arrives at an endpoint that validates the SSO token and checks the
`refund:approve` entitlement through the same authorisation path as the rest of the service. There is
no second identity mechanism.

Thresholds live in the existing runtime configuration store that finance already edits for fee rules.

## Data and privacy

The request carries what a duty manager needs to decide and nothing else: amount, currency, refund
reason, order reference, the requesting agent, and a correlation ID.

It carries **no** card number, no bank details, no full customer name, no address. The approver opens
the order in the existing admin tool, behind their existing login, if they need more.

Audit events record the approver's identity and their decision. The message stored in the chat vendor's
workspace sits under that vendor's retention, not ours — which is C1.

## Policy conformance

| Policy | How this satisfies it |
|---|---|
| Money handling standard | Amounts stay decimal end to end; the approval carries the same amount object the refund does, never a re-parsed string |
| Authorisation standard | The entitlement is checked before the work, on the existing path, not inside the handler afterwards |
| Data classification standard | No field classified `pci` or `pii` enters the message body |
| Audit standard | Every state change is an event with actor, action, entity and timestamp |
| Availability standard | R8 — the unheld path gains no synchronous call and no added latency |

## Concerns and conflicts

**C1 — Audit completeness against no-customer-data-in-chat. BLOCKING.**
Our audit standard wants the record of what was approved to be complete and held by us. The data
classification standard says customer data must not enter a third-party workspace we do not control.
Both are satisfiable for the *fields* — the body carries none — but not for the *message*: it is stored
in the vendor's workspace under their retention, so part of the exchange sits outside our audit
boundary whatever the body contains.

Options: **(a)** accept it, and state in the audit record that the chat copy is vendor-retained, which
is cheap and makes an existing implicit boundary explicit; **(b)** send only a correlation ID and force
every approver into the admin tool, which satisfies both cleanly and will be ignored in practice
because it makes the fast path slow; **(c)** build our own approval surface, which is a much larger
change and re-opens the identity question R4 closes.

Recommendation is (a). **Owner: data protection officer — not yet named. This spec cannot be accepted
until they have.**

**C2 — Rota and delegation. Non-blocking; descopes cleanly.**
The intent asks who approves when the duty manager is away. There is a rota for the manual process, but
it is a spreadsheet keyed by shift rather than by identity, so it is not directly usable. Modelling it
properly is comparable in size to this whole change.

Proposed: ship against an approver *group* rather than an individual, so anyone on duty with the
entitlement can answer, and let R5's expiry be the backstop. Raise the rota as its own intent.
**Owner: R. Lindqvist (tech lead) — accepted 2026-05-11.**

**C3 — A refund held while the bank reverses the charge anyway. Non-blocking, undecided.**
From the intent's open questions. If the original payment is reversed while approval is pending, an
approver could approve a refund that must no longer happen. Cheapest correct behaviour is to expire the
request when the underlying payment changes state and tell the approver why. **Owner: R. Lindqvist.**

## Verification

- An end-to-end test: a refund above the threshold holds, notifies, is approved, and only then calls
  the payment provider — including a restart between hold and approval.
- A test that expiry resolves as reject and the provider is never called.
- A test that a below-threshold refund takes the unchanged path and gains no provider round-trip.
- An authorisation test: a user without `refund:approve` cannot answer.
- The full verification command green.

## Decisions needing a record

**An ADR is owed.** The authorisation result becomes three-valued, which changes an interface with four
call sites. The ADR must state what a caller that does not understand `HOLD` must do — treat it as
`REFUSE`, fail closed — and that approval state is owned by the database rather than by the request.
Take the next free number from the decision-record directory when you write it.

## Open questions carried forward

- Rota and delegation — carried to C2, descoped, owner accepted.
- Payment reversed mid-approval — carried to C3, owner assigned, undecided.
- Batch pre-approval — explicitly out of scope. Needs its own intent if operations still want it.
- New: is one timeout enough, or should a £5,000 refund wait longer than a £600 one? Deferred until
  there is data from the first month.
