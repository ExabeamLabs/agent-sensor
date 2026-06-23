# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`agent-sensor-dist` is a **public distribution repo** for the `agent-sensor` binary. It contains no source code. The application is built in the private repo at `https://github.com/Exabeam/agent-sensor`. This repo holds:

- Pre-built binaries (local `bin/` staging only — never committed, attached as GitHub Release assets)
- End-user documentation in `docs/`
- A `Makefile` that drives the full release workflow via the `gh` CLI

## Release workflow

Prerequisites: `gh` CLI installed and authenticated (`gh auth login`).

```sh
# Full release (verify binaries → tag → create GitHub Release)
make release VERSION=1.2.3

# Step by step
make verify     VERSION=1.2.3   # Check all three binaries exist in bin/
make tag        VERSION=1.2.3   # Create + push git tag v1.2.3
make gh-release VERSION=1.2.3   # Create GitHub Release and upload assets
```

Before running `make release`:
1. Build in the private repo (`cargo build --release --target <triple>`) for all three targets.
2. Copy binaries into `bin/` with the naming convention below.
3. Update `docs/changelog.md` with release notes (this file is used as the GitHub Release body).

## Binary naming convention

Binaries must be placed in `bin/` with these exact names before releasing:

```
bin/agent-sensor-v{VERSION}-x86_64-apple-darwin         # macOS Intel
bin/agent-sensor-v{VERSION}-aarch64-apple-darwin        # macOS Apple Silicon
bin/agent-sensor-v{VERSION}-x86_64-pc-windows-gnu.exe   # Windows
```

`bin/` is gitignored — binaries live only as GitHub Release assets.

## Docs

`docs/` contains three files: `installation.md`, `usage.md`, `changelog.md`. The source of truth for CLI flags and subcommands is `src/main.rs` in the private repo (clap definitions). When updating `usage.md`, cross-check against the clap `Cli` struct and `Commands` enum there.

`docs/changelog.md` doubles as the GitHub Release notes body — `make gh-release` passes it via `--notes-file`. Keep the most recent release at the top; move `## Unreleased` entries under a versioned heading before releasing.
