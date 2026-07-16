# Changelog — utilities/shell/make-repo

## [Unreleased]
- No changes since the last milestone.

## [m2-docs-refresh] — 2026-07-16 — tag: `utilities-shell-make-repo/m2-docs-refresh`
Milestone summary: brought `PROJ-ARCH.md`/`PROJ-LAYOUT.md` (and summaries) up to date with the package as it actually shipped — documenting `fork-repo`, the `Makefile` install target, and `.gitignore`, none of which had been reflected in the docs since initial import.

### Changed
- `PROJ-ARCH.md`: reframed as a two-tool package (`make-repo` + `fork-repo`); added fork-repo's flow, remote-rewiring design, and `generate_description()` stub note
- `PROJ-LAYOUT.md`: tree and file table now list `bin/fork-repo`, `Makefile`, `.gitignore` alongside `bin/make-repo`
- Both `.summary.md` companions updated to match

## [m1-initial-tool] — 2026-06-14 — tag: `utilities-shell-make-repo/m1-initial-tool`
Milestone summary: initial import of the `make-repo`/`fork-repo` Bash CLI package — GitHub repo creation/editing and forking with parent-repo inheritance, interactive confirmation, and monorepo-standard `make install` support.

### Added
- `bin/make-repo`: creates/edits GitHub repos via `gh`, with 5-tier value precedence (CLI > `_OVERRIDE` env > parent repo > base env > defaults), interactive numbered-field confirmation, and team-access granting
- `bin/fork-repo`: forks repos via `gh` in local-clone mode (rewires `origin`→`upstream`) or remote-slug mode (`fork-repo org/repo`, optional `--clone`)
- `Makefile`: `make install` copies both scripts to `~/.local/bin` (symlink-aware skip); `compile`/`test` no-ops match the monorepo's `make install-utilities` convention
- `README.md`: install, quick start, precedence rules, flags/env vars, edit mode
- `docs/PROJ-ARCH.md`, `docs/PROJ-LAYOUT.md` (+ summaries): initial architecture and layout docs
- `.gitignore`: editor swap files, `.env`, `.envrc.local`
