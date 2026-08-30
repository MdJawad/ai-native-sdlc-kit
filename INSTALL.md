# Installation

## Requirements

`git`, `bash`, `jq`, `yq`. The installer checks for these and stops with a clear message if one is
missing. `jq` is also a runtime dependency of the hooks — they fail closed without it, deliberately.

## Quick start

```bash
# 1. See exactly what would happen. Writes nothing.
install/install.sh --target /path/to/repo --profile trunk-local --dry-run

# 2. Install the week-one subset
install/install.sh --target /path/to/repo --profile trunk-local \
  --modules claude-md,skills,hooks,agents

# 3. Later, add the rest
install/install.sh --target /path/to/repo --profile trunk-local
```

## Options

| Flag | Default | What it does |
|---|---|---|
| `--target <path>` | *required* | The repository to install into. Must be a git repo. |
| `--profile <name>` | `trunk-local` | `trunk-local` or `pr-github`. See [`docs/05-profiles.md`](docs/05-profiles.md). |
| `--modules <a,b,c>` | all | Which modules to install (below). |
| `--artifacts-dir <dir>` | `sdlc` | Where the intent/spec/plan chain lives. |
| `--dry-run` | off | Print the full plan and write nothing. |
| `--force` | off | Proceed even though `.claude/` is gitignored. |

## Modules

| Module | Installs | Adopt it |
|---|---|---|
| `claude-md` | `CLAUDE.md` scaffold + verification and artifacts blocks | week 1 |
| `skills` | the six skills → `.claude/skills/` | week 1 |
| `hooks` | the guards → `.claude/hooks/`, registered in `.claude/settings.json` | week 1 |
| `agents` | verifier, reviewer, spec-critic → `.claude/agents/` | week 1 |
| `commands` | `/intent` `/spec` `/plan` `/review` `/close-loop` | week 2 |
| `artifacts` | `sdlc/README.md` + templates | week 2 |
| `review` | `REVIEW.md` | month 2 |
| `evals` | `evals/` harness and three exemplar cases | month 3 |
| `ci` | `agent-evals.yml`, plus the profile's Stage 5 wiring | month 3 |
| `maintain` | `.sdlc-ai/bands.yaml`, `scripts/sdlc/watch-band.sh` | month 4 |

The recommended order and the reasoning are in [`docs/02-adoption-path.md`](docs/02-adoption-path.md).

## What the installer does to files you already have

It **merges. It never overwrites your work.**

| Destination | Behaviour |
|---|---|
| A file that does not exist | Copied. |
| `CLAUDE.md` | **Never rewritten.** A marker-delimited block (`<!-- sdlc-ai:begin verification -->` … `<!-- sdlc-ai:end verification -->`) is appended, or replaced in place if already present. Every other line is untouched. |
| `.claude/settings.json` | Deep-merged with `jq`. Objects merge recursively; arrays concatenate and de-duplicate **preserving order**, so re-running never duplicates a hook and never reorders an entry you added. |
| `.sdlc-ai/bands.yaml` | Created only if absent — your tuned bands are never clobbered. |
| Any other kit file that exists and differs | If we installed it and you have not touched it, it is updated. Otherwise the new version is written to `<file>.sdlc-ai-new` and the conflict is reported. **Your file is not modified.** |

Before modifying anything in place, the original is copied to `.sdlc-ai/backups/`, which is what makes
`uninstall.sh` exact.

### The `.gitignore` stop

The installer **refuses to run** if `.claude/` is gitignored, and prints the fix:

```gitignore
# Agent configuration is reviewed code — only these are local
.claude/settings.local.json
.claude/worktrees/
```

This is a stop rather than a warning because the failure is silent: everything appears to install, and
none of it is shared, reviewed, or diffable. `--force` proceeds anyway.

## Idempotency and upgrades

Running the installer twice changes nothing the second time — every file reports `unchanged`. To
upgrade after pulling a new kit version, run it again: files you have not edited are updated, files you
have edited are left alone with the new version beside them as `.sdlc-ai-new`.

