# The artifact chain

Every stage of the SDLC commits an artifact the next stage reads. Together they are the audit trail —
there is no separate compliance document, because keeping the trail current is the same act as doing
the work.

## Layout

One directory per change, named with a short hyphenated slug:

```
sdlc/
├── templates/                          # copy these; do not edit them in place
│   ├── intent.md · spec.md · plan.md · postmortem.md
└── claims-status-self-service/
    ├── intent.md        # Stage 1 — why. Written by the originator, accepted by the product owner
    ├── spec.md          # Stage 2 — what. Requirements + design, policy-conformant, conflicts flagged
    ├── plan.md          # Stage 3 — how. Reviewed before any code exists
    ├── review.md        # Stage 5 — findings (trunk-local profile; PR threads otherwise)
    └── postmortem.md    # Stage 6 — only if something went wrong in production
```

**Pick the slug once and never rename it.** It is how the stage-latency metrics correlate the commits,
and how a reader four months later finds the reasoning behind a diff.

## Lifecycle

| Artifact | Written by | Accepted by | Commit it |
|---|---|---|---|
| `intent.md` | originator, with Claude | product owner | on its own — the timestamp is the Stage 1 metric |
| `spec.md` | product owner, with Claude + policy skills | product owner (+ tech lead if higher-risk) | beside the intent |
| `plan.md` | engineer, in plan mode | engineer, after interrogating it | **before** implementing |
| `review.md` | the reviewer subagent | the human who triages | with the change |
| `postmortem.md` | on-call / service owner | service owner | with the eval it earns |

## Rules that make this work

- **Commit each artifact separately from the code.** Bundling `intent.md` into the implementation
  commit destroys the metric and, more importantly, destroys the evidence that thinking happened first.
- **Never rewrite history on an artifact.** A spec that changed is a spec with a second commit. The
  revision history *is* the record of what the organisation decided and when.
- **Keep open questions in the file.** An artifact with none has usually hidden something rather than
  resolved it.
- **Do not skip a stage because the change is small.** A one-line fix gets a one-paragraph intent. What
  it does not get is no intent — that is how the trail acquires holes exactly where someone will later
  need it.

## Where this fits with what you already have

**ADRs.** A `spec.md` describes *this* change; an ADR describes a constraint everything after it
inherits. When a spec makes a load-bearing choice it says so, and the ADR is written alongside, in your
existing ADR directory with your existing numbering. The `adr-authoring` skill handles this.

**A ticketing system (Jira, ServiceNow, Azure DevOps).** Three workable arrangements — pick one
deliberately, because the failure mode is having two sources of truth and no link between them:

1. **Repo is the source of truth.** The markdown is authoritative; the ticket references the commit.
2. **The ticket is the source of truth.** The markdown is a working copy, read at session start and
   written back through an MCP connector.
3. **Linkage only** — the minimum that works. Every artifact carries the record ID; every record carries
   the commit SHA. Neither is authoritative, but nothing is orphaned.

**An existing requirements or design process.** Keep it. Run the artifact chain alongside for one real
change, compare what each produced, and let the team decide. A process replaced by decree gets
performed rather than used.
