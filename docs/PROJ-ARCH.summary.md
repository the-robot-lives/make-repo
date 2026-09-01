# Architecture Summary

Two-tool Bash package wrapping `gh` + `git` (no k8-lib): **`bin/make-repo`** (~999 lines) create/edit GitHub repos; **`bin/fork-repo`** (~436 lines) fork + remote rewiring.

**make-repo:** CLI/`_OVERRIDE`/parent/base/defaults resolution → optional submodule origin identity → dry-run or interactive/`--yes`/`--headless` confirm → `gh repo create --source=. --push` (or edit) → optional team `PUT` → parent integration **none** (default), **subtree** (trailers + optional `push-subtrees.sh` registry), or **submodule** (backup + verify). `--no-inherit` drops org/visibility inheritance but keeps parent path for integration. `--origin`/`-origin` binds or swaps local remotes (park old as `{owner}-origin`; headless swap needs `--swap-origin`); submodules update `.gitmodules` + `submodule sync` without detaching; worktree remotes share common config.

**fork-repo:** local (cwd origin → rename origin/upstream) or remote slug (`--clone` optional). Target org: `--org` > overrides > user. Blocks forking into source org; preserves ssh/https.

**Install/test:** `make install` → `~/.local/bin` (symlink-aware); `make test` → fake-`gh` suite (none/subtree/wrappers/submodule/dry-run/headless/conflicts). Wrapper test expects monorepo root subtree scripts.

**Design:** interactive-safe, scriptable with explicit integration flags; fail-safe subtree/submodule conversion; `generate_description()` still a stub.
