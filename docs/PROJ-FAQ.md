# PROJ-FAQ

Anticipated why/when/compared-to-what questions for `make-repo`/`fork-repo`. See [PROJ-HOWTO.md](PROJ-HOWTO.md) for step-by-step procedures and [PROJ-ARCH.md](PROJ-ARCH.md) for design rationale.

## Motivation

### Why would I use this instead of `gh repo create` directly?

Because `make-repo` adds a review step and context inheritance that plain `gh repo create` doesn't have. Running `gh repo create` commits you immediately — there's no preview, and you must spell out org/visibility/description by hand every time. `make-repo` resolves those from parent-repo context and defaults, shows you a numbered summary before anything is created, and lets you edit any field in place. The honest trade-off: for a one-off repo where you already know every flag, `gh repo create --public --description "..."` is fewer keystrokes — `make-repo`'s value is in repeated use inside this monorepo's subtree/submodule workflows, not as a universal `gh` replacement.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-create-a-github-repo-from-the-current-directory) to do it.*

### Why does it auto-detect org/visibility from a parent repo instead of just asking me every time?

Because most repos created with this tool are subdirectories of an already-org-scoped monorepo, and re-typing the same org/visibility for every new subtree/submodule is repetitive and error-prone (easy to fat-finger `--public` when everything else in the tree is private). Parent inheritance is priority 3 of 5 in the precedence chain, so it only fills gaps CLI flags and `_OVERRIDE` env vars don't already answer. Use `--no-inherit` when you genuinely want a clean-slate resolution (e.g. publishing to a personal account from inside a work monorepo checkout).

→ *See precedence table in [README.md](../README.md#precedence).*

### Why a 5-tier precedence chain instead of just CLI flags and defaults?

Because the tool spans three different usage modes — ad hoc interactive use, `.envrc`-pinned personal defaults, and scripted CI — and each needs a different value source to win without the others interfering. CLI flags must always win (explicit beats implicit). `_OVERRIDE` env vars let you pin a personal org in `.envrc` without touching CLI invocations everywhere. Parent-repo detection handles the common monorepo case automatically. Base env vars and built-in defaults are the fallback floor. The cost is that debugging "why did it pick that org" requires knowing the tier order — `--dry-run` exists specifically to make this observable without side effects.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-preview-a-repo-creation-without-creating-anything) and [PROJ-ARCH.md](PROJ-ARCH.md#make-repo-flow).*

## Fit

### When is this the wrong tool for publishing a monorepo project?

When you haven't decided yet whether the directory should become a subtree or a submodule — `make-repo`'s default behavior, absent `--no-submodule`, is to convert the directory into a git submodule of the parent repo after creating it on GitHub. This monorepo's own convention is subtrees, never submodules (see root `CLAUDE.md`), so running plain `make-repo --yes` inside `projects/some-app` silently produces the wrong result. If you're publishing anything under `projects/`, always pass `--no-submodule`.

→ *Full discussion: [howto/avoid-submodule-conversion.md](howto/avoid-submodule-conversion.md)*

### When should I not run this non-interactively?

When you haven't first confirmed the resolved values with `--dry-run`. `--yes` skips both the confirmation prompt *and* the submodule-conversion `[Y/n]` guard — in a monorepo subdirectory that means a script running `--yes` without `--no-submodule` converts the directory to a submodule with no chance to abort. Non-interactive use is fine and intended (CI, batch scripting), but it removes every safety net the interactive mode gives you, so get the flags right first via a dry run.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-set-org-visibility-description-or-team-access-without-the-prompt).*

## Comparison

### How does `make-repo` differ from `fork-repo`?

They cover opposite starting points: `make-repo` creates a brand-new GitHub repo from a directory you already have; `fork-repo` forks an *existing* GitHub repo (yours or someone else's) and wires local remotes so `origin` points at your fork and `upstream` at the source. Both share the same precedence-resolution and interactive-confirm/`--dry-run` conventions, but `fork-repo` has no submodule-conversion behavior and no team-access granting — those are `make-repo`-only concerns.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#fork-repo-flow).*

### How does `--no-inherit` differ from `--no-submodule` — do I need both?

They control different, independent things: `--no-inherit` decides *where org/visibility values come from* (skips parent-repo detection, tier 3 of the precedence chain), while `--no-submodule` decides *what happens to the local directory afterward* (skips converting it into a git submodule of the parent). Neither implies the other — you can inherit the parent's org but still opt out of the submodule conversion, or vice versa. The common case where you want both together is publishing from inside a monorepo checkout to an unrelated personal account: `--no-inherit` stops it from copying the monorepo's org/visibility, and `--no-submodule` stops it from wiring the directory back into the monorepo's tree.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-create-a-repo-without-inheriting-the-parent-repos-orgvisibility) and [howto/avoid-submodule-conversion.md](howto/avoid-submodule-conversion.md).*

### How does editing with `--edit` differ from just re-running `make-repo`?

Plain `make-repo` against a repo that already exists errors out — it refuses to silently reinterpret repo creation as an edit unless you also passed a visibility flag (`--public`/`--private`), in which case it auto-detects the conflict and edits anyway. `--edit` is the explicit, always-safe path: it fetches current settings from GitHub first and only applies fields you actually changed, rather than assuming defaults for everything else.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-edit-an-existing-repos-settings).*

## Capability

### Can it generate a repo description for me automatically?

Not yet. `generate_description()` is a stubbed function reserved for future integration with a CLI AI tool (e.g. `claude`, `gh copilot`) — today the description field is either what you pass explicitly (`--description`, `GH_NEW_REPO_DESC[_OVERRIDE]`) or a static placeholder. Don't rely on it inferring anything from repo contents right now.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#key-design-decisions).*

### Can I grant team access without touching the GitHub UI?

Yes, via `--groups`/`GH_NEW_REPO_GROUPS[_OVERRIDE]`, both on creation and through `--edit`. Roles are validated against `pull push admin maintain triage`; an unrecognized role is skipped with a printed warning rather than failing the whole run, so always check the output for `Failed to set`/`Invalid role` lines rather than assuming silence means success.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-set-org-visibility-description-or-team-access-without-the-prompt).*

