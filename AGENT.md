# AGENT.md — make-repo

Create a GitHub repo from the current directory and push it — with sensible defaults, parent repo inheritance, and an interactive confirmation step. After creation, directories inside a parent repo can optionally be registered as a subtree or submodule; the default is to leave the parent unchanged.

Monorepo path: `Portfolio/Utilities/make-repo` (trl-infra). Monorepo ops → `../../../CLAUDE.md`.

## Universal Rules

- **Trinity Protocol REQUIRED**: each response = Orientation → Friction → Response. Full text: monorepo `protocols/the-trinity-protocol.md`.
- **No shell in main thread** — delegate to taskers; summarize, never dump raw output.
- **Worktrees**: all work on worktrees; `epic.<group>` consolidation branches off `develop` for integration testing; squash-PR provenance into epics.

## Branch & PR Policy

- Submodules sit on **`develop`** — keep your checkout on `develop`.
- All PRs target **`develop`** (feature/bug/task branches fork from `develop`).
- **`main` is CI/CD-only**: CI/CD automation performs all merges into `main` (release path). Never merge to or push `main` by hand.
