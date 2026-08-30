# Changelog

Target repos pin a kit version in `.sdlc-ai/manifest.lock`. Re-running the installer upgrades them.

## 0.1.0 — 2026-08-30

First public release. Covers all six stages of the
[AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook). Apache-2.0.

**Kit**
- Six skills: `intent-capture`, `spec-authoring`, `implementation-plan`, `adr-authoring`,
  `eval-authoring`, and `secure-api-review` (an exemplar policy skill).
- Three subagents: `verifier`, `reviewer`, `spec-critic`.
- Five commands: `/intent`, `/spec`, `/plan`, `/review`, `/close-loop`.
- Five hooks: `protect-tests`, `protect-paths`, `no-remote-push` (trunk-local),
  `production-gate` (pr-github), `format-after-edit`. All fail closed.
- Artifact chain: `intent.md`, `spec.md`, `plan.md`, `postmortem.md` templates plus `sdlc/README.md`.
- `REVIEW.md` with named passes, a definition of *Important*, and a nit cap.
- Stage 4b eval harness (`run.sh`, `check.sh`, seven check types) and three exemplar cases.
- CI: `agent-evals.yml`, `claude-review.yml`, `pre-merge-gate.sh`.
- Stage 6: `bands.yaml` with tiered response, and `watch-band.sh`.
- `kit/enterprise/managed-settings.json` — documented, deliberately not installable.

**Installer**
- Idempotent, merge-not-overwrite, with `--dry-run`, `--profile`, `--modules`, `--artifacts-dir`.
- Refuses to install when `.claude/` is gitignored.
- `.sdlc-ai/manifest.lock` + `.sdlc-ai/backups/` make upgrade, profile switching and uninstall exact.

**Docs** — the argument, the six stages, an adoption path, the governance layers, the metrics, the two
profiles, a demo runbook, and a guide for assessing your own repository.

**Examples** — a filled intent → spec → plan chain for one change to a fictional payments service.
