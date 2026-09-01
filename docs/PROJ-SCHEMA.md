# Project Schema

> **No persistence layer.** This project has **no database, no SQL schema, no ORM, and no
> migrations**. It is two stateless Bash CLIs (`bin/make-repo`, `bin/fork-repo`) that wrap
> `gh` and `git`. There are no Liquibase changelogs and no ERDs to maintain — the
> Mermaid/PlantUML ERD conventions in the schema skill do not apply here.
>
> Instead, this document is the schema reference for the **data artifacts** the tools
> define or consume: environment variables, CLI flag grammar, structured string formats,
> and the git-managed files they read/write. The scripts keep no state files of their own.

Plain tree: [`PROJ-LAYOUT.summary.md`](PROJ-LAYOUT.summary.md). Architecture: [`PROJ-ARCH.md`](PROJ-ARCH.md).

---

## 1. Environment Variable Surface

Resolved per-value by precedence (highest wins):
**CLI flag → `_OVERRIDE` env → parent-repo detection (make-repo only) → base env → built-in default.**

### `make-repo` — base vars (priority 4)

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `GH_NEW_REPO_ORG` | string | `noizu` | Default org |
| `GH_NEW_REPO_PREFIX` | string | *(empty)* | Prepended as `PREFIX-` to repo name |
| `GH_NEW_REPO_NAME` | string | *(empty)* | Repo name override (prefix still applied) |
| `GH_NEW_REPO_DESC` | string | `No additional details.` | Repo description |
| `GH_NEW_REPO_PUBLIC` | presence | *(unset = private)* | Any value ⇒ public |
| `GH_NEW_REPO_GROUPS` | groups string | *(empty)* | Team access list (format below) |
| `GH_NEW_REPO_GROUP_ROLE` | enum | `push` | Default team role |

### `make-repo` — override vars (priority 2, beat parent detection)

| Variable | Type | Purpose |
|----------|------|---------|
| `GH_NEW_REPO_ORG_OVERRIDE` | string | Force org |
| `GH_NEW_REPO_PREFIX_OVERRIDE` | string | Force prefix |
| `GH_NEW_REPO_NAME_OVERRIDE` | string | Force repo name |
| `GH_NEW_REPO_DESC_OVERRIDE` | string | Force description |
| `GH_NEW_REPO_PUBLIC_OVERRIDE` | `1` \| `0` | Force public / private (note: boolean, unlike base) |
| `GH_NEW_REPO_GROUPS_OVERRIDE` | groups string | Force team list |

### `fork-repo`

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `GH_FORK_TARGET_ORG` | string | *(unset)* | Default fork target org |
| `GH_FORK_TARGET_ORG_OVERRIDE` | string | *(empty)* | Beats base; beats all except `--org` |

No secrets are read from env; authentication is delegated entirely to `gh auth status`.

## 2. CLI Flag Grammar

Both CLIs use a hand-rolled `while/case` parser; `--help` extracts the header comment.

### `make-repo`

| Flag | Arg? | Effect |
|------|------|--------|
| `--org`, `--repo`, `--prefix`, `--description`, `--groups`, `--group-role` | value | Set resolved field |
| `--public` / `--private` | — | Set visibility |
| `--no-prefix`, `--no-inherit` | — | Disable prefix / parent inheritance |
| `--yes`, `-y`, `--headless`, `--non-interactive` | — | Skip all prompts (headless default: no parent integration) |
| `--edit` | — | Edit-mode menu for an existing repo |
| `--origin`, `-origin` | — | Bind/create/swap `origin` (subcommand-like mode) |
| `--swap-origin` | — | Headless permission for an origin swap |
| `--keep-origin-as NAME` | value | Implies `--origin`; parked-remote name |
| `--subtree` / `--submodule` / `--no-integration` (alias `--no-submodule`) | — | Parent integration mode; mutually exclusive (conflict ⇒ fatal) |
| `--dry-run` | — | Print resolved plan, mutate nothing |
| `--help`, `-h` | — | Usage |

