# Changelog — utilities/shell/make-repo

## [Unreleased]

### Added
- `make-repo --origin` (`-origin`): bind or swap `origin` on existing git repos, linked worktrees, and submodules. Parks a different existing `origin` as `{owner}-origin` (override with `--keep-origin-as`). Headless swap requires `--swap-origin`.
- Submodule path updates the superproject `.gitmodules` URL and runs `git submodule sync` (not auto-committed). Worktree remotes are the shared config; per-worktree origin overrides are patched.
- Fake-`gh` integration tests covering origin add/swap/decline/collision/attach, submodule `.gitmodules` updates, worktree sharing, dry-run, and the existing-GitHub die path.
- Fake-`gh` integration tests covering the default, subtree, submodule, dry-run, `--no-inherit`, and conflicting-flag paths.

### Changed
- `make-repo` now asks after creation whether to integrate the new repository into its parent as a subtree, submodule, or not at all; no integration is the default.
- Added `--subtree`, `--submodule`, and `--no-integration` for deterministic automation. `--no-submodule` remains a compatibility alias.
- `--yes` no longer silently converts a child directory into a submodule; it leaves the parent unchanged unless an integration flag is explicit.
- Subtree conversion now prints reusable direct pull/push commands and, when both root wrapper scripts exist, configures a parent remote and appends the new path to their shared `SUBTREES` registry.

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
