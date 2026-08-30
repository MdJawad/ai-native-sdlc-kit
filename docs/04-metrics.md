# Metrics

The playbook pairs every stage with a **leading** indicator (moves within days, tells you the practice
is being used) and a **lagging** indicator (moves over months, tells you it worked). Both matter, and
the common failure is reporting only the leading ones, because they are the flattering ones.

Almost all of these come out of git history. That is the point of committing artifacts.

## The set

| Stage | Leading | Lagging |
|---|---|---|
| 1 Plan | Time from first conversation to committed `intent.md` | Survival rate of intents into Stage 2; rework on `intent.md` after the first `spec.md` |
| 2 Design | Elapsed time `intent.md` → `spec.md` | `spec.md` commits dated after the first `plan.md` — i.e. requirements churn once building started |
| 3 Build | Share of changes merging from the first implementation pass | Rework cycles per change; whether the merged diff still matches `plan.md` |
| 4 Test | First-pass CI success on agent-written changes; eval pass rate | Review time per PR; change failure rate |
| 5 Deploy | Time to first review; findings resolved without a human touching the branch | Defects caught before merge vs. escaped to production |
| 6 Maintain | Time from band breach to `intent.md` in the triage queue | Share of findings that become merged fixes; repeat incidents |

## What the kit computes for you

Two scripts, both read-only, both operating on git history in the target repo.

```bash
scripts/metrics/stage-latency.sh --target /path/to/repo
```

For every change slug under `sdlc/`, reports the wall-clock gap between the commits that introduced
`intent.md`, `spec.md` and `plan.md`. This is Stage 1's and Stage 2's leading indicator, measured rather
than asserted.

```bash
scripts/metrics/artifact-coverage.sh --target /path/to/repo --since 90.days
```

What share of merges into the trunk have a `plan.md` committed against them. This is the honest measure
of adoption: a team that says it is doing this and has 12% coverage is not doing this.

## Reading them without fooling yourself

**Latency falling is not the win.** It is the signal that the practice is being used. The win is in the
lagging column — less rework, fewer escaped defects — and it shows up a quarter later. A team that
reports "idea to intent fell from three weeks to four hours" and nothing else has measured its own
enthusiasm.

**Watch the rework indicators hardest.** They are the ones that catch this going wrong. Requirements
churning after build starts means specs are being written too thin to be useful. A merged diff that no
longer resembles its `plan.md` means plan review is theatre.

**Coverage before latency.** A brilliant latency number over 12% of changes tells you about the 12%.

**One counter-metric, always.** Every velocity number gets a quality number beside it. Changes merged
per engineer per week is meaningless without rework rate next to it — the two move together when
something is wrong, and the pair is what makes it visible.

**Do not put these in a performance review.** Every one of them is trivially gameable by someone who
needs the number to move, and the gaming damages the practice itself. They exist to tell the team
whether its own process is working.

## Instrumenting further

For anything beyond git history — hook block rates, time spent waiting on approval gates, per-session
tool use — enable Claude Code's OpenTelemetry export and send it to whatever you already run. That is
where Stage 5's "time spent waiting on each gate" comes from, and it is the number most likely to
identify the real remaining bottleneck once the build stops being it.
