# PROJ-HOWTO

Task-oriented guides for `make-repo`/`fork-repo`. See [PROJ-ARCH.md](PROJ-ARCH.md) for *why*, [PROJ-LAYOUT.md](PROJ-LAYOUT.md) for *where*.

## How to: install the tools

**Goal:** get `make-repo` and `fork-repo` on your `PATH`.
**Prereqs:** [GitHub CLI (`gh`)](https://cli.github.com/) installed and `gh auth login` completed.

1. From this package's root:
   ```bash
   make install
   ```
   Copies both scripts to `~/.local/bin` (755). If `~/.local/bin/make-repo` already resolves to this same file (symlink), the step is skipped rather than re-copied.
2. Confirm `~/.local/bin` is on your `PATH` (or add it to `~/.zshrc`/`.envrc`).

**Verify:**
```bash
make-repo --help
fork-repo --help
```
**Gotchas:**
- `make install` only installs — `compile`/`test` are intentional no-ops, present so this package plugs into the monorepo's `make install-utilities` batch install.
- No `gh auth login` yet? Every command below fails fast with `Not authenticated — run: gh auth login`.

---

## How to: create a GitHub repo from the current directory

**Goal:** turn the directory you're standing in into a pushed GitHub repo, with review before anything is created.
**Prereqs:** installed (above); inside the directory you want to publish.

1. ```bash
   cd ~/projects/my-cool-thing
   make-repo
   ```
2. Review the numbered summary (org, repo name, visibility, description, groups). Type a number to edit that field, or `y` to confirm.

**Verify:** the tool prints `Done! <org>/<repo>` with the GitHub URL; `gh repo view <org>/<repo>` confirms it exists.
**Gotchas:**
- Running this inside a subdirectory of an existing git repo (including this monorepo) auto-inherits that parent's org/visibility. After creation it asks whether to leave the parent unchanged (default), register a subtree, or register a submodule.
- Repo already exists on GitHub → the tool errors and tells you to use `--edit` instead (see next guide).
- Non-interactive/CI use: pass `--yes` (or `-y`) or the explicit headless switch `--headless` (alias `--non-interactive`) plus explicit flags to skip the prompt entirely, e.g. `make-repo --org my-org --public --yes`, or `make-repo --org my-org --headless` for unambiguous CI scripting.

---

## How to: preview a repo creation without creating anything

**Goal:** see exactly what org/name/visibility/description would be used, with zero side effects.
**Prereqs:** installed.

1. ```bash
   make-repo --dry-run
   ```

**Verify:** output ends with `Dry run — no changes made.` and no GitHub API calls were made (nothing to `gh repo view`).
**Gotchas:** `--dry-run` still runs full precedence resolution (CLI > `_OVERRIDE` env > parent repo > base env > defaults), so it's the fastest way to debug *why* a value came out wrong before scripting `--yes`.

---

## How to: set org, visibility, description, or team access without the prompt

**Goal:** script a repo creation end-to-end with flags, no interactive step.
**Prereqs:** installed; know the target org/teams.

1. ```bash
   make-repo --org my-org --public \
     --description "My project" \
     --groups "devs,ops:admin,interns:pull" \
     --yes
   ```

**Verify:** `gh repo view my-org/<repo> --json visibility,description` matches what you passed; `gh api /orgs/my-org/teams/devs/repos/my-org/<repo>` (per team) confirms access.
**Gotchas:**
- Team roles are validated against `pull push admin maintain triage` — an unknown role is skipped with a warning, not a hard failure; check the printed output for `Failed to set` or `Invalid role` lines.
- `--groups` entries without a `:role` suffix fall back to `--group-role` (default `push`), not to each team's existing GitHub role.

---

## How to: edit an existing repo's settings

**Goal:** flip visibility, update the description, or grant team access on a repo that's already on GitHub.
**Prereqs:** installed; repo already exists under the target org.

1. Interactive:
   ```bash
   make-repo --edit
   ```
   Fetches current settings, shows a numbered menu, applies only the fields you change.
2. Scripted (no prompt):
   ```bash
   make-repo --edit --public --description "Updated desc" --yes
   ```

**Verify:** `gh repo view <org>/<repo> --json visibility,description`.
**Gotchas:** if you run plain `make-repo` (no `--edit`) against a repo that already exists but you *did* pass `--public`/`--private`, the tool auto-detects this and applies the edit anyway rather than erroring — but without a visibility flag, no `--edit`, it always errors out.

---

## How to: fork a repo and wire up remotes

**Goal:** fork a GitHub repo and end up with correct local `origin`/`upstream` remotes, without manual `git remote` surgery.
**Prereqs:** installed; `gh auth login` done.

1. **Already have the source repo cloned locally** (most common):
   ```bash
   cd ~/projects/some-repo
   fork-repo
   ```
   Renames local `origin` → `upstream`, forks on GitHub, points `origin` at your fork — preserving whichever scheme (ssh/https) `origin` already used.
2. **Don't have it cloned yet** — fork by slug, optionally clone:
   ```bash
   fork-repo some-org/some-repo --clone
   ```

**Verify:** `git remote -v` shows `origin` → your fork, `upstream` → the original.
**Gotchas:**
- Running `fork-repo` (no arg) inside a **submodule** forks the submodule's own remote, not the parent repo — the tool warns about this but still proceeds.
- Forking into the same org that already owns the source repo is rejected as a guard against self-forks; pass `--org` to target somewhere else.
- Preview first with `fork-repo --dry-run` — same no-side-effects behavior as `make-repo --dry-run`.

---

## How to: choose subtree, submodule, or no parent integration

**Goal:** publish a project directory inside this monorepo and deliberately select its parent-repository integration.
**Prereqs:** none beyond installation.

→ *See [howto/avoid-submodule-conversion.md](howto/avoid-submodule-conversion.md)*

---

## How to: bind or swap origin on an existing checkout

**Goal:** point this directory's `origin` at a GitHub repo (creating it if needed) without destroying submodule metadata or force-pushing.
**Prereqs:** installed; `gh auth login` done.

1. Preview:
   ```bash
   make-repo --origin --dry-run
   ```
2. No origin yet:
   ```bash
   make-repo --origin --yes
   ```
3. Origin exists and should be replaced. Interactive run asks "Swap origin?". For scripts:
   ```bash
   make-repo --origin --yes --swap-origin
   ```
   The previous `origin` is renamed to `{github-owner}-origin` (or `--keep-origin-as NAME`).

**Verify:** `git remote -v` shows the new `origin` and, on swap, the parked remote. For a submodule, `git config -f ../.gitmodules --get submodule.<name>.url` matches; the parent `.gitmodules` change is **not** committed automatically.

**Gotchas:**
- `--yes` alone will not swap a different existing origin — that is deliberate. Pass `--swap-origin`.
- Worktree `.git` files are not edited; remotes live in the shared config, so every linked worktree sees the new `origin`.
- Histories that have diverged are left as-is (no force-push).
- Parent subtree/submodule conversion is not offered unless you also pass `--subtree` or `--submodule`.

---

## How to: pin values that beat parent-repo detection

**Goal:** force an org, prefix, name, description, or visibility even when `make-repo` would otherwise inherit it from a containing repo.
**Prereqs:** know the `_OVERRIDE` env var for the field you want to pin (see [README.md](../README.md#environment-variables)).

1. In `.envrc` (or shell profile):
   ```bash
   export GH_NEW_REPO_ORG_OVERRIDE=my-personal-org
   ```
2. Run `make-repo` as normal from anywhere under a parent repo whose org you don't want inherited.

**Verify:** `make-repo --dry-run` shows the overridden value under `Org:`, not the parent's.
**Gotchas:** `_OVERRIDE` vars beat parent detection but **not** CLI flags — a literal `--org` on the command line still wins over any override.

---

## How to: create a repo without inheriting the parent repo's org/visibility

**Goal:** get a clean-slate org/visibility resolution (base env vars → built-in defaults) even though you're standing inside a subdirectory of an existing git repo — e.g. publishing to a personal account from inside a work monorepo checkout.
**Prereqs:** installed.

1. ```bash
   cd projects/some-app   # inside a monorepo/parent repo
   make-repo --no-inherit
   ```
   This excludes the parent's values from priority 3 of the precedence chain, so `org`/`visibility` fall through to `_OVERRIDE` env vars, then base env vars, then built-in defaults (`noizu`, `private`). The parent path is still detected so a later subtree/submodule choice remains possible.
2. Combine with explicit flags if the defaults still aren't what you want:
   ```bash
   make-repo --no-inherit --org my-personal-account --public
   ```

**Verify:** `make-repo --no-inherit --dry-run` shows `Org:`/`Visibility:` resolved from env/defaults, not from the containing repo's GitHub remote.
**Gotchas:**
- `--no-inherit` only turns off *parent value inheritance* (tier 3) — it does not disable `_OVERRIDE` env vars (tier 2), so a stray `GH_NEW_REPO_ORG_OVERRIDE` in your shell still wins.
- This is unrelated to the integration choice: `--no-inherit` controls where org/visibility values come from; `--subtree`, `--submodule`, or the default no-integration choice controls what happens to the directory afterward.
