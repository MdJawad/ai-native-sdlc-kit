# Adoption path

Stages are independent. You do not need to adopt six at once, and a team that tries usually gets none
of them. What follows is the order that pays back fastest, based on what most repositories are already
missing.

## Before anything: two prerequisites

**1. Is `.claude/` version-controlled?** Check your `.gitignore`. A great many repos ignore the whole
directory as "local agent config", which is reasonable right up until agent configuration becomes
something you want reviewed, owned and diffed. If `.claude/` is ignored, none of this kit's skills,
hooks or subagents can be shared, and the installer will stop and tell you so.

The narrow fix, which keeps the genuinely local things local:

```gitignore
# Agent configuration is reviewed code — only these are local
.claude/settings.local.json
.claude/worktrees/
```

**2. Is there one command that verifies the repo?** A single target that exits non-zero on failure —
`make all`, `npm test`, whatever. Without it, Stage 4 has nothing to stand on and every session hands
you unverified work. If you do not have one, build it first. It is worth more than anything else here.

---

## Week one — Build and Test (Stages 3 and 4a)

The fastest payback, and it needs no process change from anyone outside the engineering team.

```bash
install/install.sh --target /path/to/repo --profile trunk-local --modules claude-md,skills,hooks,agents
```

- **`CLAUDE.md` with a verification block.** State the commands, what healthy output looks like, and
  that running them is part of "done". If you already have a `CLAUDE.md`, the installer appends one
  marked block and leaves the rest of your file alone.
- **Two hooks, chosen for being unarguable.** `protect-tests.sh` stops an agent editing a test to make
  a failure disappear. `protect-paths.sh` guards generated and frozen directories. Neither is
  controversial, and both convert a rule people already believe in into a rule that holds.
- **The `verifier` subagent.** It runs the change and reports what it saw. It is not allowed to fix
  anything, which is what makes its report worth reading.

**How you know it worked:** the share of sessions that hand back a change with the gates already green.
Track it informally for a fortnight before you instrument anything.

## Week two to four — the artifact chain (Stages 1, 2, 3)

```bash
install/install.sh --target /path/to/repo --modules artifacts,skills,commands
```

Introduce `intent.md` → `spec.md` → `plan.md`. Do it on **one real change**, end to end, and commit all
three. A filled-in chain that someone can read beats any amount of explanation — that is exactly why
this repo ships [`examples/payments-api/`](../examples/payments-api/).

Resist writing the whole template set for your organisation first. Use the shipped templates on a real
change, notice which fields you never fill in, and delete those.

## Month two — Review (Stage 5)

```bash
install/install.sh --target /path/to/repo --modules review
```

Write `REVIEW.md`. The three things that decide whether it works:

1. **Passes, named.** Bugs, security, compliance-with-the-spec. Tag every finding with its pass.
2. **A definition of *Important*.** Reserve it for things that break behaviour, leak data or breach
   policy. Everything else is a nit, and say so.
3. **A nit cap.** Five, then a count. An uncapped reviewer produces output nobody reads, which is worse
   than no reviewer because it burns the team's willingness to try.

Then tune it monthly. Rate the findings; feed the pattern back into `CLAUDE.md`.

## Month three — agent-configuration evals (Stage 4b)

```bash
install/install.sh --target /path/to/repo --modules evals,ci
```

By now you have skills and hooks that people depend on, and no way to tell whether editing them made
things worse. Collect 20–50 real tasks from recent work, write each as a prompt plus checks, and gate
changes to `CLAUDE.md` and `.claude/**` on the results.

Start with three cases. Three that run beat fifty that were designed and never wired up.

## Month four onward — close the loop (Stage 6)

```bash
install/install.sh --target /path/to/repo --modules maintain
```

Pick **one** metric with a stable rolling baseline — CI failure rate is usually the easiest, because
you already have the data and nothing in production is at risk. Set the bands, wire the trigger, and
let it run at `log` and `diagnose` tiers only for a month before you let anything act at 3σ.

---

## The order not to use

Do not start with Stage 6. It is the most impressive to demonstrate and the least valuable to adopt
first: an autonomous loop feeding findings into a process that cannot yet absorb them produces a queue
of `intent.md` files nobody triages, and the experiment gets written off.

Do not start with evals either. Evals regression-test agent configuration; write the configuration
first or there is nothing to protect.

## Rollout across many repos

Once one repo works, distribute the `.claude/` half as a plugin (see [`../INSTALL.md`](../INSTALL.md))
so policy skills update centrally. Keep using the installer for everything the plugin cannot carry:
CI workflows, artifact templates, `REVIEW.md`, and the `.gitignore` fix.
