# AGENT-README

> Orientation for AI coding agents working in this repo. Human docs: README.md.

## Type

cli-tool

## Purpose

Bash CLI (`bin/make-repo`) that wraps `gh` to create a GitHub repo from the current directory and push it — sensible defaults, parent repo inheritance, interactive confirmation; optional subtree/submodule registration of the new directory in the parent (default: leave parent unchanged).

## Stack

Bash + `gh` CLI. `bin/make-repo` and `bin/fork-repo`, installed to `~/.local/bin` by the Makefile.

## Dev mode

```bash
export PATH="$PATH:/path/to/make-repo/bin"
make-repo                       # interactive summary; y confirms, 1-6 edits a field
make install                    # install bin scripts to ~/.local/bin
```

## Ports / URLs

- none (library/CLI)

## Tests

```bash
make test                       # bash tests/run.sh — needs Bash 4+
```

## Gotchas

- Tests need Bash 4+; macOS `/bin/bash` is 3.2, so the Makefile falls back to `/opt/homebrew/bin/bash` and errors if it is missing.
- Resolution precedence: CLI flags > `*_OVERRIDE` env vars > parent repo remote (org + visibility inherited) > base env vars > built-in defaults (`noizu`, `private`); `--no-inherit` skips parent detection.
- Also installed via the monorepo root `make install-utilities` (Portfolio/Utilities fleet) — the Makefile skips reinstall when source and destination are the same file.
