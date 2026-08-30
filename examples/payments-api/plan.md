# Plan: human approval for refunds above a threshold

Source: `spec.md` (2026-05-11, C1 resolved 2026-05-14 — option (a), signed off by the data protection officer)
Author: R. Lindqvist. Status: accepted
Date: 2026-05-15

## Approach

Add `HOLD` to the refund authorisation result, make the refund service suspend on it *before* calling
the payment provider, and keep approval state in the database so the wait survives a restart. The chat
channel sits behind a port with one adapter.

**Rejected — hold the caller's HTTP connection open and block.** Much the simplest, and wrong. It fails
R2 on any restart or deploy, and ties an approval that may take fifteen minutes to a request timeout
measured in seconds.

**Rejected — a scheduled job that polls for approved refunds and completes them.** Avoids the
suspension entirely, and puts an unbounded delay between approval and the money moving. A duty manager
who approves and watches nothing happen for four minutes will approve it again.

**Rejected — a separate approvals service.** It is one table, one state machine and one adapter. A
fifth deployable for that is a cost with no benefit until something else needs approvals too.

## Files that change

| Path | New/Modified | What happens |
|---|---|---|
| `src/refunds/authoriser.py` | modified | `Result` gains `HOLD`; `HoldDetails` (approver_group, timeout_seconds) |
| `src/refunds/service.py` | modified | on `HOLD`: persist, notify, return pending — **before** any provider call |
| `src/approvals/__init__.py` | new | the module: state machine, `ApprovalRequest` model |
| `src/approvals/port.py` | new | the `ApprovalChannel` port |
| `src/approvals/adapters/chat/` | new | the chat adapter. **The only place the vendor SDK is imported.** |
| `src/api/routes/approvals.py` | new | inbound approve/reject; validates SSO and the `refund:approve` entitlement |
| `migrations/0042_approval_requests.py` | new | the `approval_requests` table, with an index on state and expiry |
| `config/thresholds.yaml` | new | the amounts, editable by finance without a release (R7) |
| `tests/e2e/test_refund_hold.py` | new | hold → notify → approve → provider called, including a restart |
| `tests/e2e/test_refund_expiry.py` | new | expiry resolves as reject; the provider is **never** called |
| `tests/e2e/test_refund_below_threshold.py` | new | unchanged path, no extra provider round-trip (R8) |
| `tests/api/test_approval_authz.py` | new | a user without `refund:approve` gets 403 |
| `docs/adr/NNNN-refund-hold-outcome.md` | new | **take the next free number from the directory when you write it** |
| `CLAUDE.md` | modified | the new module in the architecture section |

## Order of work

1. **`HOLD` and `HoldDetails` in the authoriser.** Nothing returns it yet; all four call sites still
   see allow/refuse. Verification green here.
2. **The ADR.** Before anything depends on the three-valued result, not after.
3. **`approvals/`: model, migration, state machine, port.** No channel, no service wiring. Unit-tested
   in isolation, including that an unknown state is treated as reject.
4. **Suspension in the refund service, with a fake channel.** `test_refund_hold.py` and
   `test_refund_below_threshold.py` land here and pass without any chat integration existing.
5. **Restart survival.** The restart case in `test_refund_hold.py` starts passing at this step.
6. **The chat adapter and the inbound endpoint.** The first step touching a vendor SDK, and the last
   that can break anything already working.
7. **`config/thresholds.yaml`, the expiry job, `test_refund_expiry.py`, `test_approval_authz.py`.**

## Risks

| Risk | Likelihood | What we do about it |
|---|---|---|
| A call site that does not understand `HOLD` treats it as allow, and money moves unapproved | Low, catastrophic | The ADR states it; the enum default and the service both treat an unrecognised result as refuse. A test asserts a malformed hold refuses. **This is the risk the change lives or dies on.** |
| The provider is called before the hold is persisted, so a crash double-refunds | Medium, severe | Persist first, then notify, then return. The provider call happens only on the approval path. `test_refund_hold.py` asserts call ordering, not just the outcome. |
| Expiry job does not run; requests sit pending forever | Medium | Expiry is computed on read as well as swept by the job, so a stalled sweeper delays cleanup rather than leaving a request answerable. |
| Chat delivery fails silently and the request expires as reject | Medium | Delivery failure is its own audit event and is visible in the admin tool. Expiry-as-reject is correct but must be distinguishable from "nobody answered". |
| Finance edits `thresholds.yaml` to something that holds every refund | Low, noisy | Validate on load: reject a threshold of zero, warn below £50, and fall back to the last good config rather than failing closed on every refund. |
| Approval state drifts from refund state | Medium | The refund remains authoritative. Approval rows reference it and never the reverse. Stated in the ADR. |

## Proof

- [ ] `tests/e2e/test_refund_hold.py` — hold → notify → approve → provider called **once**, and the
      same across a restart between hold and approval
- [ ] `tests/e2e/test_refund_expiry.py` — unanswered request rejects; provider never called
- [ ] `tests/e2e/test_refund_below_threshold.py` — below-threshold path unchanged, no added round-trip
- [ ] `tests/api/test_approval_authz.py` — no `refund:approve` entitlement → 403
- [ ] Full verification command green
- [ ] Manual: issue a £750 test refund in staging, approve it in chat, and confirm the message body
      contains no card, bank or address field

## Decision record owed

**Yes.** The refund authorisation result becomes three-valued: what `HOLD` means, that an unrecognised
result is treated as `REFUSE`, that approval state is owned by the database rather than the request,
and that the channel is a swappable adapter. **Read the decision-record directory for the next free
number when you write it — do not use a number quoted in this plan or in `spec.md`.**