### `fork-repo`

| Flag | Arg? | Effect |
|------|------|--------|
| `--org NAME` | value | Fork target org |
| `--clone` | — | Slug mode: clone the fork after creating it |
| `--yes`, `-y` / `--dry-run` / `--help`, `-h` | — | As above |
| *(positional)* | `org/repo` | Source slug; absent ⇒ local mode |

## 3. Structured String Formats

### Groups string (`--groups` / `GH_NEW_REPO_GROUPS*`)

```
"<team>[::<role>]"(, ...) — comma-separated; each entry "team[:role]"
```

- `role` ∈ `pull | push | admin | maintain | triage`; invalid role ⇒ entry skipped with warning.
- Entries are whitespace-trimmed; applied via `gh api /orgs/{org}/teams/{team}/repos/{repo}`.

### GitHub remote URL forms (parsed, never stored by this project)

```
git@github.com:<owner>/<repo>.git      # ssh
https://github.com/<owner>/<repo>.git  # https
```

## 4. Git-Managed Artifacts Read/Written

These are the project's "tables" — external git state it mutates. None are owned
files of this repo.

| Artifact | Written by | Format / semantics |
|----------|-----------|--------------------|
| `.git/config` remotes | make-repo `--origin` | `origin` set to new URL; previous `origin` renamed to `{owner}-origin` (or `--keep-origin-as`), numeric `-2`, `-3`… suffix if taken |
| Per-worktree `<gitdir>/config` `remote.origin.url` | make-repo `--origin` | Per-worktree overrides updated to match new origin |
| Superproject `.gitmodules` `submodule.<name>.url` | make-repo `--origin` (submodule checkout) | Relative (`../`) URLs replaced with absolute; edited only with consent on a dirty file; not auto-committed |
| `SUBTREES=(...)` registry in `push-subtrees.sh` | make-repo subtree integration | Line `"prefix\|remote-alias\|branch"` appended before closing `)`; idempotent (path-checked); committed separately |
| Parent remote alias (`<repo-name>`, `-2`, …) | make-repo subtree integration | `git remote add` pointing at the new repo |
| Subtree metadata commit | make-repo subtree conversion | Commit message trailers `git-subtree-dir: <path>` / `git-subtree-split: <sha>` |
| `.gitmodules` section removal | make-repo submodule→subtree conversion | `git config --remove-section` for the matching submodule key |
| Gitlink + `.gitmodules` | make-repo submodule conversion | `git submodule add <url> <path>`; committed in parent |
| Local git repo | make-repo create path | `git init` + `initial commit` (existing submodule: `.git` file removed, re-init standalone) |

**Safety invariants**: never force-pushes; never commits outside the explicitly-listed
paths; dirty `.gitmodules` under `--yes` aborts; bare repos unsupported.

## 5. Scratch / Backup Paths (untracked, best-effort)

| Path | Created by | Lifecycle |
|------|-----------|-----------|
| `<parent>/copy.<dirname>/` | submodule conversion | Full `cp -a` backup before destructive re-add; kept until user deletes it |
| `/tmp/make-repo-subtree.XXXXXX/` | subtree conversion | Holds `.git` metadata during conversion; removed on success/failure-restore |

## 6. State the Project Does NOT Keep

- No dotfiles, caches, or config files of its own (nothing in `~/.config`, no `.envrc`).
- No state between runs — every invocation re-derives context from `git`/`gh`/cwd.
- Description auto-generation (`generate_description()`) is a stub returning a placeholder.

---

## Maintenance Notes

This file replaces an ERD: when scripts change what they read/write (new env var, new
flag, new git artifact), update §1–§4 and the summary. There is deliberately no
`schema/` extract directory and no Mermaid `erDiagram` — the artifact table in §4 is
the closest analogue and is kept flat because the project has <10 artifacts.
