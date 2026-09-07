# Project Schema — Summary

Full reference: [`PROJ-SCHEMA.md`](PROJ-SCHEMA.md).

> **No persistence layer** — no database, SQL, ORM, or migrations. Stateless Bash CLIs.
> "Schema" here = env vars, CLI grammar, string formats, git artifacts touched.

## Artifacts at a Glance

| Category | Count | Items |
|----------|-------|-------|
| Env vars (`make-repo`) | 13 base + override pairs | `GH_NEW_REPO_*` (org, prefix, name, desc, public, groups, group_role × base/`_OVERRIDE`) |
| Env vars (`fork-repo`) | 2 | `GH_FORK_TARGET_ORG`, `GH_FORK_TARGET_ORG_OVERRIDE` |
| CLI flags (`make-repo`) | ~18 | Field setters, `--edit`, `--origin`/`--swap-origin`/`--keep-origin-as`, `--subtree`/`--submodule`/`--no-integration`, `--dry-run`, `--yes`/`--headless` |
| CLI flags (`fork-repo`) | 4 + positional | `--org`, `--clone`, `--yes`, `--dry-run`, `org/repo` |
| String formats | 2 | Groups `"team[:role]"` list (roles: pull/push/admin/maintain/triage); GitHub remote URLs (ssh/https) |
| Git artifacts | 8 | remotes/`origin` swap, per-worktree overrides, `.gitmodules` URL, `SUBTREES=(...)` registry, subtree metadata trailers, gitlink, local init |
| Scratch paths | 2 | `copy.<dirname>/` backup; `/tmp/make-repo-subtree.*` |

## Precedence (both CLIs)

```
CLI flag → _OVERRIDE env → parent-repo detection (make-repo only) → base env → default
```

## Key Invariants

- No secrets in env; auth via `gh` only. Never force-pushes. No own state files/dotfiles.
- Headless (`--yes`) refuses origin swap without `--swap-origin`; refuses dirty `.gitmodules` edits; parent integration defaults to none.
