# How to: keep monorepo projects as subtrees, not submodules

**Goal:** publish a project directory inside this monorepo to GitHub *without* `make-repo` converting it into a git submodule afterward.
**Prereqs:** installed (`make install`); standing inside the project directory you want to publish.

## Why this matters here

This monorepo's own convention (see root `CLAUDE.md`) is: **`projects/` = git subtrees, never submodules.** `make-repo`'s default behavior is the opposite — whenever it detects you're running inside a subdirectory of an existing git repo, it will, after creating the new GitHub repo, **offer (interactively) or silently proceed (with `--yes`) to convert that directory into a submodule of the parent repo.** If you run plain `make-repo --yes` inside `projects/some-app`, you can end up with a submodule where a subtree was expected.

## Steps

1. Always pass `--no-submodule` when publishing a subdirectory of this monorepo:
   ```bash
   cd projects/some-app
   make-repo --no-submodule
   ```
2. If you forgot and are in the interactive prompt, the tool asks explicitly before converting:
   ```
   Convert to submodule in parent repo? [Y/n]
   ```
   Answer `n` to abort the conversion step (the GitHub repo itself has already been created and pushed at this point — only the local submodule wiring is skipped).
3. Confirm the flag took effect with a dry run first:
   ```bash
   make-repo --no-submodule --dry-run
   ```
   Look for `Submodule:   skipped (--no-submodule)` in the output.

**Verify:** after running, `git status` in the monorepo root shows no new `.gitmodules` entry, and `ls -la projects/some-app` still shows a plain directory (`.git` absent or a real subdirectory, not a `.git` *file* pointing into `.git/modules/`).

## Gotchas

- **`--yes` + no `--no-submodule` = silent conversion.** In scripted/automated runs, the interactive `[Y/n]` confirmation never fires — the tool proceeds straight to conversion. Always pair `--yes` with `--no-submodule` in scripts run from inside this monorepo.
- **If a conversion already happened:** the tool backs up the original directory to `copy.<dirname>` in the parent repo *before* the destructive `git submodule add` step, and verifies file-for-file that the new submodule matches the backup. If you need to undo, remove the submodule entry (`git submodule deinit -f <path> && git rm -f <path> && rm -rf .git/modules/<path>`) and restore from `copy.<dirname>`. Don't delete the `copy.*` backup until you've confirmed the state you want.
- **Verification mismatch warning:** if the tool prints `Content mismatch` or `Missing in submodule` lines, the backup at `copy.<dirname>` is intentionally preserved — treat that as a signal to resolve manually before subtree-managing the directory again, not something to auto-delete.
- **Already a submodule going in?** If the directory you `make-repo` on was already registered as a submodule (`.git` is a file), the tool detaches it to a standalone repo first, then (absent `--no-submodule`) re-adds it as a submodule of the newly created remote — same conversion path applies.
