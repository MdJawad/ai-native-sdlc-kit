# sdlc-ai

The AI-native SDLC playbook as an installable kit. Open source, Apache-2.0.
`kit/` is content that gets installed elsewhere. `install/` is the machinery that puts it there.

## Commands

- Verify everything: `make check` (syntax, JSON/YAML validity, frontmatter, hook behaviour, a full
  install/uninstall round trip against a throwaway fixture). Must be green before any commit.
- Dry-run against a repo: `install/install.sh --target <repo> --dry-run`

## Conventions

- **Nothing under `kit/` runs from here.** It is copied into a target repo. Paths inside it are
  relative to *that* repo, not this one.
- **Shell is bash, POSIX-leaning.** Dependencies are `git`, `jq`, `yq` and nothing else.
- **Guards fail closed.** A hook that cannot parse its input blocks. A guard that cannot inspect the
  call must not allow it.
- **The installer merges; it never overwrites a user's file.** If you cannot merge cleanly, write
  `<file>.sdlc-ai-new` and report. This rule has no exceptions.
- **Every kit asset is an exemplar or a mechanism, and the difference is stated in the file.** An
  exemplar carrying someone else's rules must say so at the top.
- **Adding a kit file means adding a `kit/manifest.yaml` entry.** A file not in the manifest is not
  installed, and nothing else will tell you.

## Architecture

- `kit/` — installable content: skills, agents, commands, hooks, templates, CI, eval harness.
- `kit/manifest.yaml` — the source → destination map, per module, per profile. The installer reads
  only this; it never walks `kit/` on its own.
- `install/install.sh` + `install/lib/` — merge machinery. `merge_json.sh` (deep JSON merge),
  `merge_block.sh` (marker-delimited markdown blocks), `manifest.sh` (the target-side lock file).
- `docs/` — the methodology. `01-stages.md` is the vocabulary; everything else assumes it.
- `scripts/metrics/` — read-only, git-history-derived measurement.

## Things Claude gets wrong

- **Heredoc delimiter collisions.** A nested heredoc using the same delimiter silently truncates the
  outer one and executes the remainder as shell. Use a unique delimiter (`SDLC_SCRIPT_EOF`) for any
  heredoc whose body contains another.
- **`jq` function parameters are filters, not values.** In `def f(a; b)`, `a` is re-evaluated against
  the current input — inside a `reduce`, that is the accumulator, not the original. Use `def f($a; $b)`.
- **`git log --follow` on template-derived files.** Copy detection cheerfully follows `spec.md` back to
  `intent.md` and reports the wrong timestamp. Do not use `--follow` in the metrics scripts.
- **Git pathspec globs match across `/`.** `sdlc/*/spec.md` also matches `sdlc/templates/spec.md`.
  Exclude the template directory explicitly.

## Verifying your work

<!-- sdlc-ai:begin verification -->

- Check: `make check` (every assertion green — the round-trip test must end with the fixture at
  zero diff from its baseline)

Run it before reporting any task complete, and paste the output.
**If a test fails, fix the code, not the test.**

<!-- sdlc-ai:end verification -->