`.sdlc-ai/manifest.lock` records the kit version, the profile, the modules, a hash of every file
installed, and every file patched in place.

## Switching profiles

```bash
install/install.sh --target /path/to/repo --profile pr-github
```

The previous profile's Stage 5 assets are removed (if you have not edited them) and the new ones
installed. Nothing outside Stage 5 changes.

**One manual step:** the old profile's hook registration stays in `.claude/settings.json` — the
installer will not un-merge a file you may have hand-edited. It tells you to remove that entry.

## Uninstalling

```bash
install/uninstall.sh --target /path/to/repo --dry-run
install/uninstall.sh --target /path/to/repo
```

Files we created and you have not modified are removed. `CLAUDE.md` and `.claude/settings.json` are
restored from their backups. **Anything you edited is left alone and reported** — this will not
destroy your work to tidy up.

## After installing

1. **Fill in `CLAUDE.md`'s verification block** with your real commands and what healthy output looks
   like. This is what lets a session check its own work, and it is the highest-value ten minutes here.
2. **Edit `REVIEW.md`** — the *Do not report* list first, then the nit cap.
3. **Configure the guards** in `.sdlc-ai/`:

   | File | One per line | Effect |
   |---|---|---|
   | `protected-paths.txt` | glob | `protect-paths.sh` blocks edits under it |
   | `test-patterns.txt` | extended regex | overrides `protect-tests.sh`'s default test-path detection |
   | `format-command.txt` | a single command | run after every edit by `format-after-edit.sh` |
   | `production-gate.txt` | extended regex | what counts as a production deploy (`pr-github`) |

4. **Run the chain on one real change** — `/intent` → `/spec` → `/plan` — and commit all three. A
   filled-in chain someone can read beats any amount of explanation.
5. **Adapt the exemplars.** `secure-api-review` carries someone else's security rules, and
   `evals/cases/` assumes things about your repo that are probably not true.

## Distributing across many repos: the plugin

Once one repo works, the `.claude/` half can be distributed as a Claude Code plugin so policy skills
update centrally instead of being copied.

```bash
/plugin marketplace add <owner>/<repo>
/plugin install sdlc-ai@sdlc-ai
```

For an organisation-wide rollout, fork this repository, put your own policy skills in
`kit/claude/skills/`, and point the marketplace at your fork. Skills then update centrally instead of
being copied into every repo.

**The plugin carries** the six skills, three subagents and five commands.

**The plugin does not carry** — keep using the installer for these:

- **hooks**, which need `${CLAUDE_PROJECT_DIR}`-relative registration in the repo's own
  `settings.json` and read their configuration from the repo's `.sdlc-ai/`;
- **CI workflows**, artifact templates, `REVIEW.md`, and the `.gitignore` fix, none of which live
  under `.claude/`.

Both mechanisms read the same files under `kit/`, so there is one source of truth either way.

## Enterprise controls

`kit/enterprise/managed-settings.json` is **not installed by the installer**, deliberately. Managed
settings are deployed by IT through MDM, outside the repository, because a control an engineer can edit
is not a control against an engineer. See [`kit/enterprise/README.md`](kit/enterprise/README.md).

## Troubleshooting

**"jq is required to merge settings.json"** — install `jq`. The hooks need it at runtime too, and they
fail closed without it: a guard that cannot read the tool call must not allow it.

**A hook blocks something it should not** — read the block message; it names the rule. To change the
rule, edit the config file in `.sdlc-ai/`. To bypass once, the escape hatches are documented in each
hook's header comment (`SDLC_ALLOW_TEST_EDITS=1`, `RELEASE_APPROVAL=<ref>`).

**`*.sdlc-ai-new` files everywhere** — you edited files the kit also ships. Diff each against yours,
take what you want, delete the `.sdlc-ai-new`. That is the intended workflow, not a failure.

**Nothing happens when I type `/intent`** — the `commands` module is not installed, or `.claude/` is
gitignored and the files are not where the session expects them.
