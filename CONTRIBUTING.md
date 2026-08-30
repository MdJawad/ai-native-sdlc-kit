# Contributing

Thanks for considering it. This is a small repository with a narrow purpose, so the bar for a change is
mostly about fit rather than size.

## Setup

```bash
git clone <this repo> && cd <repo>
make check          # must be green before you change anything
```

Requirements: `git`, `bash`, `jq`, `yq`, `python3`. Nothing else.

## The one rule

**`make check` must be green.** It runs shell syntax over every script, validates every JSON and YAML
file, checks skill and subagent frontmatter, verifies every kit file is reachable from
`kit/manifest.yaml`, exercises each hook's block-and-allow behaviour, and drives a full install →
idempotency → conflict → profile-switch → uninstall round trip that must end with the test fixture
byte-identical to its baseline.

If a check fails, fix the code rather than the check. If a check is wrong, say so in the pull request
and change it deliberately — but not as a step on the way to something else.

## What belongs here

| Very welcome | Please don't |
|---|---|
| A hook that encodes a rule many teams state in prose | A hook encoding one team's house style |
| A third profile for a genuinely different integration model | A fork of an existing profile with different names |
| Bugs in the installer's merge behaviour | Rewriting the merge strategy without a failing case first |
| Sharper docs, better examples, clearer block messages | Expanding the docs into a book |
| A new check in `scripts/check.sh` | Turning `make check` into a linter for prose style |

## Rules for kit content

Everything under `kit/` is copied into someone else's repository, which makes a few things
non-negotiable:

1. **Say whether it is an exemplar or a mechanism.** A mechanism works as shipped. An exemplar carries
   placeholder rules and must say so, at the top, in bold. A file that looks authoritative and contains
   someone else's policy is worse than no file.
2. **Guards fail closed.** A hook that cannot parse its input blocks. Never wave a call through because
   inspection failed.
3. **A block message is read by the thing that must change course.** Say what was blocked, why, what to
   do instead, and that looking for another route is not the answer.
4. **New kit file means a new `kit/manifest.yaml` entry.** A file not in the manifest is never
   installed, and only `make check` will tell you.
5. **Paths inside `kit/` are relative to the target repo**, not to this one.
6. **No absolute paths, no email addresses, no real organisation or person.** Everything in `examples/`
   is fictional and must stay that way.

## Style

Match what is already there. Documentation is plain English, wrapped near 100 columns, and prefers a
concrete example to an abstract statement. Where a rule has a cost, the docs say so — the credibility
of the whole thing rests on not overselling it.

## Licence

By contributing you agree your contribution is licensed under Apache-2.0, the same as the project.
