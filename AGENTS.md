# AGENTS.md

The canonical guide for AI agents working in this repo is **[`CLAUDE.md`](CLAUDE.md)** — read it first.

Then read [`README.md`](README.md) for what this is, [`docs/01-stages.md`](docs/01-stages.md) for the
vocabulary every other document assumes, and [`INSTALL.md`](INSTALL.md) for what the installer
guarantees about not overwriting a user's files.

This repository dogfoods the kit it ships: its own `CLAUDE.md` carries the verification block the kit
installs, and `make check` is the single verification command that block points at. A filled-in
artifact chain — intent, spec and plan for one change — is in
[`examples/payments-api/`](examples/payments-api/).
