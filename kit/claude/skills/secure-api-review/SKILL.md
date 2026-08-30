---
name: secure-api-review
description: EXEMPLAR — replace the rules below with your organisation's real API security standard. Applies the API security standard when creating or modifying an external-facing endpoint, reviewing API code, or generating an OpenAPI spec.
---

# Secure API review

> **This is a worked example, not policy.** It ships so you can see the shape of a policy skill: a
> narrow trigger, numbered rules that are checkable, a deterministic check to run, and a named owner.
> Replace the rules with your own standard before you rely on it, and delete this block when you do.
> A skill that looks authoritative and contains someone else's rules is worse than no skill.

When you create or change an API endpoint:

1. **Authentication.** Every endpoint requires the gateway JWT. No anonymous routes outside `/health`.
2. **Input validation.** Validate request bodies against the OpenAPI schema and reject unknown fields.
   Rejecting unknown fields is not optional — silent acceptance is how fields get added by accident.
3. **Authorisation.** Check the caller's scope against the operation before doing the work, not after.
   Returning 403 from inside the handler after a write has happened is not authorisation.
4. **Audit.** Every state-changing endpoint emits an audit event carrying actor, action, entity and
   timestamp.
5. **Data classification.** Fields tagged `pii` in the schema must never appear in logs, error
   messages, traces or exception payloads. Check the error paths specifically — that is where they leak.
6. **Rate limiting.** Every externally reachable endpoint sits behind a declared limit. If you cannot
   find the limit for the resource you are calling, say so rather than assuming there is one.

Run `scripts/check-endpoints.sh` and include its output in your summary.

## If you cannot satisfy a rule

Say so, plainly, naming the rule and why. Do not implement a partial version and describe it as done,
and do not silently drop the requirement. Route the conflict to the policy owner named below.

**Policy owner:** `<team or named role>` — set this before use. A skill with no owner cannot be kept
current, and a stale security skill is actively dangerous.

## Writing your own policy skill

The parts that make this work, in order of how often they are got wrong:

- **The `description` decides when it loads.** Write it as trigger conditions — *"use whenever creating
  or modifying an external-facing endpoint"* — not as a topic label. A description that says
  "API security guidance" will not load when it matters.
- **Rules must be checkable.** "Handle errors properly" cannot be applied or verified. "Fields tagged
  `pii` must never appear in logs or error messages" can.
- **Point at a deterministic check.** A script the model can run turns advice into evidence.
- **Back anything absolute with a hook.** A skill makes the right thing likely; only a hook makes the
  wrong thing fail. See `docs/03-governance.md`.
- **Name the owner.** Policy changes when the world changes, and an unowned skill drifts out of date
  while continuing to look authoritative.