## Caveats

### What happens if I forget `--no-submodule` and it converts my directory?

It's recoverable but manual. Before the destructive `git submodule add`, the tool backs up the original directory to `copy.<dirname>` in the parent repo and verifies file-for-file that the new submodule matches the backup — so nothing is lost, but undoing requires you to run `git submodule deinit`/`git rm`/`rm -rf .git/modules/<path>` yourself and restore from the `copy.*` backup. Don't delete that backup until you've confirmed the restored state is correct.

→ *Full discussion: [howto/avoid-submodule-conversion.md](howto/avoid-submodule-conversion.md)*

### What are the risks of running `fork-repo` inside a submodule?

It forks the submodule's own remote, not the parent repo's — which is easy to mistake for "forking the whole project." The tool prints a warning when it detects this but proceeds anyway rather than aborting, so read the warning rather than assuming the fork target matched your mental model.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-fork-a-repo-and-wire-up-remotes).*

### Does it depend on the monorepo's shared shell library?

No — and this is deliberate. Unlike most other utilities in `utilities/shell/`, neither `make-repo` nor `fork-repo` sources `share/k8-lib`. Both are single-file scripts depending only on `gh` and `git`, specifically so they keep working if copied out of this monorepo. The cost is some duplication of patterns (arg parsing, confirmation prompts) that k8-lib-based utilities get for free.

→ *See [PROJ-ARCH.md](PROJ-ARCH.md#overview).*

## Trust

### Does anything get pushed to GitHub before I confirm?

No — in interactive mode (the default), nothing is created or pushed until you type `y` at the confirmation prompt; `--dry-run` goes further and performs zero GitHub API calls at all, only local resolution and printing. The one sequencing detail to know: in `--edit` interactive mode, the tool has already fetched (read-only) the repo's *current* settings from GitHub before showing you the menu — that's a read, not a write, but it does mean `--edit` requires the repo to exist and be reachable before you see anything.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-preview-a-repo-creation-without-creating-anything).*

### Does it store or transmit my GitHub credentials?

No — authentication is entirely delegated to `gh auth login`; `make-repo`/`fork-repo` hold no tokens or credentials of their own and fail fast with `Not authenticated — run: gh auth login` if `gh` isn't already authenticated. There's nothing in this package's own state to leak.

→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-install-the-tools).*
