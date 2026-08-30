## The SDLC artifacts

<!-- sdlc-ai:begin artifacts -->
<!-- Managed by sdlc-ai. Keep the markers so upgrades can replace this block cleanly. -->

Work in this repo carries a committed artifact chain in `sdlc/<slug>/`:

| Stage | Artifact | Command |
|---|---|---|
| 1 Plan | `intent.md` — why this is worth doing | `/intent` |
| 2 Design | `spec.md` — what, conformant to policy, conflicts flagged | `/spec <slug>` |
| 3 Build | `plan.md` — how, reviewed before any code exists | `/plan <slug>` |
| 5 Deploy | review findings against `REVIEW.md` | `/review` |
| 6 Maintain | a new `intent.md`, closing the loop | `/close-loop` |

Read `sdlc/README.md` for the rules. Two that matter most: commit each artifact **separately from the
code** — bundling them destroys the metric and the evidence that thinking happened first — and **never
rewrite an artifact's history**; a spec that changed is a spec with a second commit.

<!-- sdlc-ai:end artifacts -->
