# Enterprise controls

`managed-settings.json` is the regulated-environment profile. **The installer will not install it**,
and that is deliberate: anything an engineer can edit is not a control against an engineer. It is
deployed by IT or the platform team, through MDM, to the managed settings path — outside the
repository, outside the user's home configuration, and not overridable by any project file or CLI flag.

Treat the shipped file as a starting point. Every value in it is an organisational decision.

## What each line buys you

| Setting | What it prevents |
|---|---|
| `permissions.deny` | Secrets being read; arbitrary network egress via `curl`/`wget`/`WebFetch` |
| `permissions.allow` | Prompt fatigue — pre-approving the safe inner loop is what keeps the deny list credible |
| `disableBypassPermissionsMode` | The one flag that would make everything above advisory |
| `allowManagedPermissionRulesOnly` | A project `settings.json` or a CLI flag widening the rules locally |
| `sandbox.failIfUnavailable` | Silent degradation to an unsandboxed session when the sandbox cannot start |
| `sandbox.network.allowedDomains` | Egress to anywhere not on the list, enforced at OS level rather than by asking |
| `credentials` | Secrets being read *and* being inherited by sandboxed subprocesses |
| `allowManagedHooksOnly` | A local hook replacing or shadowing your approval gates |
| `disableSideloadFlags` + `strictKnownMarketplaces` | Skills, agents and MCP servers arriving from anywhere but an approved marketplace |
| `allowManagedMcpServersOnly` | The tool surface growing by discovery rather than by decision |
| `requiredMinimumVersion` | Sessions running on a client version you have not reviewed |

## Getting the balance right

The two failure modes are symmetrical, and the second is the one people walk into.

**Too loose** is obvious and gets caught in audit.

**Too tight** is not obvious. An engineer who is prompted for every command stops reading the prompts,
and a control everyone clicks through has been converted into latency. The `allow` list is not a
convenience — it is what keeps the `deny` list meaningful. Pre-approve the whole inner loop generously,
and spend the strictness on egress, credentials, and the tool surface.

## Rolling it out

1. **Start in report mode where you can.** Run with the deny list and the sandbox, without
   `allowManagedPermissionRulesOnly`, for a fortnight. Collect what people actually hit.
2. **Widen the `allow` list from that evidence**, not from imagination.
3. **Then lock it.** Turn on `allowManagedPermissionRulesOnly`, `allowManagedHooksOnly` and
   `disableSideloadFlags` together — each is weak without the others.
4. **Pin `requiredMinimumVersion`** and put a named owner on moving it. An unowned version pin becomes
   a blocker within a quarter.

## Model access

If network policy or data residency prevents calling the Anthropic API directly, the same setup runs
against AWS Bedrock, Google Vertex AI, or Microsoft Foundry. That is a deployment decision that does not
change anything else in this kit — the skills, hooks, artifacts and evals are identical.
